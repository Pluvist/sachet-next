package com.pluvist.sachet.next

import android.app.Application
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ResolveInfo
import android.os.PowerManager
import android.provider.Settings
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = Application::class)
class OnboardingSettingsTest {
    private val app get() = RuntimeEnvironment.getApplication() as Application
    @Test fun upgradeCancelsOnlyLegacyRemindersAndIsIdempotent() {
        val alarm = app.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val oldIntent = Intent().setClassName(app.packageName,
            "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver")
        val old = PendingIntent.getBroadcast(app, 42, oldIntent, PendingIntent.FLAG_IMMUTABLE)
        val current = PendingIntent.getBroadcast(app, 772, Intent(app, CourseWidgetProvider::class.java), PendingIntent.FLAG_IMMUTABLE)
        alarm.set(AlarmManager.RTC, 100_000, old)
        alarm.set(AlarmManager.RTC, 100_000, current)
        app.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE).edit()
            .putString("scheduled_notifications", "[{\"id\":42}]").commit()
        val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(NotificationChannel("course_reminder", "Old", NotificationManager.IMPORTANCE_DEFAULT))
        manager.createNotificationChannel(NotificationChannel("notification_test", "Test", NotificationManager.IMPORTANCE_DEFAULT))
        manager.createNotificationChannel(NotificationChannel("course_live_activity", "Live", NotificationManager.IMPORTANCE_DEFAULT))
        manager.notify(42, Notification.Builder(app, "course_live_activity").setContentTitle("Live").setSmallIcon(R.mipmap.launcher_icon).build())
        LegacyReminderCleanup.run(app)
        assertEquals(listOf(current), shadowOf(alarm).scheduledAlarms.map { it.operation })
        assertNull(manager.getNotificationChannel("course_reminder"))
        assertNull(manager.getNotificationChannel("notification_test"))
        assertNotNull(manager.getNotificationChannel("course_live_activity"))
        assertEquals("Live", shadowOf(manager).getNotification(42).extras.getString(Notification.EXTRA_TITLE))
        assertTrue(app.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE).all.isEmpty())
        LegacyReminderCleanup.run(app)
        assertEquals(1, shadowOf(alarm).scheduledAlarms.size)
    }
    @Test fun malformedLegacyCacheDoesNotBlockStartup() {
        app.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE).edit()
            .putString("scheduled_notifications", "broken").commit()
        LegacyReminderCleanup.run(app)
        assertTrue(app.getSharedPreferences("sachet_next_migrations", Context.MODE_PRIVATE)
            .getBoolean("legacyRemindersRemoved", false))
    }
    @Test @Config(sdk = [22]) fun upgradeAlsoCancelsLegacyAlarmsBeforeImmutablePendingIntentsExisted() {
        val alarm = app.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent().setClassName(app.packageName,
            "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver")
        val pending = PendingIntent.getBroadcast(app, 7, intent, 0)
        alarm.set(AlarmManager.RTC, 100_000, pending)
        app.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE).edit()
            .putString("scheduled_notifications", "[{\"id\":7}]").commit()
        LegacyReminderCleanup.run(app)
        assertTrue(shadowOf(alarm).scheduledAlarms.isEmpty())
    }
    @Test fun setupReportsOnlyPublicBatteryStateAndNeverClaimsAutostartWasGranted() {
        val power = app.getSystemService(Context.POWER_SERVICE) as PowerManager
        shadowOf(power).setIgnoringBatteryOptimizations(app.packageName, true)
        val status = BackgroundSetupSettings.status(app)
        assertEquals(true, status["batteryUnrestricted"])
        assertFalse(status.containsKey("autostartGranted"))
        assertEquals(0, status["widgetCount"])
        val fallback = BackgroundSetupSettings.candidates(app, "autostart").last()
        assertEquals(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, fallback.action)
        assertEquals("package:${app.packageName}", fallback.data.toString())
    }
    @Test fun batteryEntryOnlyOpensAUserControlledSettingsScreen() {
        val activity = Robolectric.buildActivity(android.app.Activity::class.java).setup().get()
        val candidates = BackgroundSetupSettings.candidates(activity, "battery")
        val fallback = candidates.last()
        shadowOf(app.packageManager).addResolveInfoForIntent(fallback, ResolveInfo().apply {
            activityInfo = android.content.pm.ActivityInfo().apply {
                packageName = "com.android.settings"; name = "com.android.settings.AppDetails"; exported = true
            }
        })
        assertTrue(BackgroundSetupSettings.open(activity, "battery"))
        assertEquals(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, shadowOf(activity).nextStartedActivity.action)
        assertTrue(candidates.none { it.action == Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS })
    }
}
