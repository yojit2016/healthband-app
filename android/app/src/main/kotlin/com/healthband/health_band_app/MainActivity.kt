package com.healthband.health_band_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.healthband.notifications/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // One-time fix: clear any corrupted scheduled_notifications SharedPreferences
        // that cause the Gson "Missing type parameter" crash in flutter_local_notifications.
        clearCorruptedNotificationCache()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openExactAlarmSettings" -> {
                        openExactAlarmSettings()
                        result.success(null)
                    }
                    "clearNotificationCache" -> {
                        clearCorruptedNotificationCache()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Clears the flutter_local_notifications scheduled notifications cache from
     * SharedPreferences. This fixes the "Missing type parameter" Gson crash that
     * happens when the cache contains a notification serialized with an incompatible
     * format (e.g. from a previous app version that used matchDateTimeComponents).
     */
    private fun clearCorruptedNotificationCache() {
        try {
            val prefs = getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
            android.util.Log.d("MainActivity", "Cleared scheduled_notifications SharedPreferences cache")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to clear notification cache: ${e.message}")
        }
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.fromParts("package", packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } else {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        }
    }
}
