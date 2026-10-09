package com.kinetic.kinetic

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.kinetic.kinetic/media_service"
    private var mediaManager: KineticMediaManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        mediaManager = KineticMediaManager(this, channel)
        mediaManager?.setup()
    }

    override fun onResume() {
        super.onResume()
        // Refresh active media sessions whenever the app returns to foreground
        mediaManager?.refreshSessions()
    }

    override fun onDestroy() {
        mediaManager?.destroy()
        mediaManager = null
        super.onDestroy()
    }
}
