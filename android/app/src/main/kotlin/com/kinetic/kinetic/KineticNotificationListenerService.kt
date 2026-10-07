package com.kinetic.kinetic

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import androidx.core.app.NotificationManagerCompat

class KineticNotificationListenerService : NotificationListenerService() {

    companion object {
        var instance: KineticNotificationListenerService? = null
        var onListenerConnectedCallback: (() -> Unit)? = null
        var onListenerDisconnectedCallback: (() -> Unit)? = null

        fun isPermissionGranted(context: Context): Boolean {
            try {
                val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
                if (enabledPackages.contains(context.packageName)) {
                    return true
                }
            } catch (_: Exception) {}

            try {
                val packageName = context.packageName
                val flat = Settings.Secure.getString(
                    context.contentResolver,
                    "enabled_notification_listeners"
                )
                if (flat != null && flat.contains(packageName)) {
                    return true
                }
            } catch (_: Exception) {}

            return false
        }

        fun getComponentName(context: Context): ComponentName {
            return ComponentName(context, KineticNotificationListenerService::class.java)
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        onListenerConnectedCallback?.invoke()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (instance == this) {
            instance = null
        }
        onListenerDisconnectedCallback?.invoke()
    }
}
