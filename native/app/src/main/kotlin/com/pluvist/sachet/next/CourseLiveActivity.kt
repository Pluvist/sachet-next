package com.pluvist.sachet.next

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale

object CourseLiveActivity {
    const val REFRESH = "com.pluvist.sachet.next.LIVE_REFRESH"
    const val DISMISS = "com.pluvist.sachet.next.LIVE_DISMISS"
    private const val CHANNEL = "course_live_activity"
    private const val TAG = "course_live_activity"
    internal const val ID = -1958
    private fun prefs(context: Context) = context.getSharedPreferences("course_widget", Context.MODE_PRIVATE)
    private fun manager(context: Context) = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private fun alarm(context: Context) = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private fun alarmIntent(context: Context) = PendingIntent.getBroadcast(context, 9901,
        Intent(context, CourseLiveActivityReceiver::class.java).setAction(REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun dayKey(now: Long) = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(now)
    private fun time(time: Long) = SimpleDateFormat("HH:mm", Locale.ROOT).format(time)

    fun data(context: Context): JSONObject = try {
        JSONObject(prefs(context).getString("data", "{}") ?: "{}")
    } catch (_: Exception) { JSONObject() }
    private fun lessons(data: JSONObject): List<LiveLesson> {
        val array = data.optJSONArray("lessons") ?: return emptyList()
        return (0 until array.length()).mapNotNull { i ->
            val value = array.optJSONObject(i) ?: return@mapNotNull null
            val start = value.optLong("start"); val end = value.optLong("end")
            val title = value.optString("title").trim()
            if (title.isEmpty() || end <= start || start <= 0) null else LiveLesson(title,
                value.optString("place").ifBlank { "地点待确认" }, start, end)
        }.sortedBy { it.start }
    }
    fun notificationsAllowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
        if (Build.VERSION.SDK_INT >= 24 && !manager(context).areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= 26 && manager(context).getNotificationChannel(CHANNEL)?.importance == NotificationManager.IMPORTANCE_NONE) return false
        return true
    }
    fun hasToday(context: Context): Boolean {
        val data = data(context)
        return data.optBoolean("liveActivityEnabled") && data.optBoolean("ready") &&
            CourseTimeline.resolve(System.currentTimeMillis(), lessons(data)).phase != LiveCoursePhase.NONE
    }
    fun supportsPromotion(): Boolean = Build.VERSION.SDK_INT >= 36 &&
        NotificationManager::class.java.methods.any { it.name == "canPostPromotedNotifications" }
    fun status(context: Context): Map<String, Any> = mapOf(
        "supported" to supportsPromotion(), "notifications" to notificationsAllowed(context),
        "promoted" to (if (supportsPromotion()) try {
            NotificationManager::class.java.getMethod("canPostPromotedNotifications").invoke(manager(context)) as Boolean
        } catch (_: Exception) { false } else false),
        "exactAlarms" to (Build.VERSION.SDK_INT < 31 || alarm(context).canScheduleExactAlarms()))

    @Synchronized fun dismissToday(context: Context, day: String?) {
        prefs(context).edit().putString("liveDismissedDay", day ?: dayKey(System.currentTimeMillis())).commit()
        refresh(context)
    }

    @Synchronized fun refresh(context: Context) {
        val now = System.currentTimeMillis()
        val data = data(context)
        val manager = manager(context)
        // Migrate the earlier tagged notification to the single service notification.
        manager.cancel(TAG, ID)
        if (!data.optBoolean("liveActivityEnabled") || !data.optBoolean("ready") || !notificationsAllowed(context)) {
            stopCountdown(context); manager.cancel(ID); alarm(context).cancel(alarmIntent(context)); return
        }
        val lessons = lessons(data)
        val state = CourseTimeline.resolve(now, lessons)
        val dismissed = prefs(context).getString("liveDismissedDay", "") == dayKey(now)
        if (dismissed || state.phase == LiveCoursePhase.NONE) { stopCountdown(context); manager.cancel(ID) }
        else {
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel(CHANNEL, "课程实时活动", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "同步主页课程状态、下课倒计时和下一节课地点"; setSound(null, null)
                    enableVibration(false); setShowBadge(false)
                })
            }
            val open = PendingIntent.getActivity(context, 9903,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val dismiss = PendingIntent.getBroadcast(context, 9902,
                Intent(context, CourseLiveActivityReceiver::class.java).setAction(DISMISS).putExtra("day", dayKey(now)),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val completed = state.phase == LiveCoursePhase.COMPLETED
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
            builder.setSmallIcon(R.drawable.ic_course_live).setColor(0xff3482ff.toInt())
                .setContentIntent(open).setDeleteIntent(dismiss).setOnlyAlertOnce(true)
                .setCategory(Notification.CATEGORY_EVENT).setVisibility(Notification.VISIBILITY_PRIVATE)
                .setOngoing(!completed).setAutoCancel(completed).setShowWhen(false)
            val title: String; val compact: String; val body: String
            when (state.phase) {
                LiveCoursePhase.IN_CLASS -> {
                    val current = state.current!!
                    title = CourseTimeline.countdown(current.end - now)
                    compact = ""
                    body = "正在上课：${current.title}\n地点：${current.place}\n${time(current.start)}–${time(current.end)}\n" +
                        (state.next?.let { "下一节：${it.title} · ${time(it.start)} · ${it.place}" } ?: "今天没有下一节课啦")
                    if (Build.VERSION.SDK_INT >= 24) builder.setWhen(current.end).setShowWhen(true)
                        .setUsesChronometer(true).setChronometerCountDown(true)
                }
                LiveCoursePhase.WAITING -> {
                    val next = state.next!!
                    val duration = (next.end - next.start + 59_999L) / 60_000L
                    val period = "${time(next.start)}–${time(next.end)}"
                    title = "${time(next.start)} · ${next.place}"
                    compact = "${next.title} · $period · ${duration}分钟"
                    body = "下一堂课：${next.title}\n时间：$period\n持续时间：${duration}分钟"
                    setShortText(builder, time(next.start) + CourseTimeline.compactPlace(next.place))
                }
                else -> {
                    title = "课程已完成"; compact = "今天的课程都已结束"
                    body = "课程已完成\n今天的课程都已结束，休息一下吧。"
                    if (Build.VERSION.SDK_INT >= 26) builder.setTimeoutAfter(state.tomorrow - now)
                }
            }
            // A numeric title also satisfies promoted-notification eligibility.
            // Full course details are confined to the expanded view.
            builder.setContentTitle(title).setContentText(compact).setStyle(Notification.BigTextStyle()
                .setBigContentTitle(if (state.phase == LiveCoursePhase.IN_CLASS) state.current!!.title else title)
                .bigText(body))
            if (!completed) {
                if (Build.VERSION.SDK_INT >= 23) builder.addAction(Notification.Action.Builder(
                    null as android.graphics.drawable.Icon?, "今天不再显示", dismiss).build())
                else builder.addAction(0, "今天不再显示", dismiss)
            }
            // These public APIs are newer than compileSdk 35. Use public reflection
            // and documented extras, retaining Android 5+ runtime compatibility.
            if (Build.VERSION.SDK_INT >= 36) {
                val promote = CourseTimeline.promote(state, now)
                builder.addExtras(Bundle().apply { putBoolean("android.requestPromotedOngoing", promote) })
                try { Notification.Builder::class.java.getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
                    .invoke(builder, promote) } catch (_: Exception) { }
            }
            val notification = builder.build()
            try { manager.notify(ID, notification) } catch (_: SecurityException) { }
            if (state.current != null) startCountdown(context, notification, state.current.end)
            else stopCountdown(context)
        }
        val trigger = CourseTimeline.nextWake(now, lessons, state, dismissed)
        alarm(context).cancel(alarmIntent(context))
        if (trigger != null && trigger > now) {
            try {
                if (Build.VERSION.SDK_INT >= 31 && !alarm(context).canScheduleExactAlarms())
                    alarm(context).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, alarmIntent(context))
                else if (Build.VERSION.SDK_INT >= 23)
                    alarm(context).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, alarmIntent(context))
                else alarm(context).setExact(AlarmManager.RTC_WAKEUP, trigger, alarmIntent(context))
            } catch (_: SecurityException) { alarm(context).set(AlarmManager.RTC_WAKEUP, trigger, alarmIntent(context)) }
        }
    }
    private fun startCountdown(context: Context, notification: Notification, end: Long) {
        val intent = Intent(context, CourseCountdownService::class.java)
            .putExtra("notification", notification).putExtra("end", end)
        try {
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
        } catch (error: RuntimeException) {
            // Systems may restrict background starts. The native chronometer remains
            // the live chip's fallback; do not turn this into repeated alarm wakes.
            android.util.Log.w("CourseActivity", "Countdown service start restricted", error)
        }
    }
    private fun stopCountdown(context: Context) {
        context.stopService(Intent(context, CourseCountdownService::class.java))
    }
    internal fun activeEnd(context: Context): Long? {
        val now = System.currentTimeMillis()
        val data = data(context)
        if (!data.optBoolean("liveActivityEnabled") || !data.optBoolean("ready") || !notificationsAllowed(context) ||
            prefs(context).getString("liveDismissedDay", "") == dayKey(now)) return null
        return CourseTimeline.resolve(now, lessons(data)).current?.end
    }
    /** A foreground notification can only be cancelled after the service detaches. */
    @Synchronized internal fun cleanupCountdown(context: Context) {
        val now = System.currentTimeMillis()
        val data = data(context)
        if (!data.optBoolean("liveActivityEnabled") || !data.optBoolean("ready") || !notificationsAllowed(context) ||
            prefs(context).getString("liveDismissedDay", "") == dayKey(now) ||
            CourseTimeline.resolve(now, lessons(data)).phase == LiveCoursePhase.NONE) manager(context).cancel(ID)
    }
    private fun setShortText(builder: Notification.Builder, text: String) {
        if (Build.VERSION.SDK_INT < 36) return
        try { Notification.Builder::class.java.getMethod("setShortCriticalText", String::class.java).invoke(builder, text) }
        catch (_: Exception) { }
    }
}
