package com.kinetic.kinetic

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class KineticMediaManager(
    private val context: Context,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as? MediaSessionManager
    private var activeController: MediaController? = null
    private var isListening = false

    private val activeSessionsListener = MediaSessionManager.OnActiveSessionsChangedListener { controllers ->
        updateActiveSession(controllers)
    }

    private val controllerCallback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) {
            dispatchTrackInfo()
        }

        override fun onMetadataChanged(metadata: MediaMetadata?) {
            dispatchTrackInfo()
        }

        override fun onSessionDestroyed() {
            activeController = null
            dispatchTrackInfo()
            refreshSessions()
        }
    }

    fun setup() {
        channel.setMethodCallHandler(this)
        KineticNotificationListenerService.onListenerConnectedCallback = {
            refreshSessions()
        }
        KineticNotificationListenerService.onListenerDisconnectedCallback = {
            activeController?.unregisterCallback(controllerCallback)
            activeController = null
            dispatchTrackInfo()
        }
    }

    fun destroy() {
        stopListening()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isPermissionGranted" -> {
                result.success(KineticNotificationListenerService.isPermissionGranted(context))
            }
            "requestPermission" -> {
                openPermissionSettings()
                result.success(true)
            }
            "startListening" -> {
                startListening()
                result.success(true)
            }
            "stopListening" -> {
                stopListening()
                result.success(true)
            }
            "getTrackInfo" -> {
                result.success(extractTrackInfo(activeController))
            }
            "playPause" -> {
                val controller = activeController
                if (controller != null) {
                    val state = controller.playbackState?.state
                    if (state == PlaybackState.STATE_PLAYING) {
                        controller.transportControls?.pause()
                    } else {
                        controller.transportControls?.play()
                    }
                    mainHandler.postDelayed({ dispatchTrackInfo() }, 300)
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
            "next" -> {
                activeController?.transportControls?.skipToNext()
                mainHandler.postDelayed({ dispatchTrackInfo() }, 300)
                result.success(true)
            }
            "previous" -> {
                activeController?.transportControls?.skipToPrevious()
                mainHandler.postDelayed({ dispatchTrackInfo() }, 300)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startListening() {
        if (isListening) return
        isListening = true

        if (KineticNotificationListenerService.isPermissionGranted(context)) {
            try {
                val component = KineticNotificationListenerService.getComponentName(context)
                mediaSessionManager?.addOnActiveSessionsChangedListener(activeSessionsListener, component)
                refreshSessions()
            } catch (_: SecurityException) {
                // Permission not granted or revoked
            }
        }
    }

    private fun stopListening() {
        if (!isListening) return
        isListening = false
        try {
            mediaSessionManager?.removeOnActiveSessionsChangedListener(activeSessionsListener)
        } catch (_: Exception) {}
        activeController?.unregisterCallback(controllerCallback)
        activeController = null
    }

    fun refreshSessions() {
        if (!KineticNotificationListenerService.isPermissionGranted(context)) {
            if (activeController != null) {
                activeController?.unregisterCallback(controllerCallback)
                activeController = null
                dispatchTrackInfo()
            }
            return
        }

        try {
            val component = KineticNotificationListenerService.getComponentName(context)
            val controllers = mediaSessionManager?.getActiveSessions(component)
            updateActiveSession(controllers)
        } catch (_: SecurityException) {
            // Permission access rejected
        }
    }

    private fun updateActiveSession(controllers: List<MediaController>?) {
        if (controllers.isNullOrEmpty()) {
            if (activeController != null) {
                activeController?.unregisterCallback(controllerCallback)
                activeController = null
                dispatchTrackInfo()
            }
            return
        }

        var chosen: MediaController? = null
        for (controller in controllers) {
            val state = controller.playbackState?.state
            if (state == PlaybackState.STATE_PLAYING) {
                chosen = controller
                break
            } else if (chosen == null && state == PlaybackState.STATE_PAUSED) {
                chosen = controller
            }
        }

        if (chosen == null) {
            chosen = controllers.firstOrNull()
        }

        if (chosen != activeController) {
            activeController?.unregisterCallback(controllerCallback)
            activeController = chosen
            activeController?.registerCallback(controllerCallback)
        }

        dispatchTrackInfo()
    }

    private fun extractTrackInfo(controller: MediaController?): Map<String, Any?>? {
        if (controller == null) return null

        val metadata = controller.metadata ?: return null
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
            ?: metadata.getText(MediaMetadata.METADATA_KEY_TITLE)?.toString()
            ?: ""

        if (title.isBlank()) return null

        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: metadata.getText(MediaMetadata.METADATA_KEY_ARTIST)?.toString()
            ?: ""

        val album = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM)
            ?: metadata.getText(MediaMetadata.METADATA_KEY_ALBUM)?.toString()
            ?: ""

        val isPlaying = controller.playbackState?.state == PlaybackState.STATE_PLAYING

        var artUrl: String? = null
        val bitmap = metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)

        if (bitmap != null) {
            try {
                val artFile = File(context.cacheDir, "kinetic_current_media_art.png")
                FileOutputStream(artFile).use { out ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 90, out)
                }
                artUrl = "file://${artFile.absolutePath}"
            } catch (_: Exception) {}
        }

        if (artUrl == null) {
            artUrl = metadata.getString(MediaMetadata.METADATA_KEY_ART_URI)
                ?: metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ART_URI)
        }

        return mapOf(
            "title" to title,
            "artist" to artist,
            "album" to album,
            "isPlaying" to isPlaying,
            "artUrl" to artUrl
        )
    }

    private fun dispatchTrackInfo() {
        val trackInfo = extractTrackInfo(activeController)
        mainHandler.post {
            channel.invokeMethod("onTrackChanged", trackInfo)
        }
    }

    private fun openPermissionSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val componentName = KineticNotificationListenerService.getComponentName(context).flattenToString()
                val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).apply {
                    putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, componentName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                return
            }
        } catch (_: Exception) {}

        try {
            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (_: Exception) {}
    }
}
