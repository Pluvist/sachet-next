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
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

/** System permission queries use Binder; keep them out of composition/animation frames.
 * Resume immediately refreshes the snapshot after returning from a system settings page. */
@Composable internal fun rememberBackgroundSetupStatus(enabled:Boolean=true):State<Map<String,Any>> {
    val context=LocalContext.current.applicationContext
    val lifecycle=LocalLifecycleOwner.current.lifecycle
    return produceState<Map<String,Any>>(emptyMap(),context,lifecycle,enabled) {
        if(enabled) lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
            while(true) {
                value=withContext(Dispatchers.IO){BackgroundSetupSettings.status(context)}
                delay(1000)
            }
        }
    }
}

/** Opens user-controlled system screens; it never grants or fabricates access. */
internal object BackgroundSetupSettings {
    private fun details(context: Context) = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
        Uri.parse("package:${context.packageName}"))
    internal fun candidates(context: Context, kind: String): List<Intent> = when (kind) {
        "autostart" -> listOf(Intent().setComponent(ComponentName("com.miui.securitycenter",
            "com.miui.permcenter.autostart.AutoStartManagementActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.oplus.safecenter",
                "com.oplus.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter",
                "com.coloros.safecenter.startupapp.StartupAppListActivity")), details(context))
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
            "autostartAvailable" to candidates(context, "autostart").dropLast(1)
                .any { it.resolveActivity(context.packageManager) != null },
            "live" to CourseLiveActivity.status(context),
            // There is no public API to read a vendor's auto-start permission.
            "widgetCount" to (manager.getAppWidgetIds(ComponentName(context, CourseWidgetProvider::class.java)).size +
                manager.getAppWidgetIds(ComponentName(context, CourseWidgetWideProvider::class.java)).size))
    }
}
