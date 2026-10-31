package com.pluvist.sachet.next

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray

/** One-way removal of the retired local-notifications plugin's own reminders.
 * Never cancel the widget/live-activity alarms or notifications.
 */
internal object LegacyReminderCleanup {
    @Synchronized fun run(context: Context) {
        // This persisted identifier must survive product-name changes.
        val migration = context.getSharedPreferences("sachet_next_migrations", Context.MODE_PRIVATE)
        if (migration.getBoolean("legacyRemindersRemoved", false)) return
        val cache = context.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
        val entries = try { JSONArray(cache.getString("scheduled_notifications", "[]")) }
            catch (_: Exception) { JSONArray() }
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val intent = Intent().setClassName(context.packageName,
            "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver")
        for (i in 0 until entries.length()) {
            val entry = entries.optJSONObject(i) ?: continue
            if (!entry.has("id")) continue
            val id = entry.optInt("id")
            val pending = PendingIntent.getBroadcast(context, id, intent,
                PendingIntent.FLAG_NO_CREATE or
                    if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0)
            if (pending != null) { alarm.cancel(pending); pending.cancel() }
            if (Build.VERSION.SDK_INT < 26 && id != CourseLiveActivity.ID) notifications.cancel(id)
        }
        if (Build.VERSION.SDK_INT >= 23) {
            for (notification in notifications.activeNotifications) {
                if (Build.VERSION.SDK_INT >= 26 && notification.notification.channelId in
                    setOf("course_reminder", "notification_test"))
                    notifications.cancel(notification.tag, notification.id)
            }
        }
        if (Build.VERSION.SDK_INT >= 26) {
            notifications.deleteNotificationChannel("course_reminder")
            notifications.deleteNotificationChannel("notification_test")
        }
        cache.edit().clear().commit()
        context.getSharedPreferences("notification_plugin_cache", Context.MODE_PRIVATE).edit().clear().commit()
        migration.edit().putBoolean("legacyRemindersRemoved", true).commit()
    }
}
