package com.pluvist.sachet.next

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/** Opens user-controlled system screens; it never grants or fabricates access. */
internal object BackgroundSetupSettings {
    private fun details(context: Context) = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
        Uri.parse("package:${context.packageName}"))
    internal fun candidates(context: Context, kind: String): List<Intent> = when (kind) {
        "autostart" -> listOf(Intent().setComponent(ComponentName("com.miui.securitycenter",
            "com.miui.permcenter.autostart.AutoStartManagementActivity")), details(context))
        "battery" -> listOf(Intent("android.settings.APP_BATTERY_SETTINGS",
            Uri.parse("package:${context.packageName}")),
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS), details(context))
        else -> listOf(details(context))
    }
    fun open(activity: Activity, kind: String): Boolean {
        for (intent in candidates(activity, kind)) {
            try {
                if (intent.resolveActivity(activity.packageManager) != null) {
                    activity.startActivity(intent)
                    return true
                }
            } catch (_: android.content.ActivityNotFoundException) { }
              catch (_: SecurityException) { }
        }
        return false
    }
    fun status(context: Context): Map<String, Any> {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val manager = AppWidgetManager.getInstance(context)
        return mapOf(
            "batteryUnrestricted" to (Build.VERSION.SDK_INT < 23 || power.isIgnoringBatteryOptimizations(context.packageName)),
            "autostartAvailable" to (candidates(context, "autostart").first().resolveActivity(context.packageManager) != null),
            // There is no public API to read a vendor's auto-start permission.
            "widgetCount" to (manager.getAppWidgetIds(ComponentName(context, CourseWidgetProvider::class.java)).size +
                manager.getAppWidgetIds(ComponentName(context, CourseWidgetWideProvider::class.java)).size))
    }
}
