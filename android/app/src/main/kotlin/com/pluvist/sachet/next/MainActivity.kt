package com.pluvist.sachet.next

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
    companion object {
        private val widgetExecutor = Executors.newSingleThreadExecutor()
    }
    private var resumed = false
    private fun requestLivePermission(force: Boolean = false) {
        if (!resumed || isFinishing) return
        if (android.os.Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            if (force) openLiveSettings("notifications")
            return
        }
        val prefs = getSharedPreferences("course_widget", MODE_PRIVATE)
        if (!force && (prefs.getBoolean("livePermissionAsked", false) || !CourseLiveActivity.hasToday(this))) return
        if (force && prefs.getBoolean("livePermissionAsked", false) &&
            !shouldShowRequestPermissionRationale(android.Manifest.permission.POST_NOTIFICATIONS)) {
            openLiveSettings("notifications"); return
        }
        prefs.edit().putBoolean("livePermissionAsked", true).apply()
        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 9904)
    }
    private fun openLiveSettings(kind: String) {
        val fallback = if (android.os.Build.VERSION.SDK_INT >= 26)
            android.content.Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)
            else android.content.Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                android.net.Uri.parse("package:$packageName"))
        val intent = when {
            kind == "exact" && android.os.Build.VERSION.SDK_INT >= 31 ->
                android.content.Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                    android.net.Uri.parse("package:$packageName"))
            kind == "promoted" -> try {
                val action = android.provider.Settings::class.java.getField("ACTION_MANAGE_APP_PROMOTED_NOTIFICATIONS").get(null) as String
                android.content.Intent(action).putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)
            } catch (_: Exception) { fallback }
            else -> fallback
        }
        try { startActivity(if (intent.resolveActivity(packageManager) != null) intent else fallback) }
        catch (_: android.content.ActivityNotFoundException) { }
    }
    override fun onResume() {
        super.onResume(); resumed = true
        widgetExecutor.execute { CourseLiveActivity.refresh(applicationContext) }
        requestLivePermission()
    }
    override fun onPause() { resumed = false; super.onPause() }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 9904) widgetExecutor.execute { CourseLiveActivity.refresh(applicationContext) }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetExecutor.execute { LegacyReminderCleanup.run(applicationContext) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sachet_next/course_widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "backgroundStatus" -> result.success(BackgroundSetupSettings.status(this))
                    "backgroundSettings" -> result.success(BackgroundSetupSettings.open(this, call.arguments as? String ?: "battery"))
                    "sync" -> {
                        val context = applicationContext
                        val data = call.arguments as String
                        widgetExecutor.execute {
                            try {
                                val saved = context.getSharedPreferences("course_widget", MODE_PRIVATE).edit()
                                    .putString("data", data).commit()
                                if (!saved) throw IllegalStateException("Cannot persist course widget")
                                CourseWidgetProvider.refresh(context)
                                CourseLiveActivity.refresh(context)
                                runOnUiThread { requestLivePermission() }
                                runOnUiThread { result.success(null) }
                            } catch (_: Exception) {
                                runOnUiThread { result.error("widget_sync", "Cannot update widget", null) }
                            }
                        }
                    }
                    "liveStatus" -> result.success(CourseLiveActivity.status(this))
                    "livePermission" -> { requestLivePermission(call.arguments as? Boolean ?: true); result.success(null) }
                    "liveSettings" -> { openLiveSettings(call.arguments as? String ?: "notifications"); result.success(null) }
                    "pin" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        result.success(android.os.Build.VERSION.SDK_INT >= 26 &&
                            manager.isRequestPinAppWidgetSupported &&
                            manager.requestPinAppWidget(ComponentName(this,
                                if (call.arguments == "wide") CourseWidgetWideProvider::class.java
                                else CourseWidgetProvider::class.java), null, null))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
