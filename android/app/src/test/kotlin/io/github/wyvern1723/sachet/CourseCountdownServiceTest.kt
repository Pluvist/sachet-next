package io.github.wyvern1723.sachet

import android.Manifest
import android.app.Application
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Looper
import android.os.PowerManager
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode
import java.time.Duration
import java.time.Instant
import java.util.TimeZone

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = Application::class, instrumentedPackages = ["io.github.wyvern1723.sachet"])
@LooperMode(LooperMode.Mode.PAUSED)
class CourseCountdownServiceTest {
    private val app get() = RuntimeEnvironment.getApplication() as Application
    private val manager get() = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val oldZone = TimeZone.getDefault()
    @Before fun prepare() {
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai"))
        android.os.SystemClock.setCurrentTimeMillis(Instant.parse("2026-10-16T00:10:00Z").toEpochMilli())
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
    }
    @After fun resetZone() { TimeZone.setDefault(oldZone) }
    private fun cache(start: Long, end: Long, enabled: Boolean = true) {
        val data = JSONObject().put("ready", true).put("liveActivityEnabled", enabled)
            .put("lessons", JSONArray().put(JSONObject().put("title", "数学")
                .put("place", "逸夫楼201").put("start", start).put("end", end)))
        app.getSharedPreferences("course_widget", Context.MODE_PRIVATE).edit().putString("data", data.toString()).commit()
    }
    private fun active() = manager.activeNotifications.first { it.id == CourseLiveActivity.ID }.notification
    private fun controller(end: Long) = Robolectric.buildService(CourseCountdownService::class.java,
        Intent(app, CourseCountdownService::class.java).putExtra("end", end).putExtra("notification", active()))
        .create().startCommand(0, 1)

    @Test fun numericTitleTicksAndExpandedDetailsRemainAvailable() {
        val now = android.os.SystemClock.uptimeMillis(); val end = now + 120_000
        cache(now - 60_000, end)
        CourseLiveActivity.refresh(app)
        assertEquals("02:00", active().extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertEquals("数学", active().extras.getCharSequence(Notification.EXTRA_TITLE_BIG).toString())
        assertTrue(active().extras.getCharSequence(Notification.EXTRA_BIG_TEXT).toString().contains("逸夫楼201"))
        val controller = controller(end)
        try {
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1))
            assertEquals("01:59", active().extras.getCharSequence(Notification.EXTRA_TITLE).toString())
            assertTrue(active().extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
            CourseLiveActivity.dismissToday(app, null)
        } finally { controller.destroy() }
        assertFalse(manager.activeNotifications.any { it.id == CourseLiveActivity.ID })
    }

    @Test fun screenOffPausesTitleRefreshAndScreenOnCatchesUp() {
        val now = android.os.SystemClock.uptimeMillis(); val end = now + 120_000
        cache(now - 60_000, end); CourseLiveActivity.refresh(app)
        val controller = controller(end)
        try {
            shadowOf(Looper.getMainLooper()).idle()
            val power = app.getSystemService(Context.POWER_SERVICE) as PowerManager
            shadowOf(power).setIsInteractive(false)
            app.sendBroadcast(Intent(Intent.ACTION_SCREEN_OFF))
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(5))
            assertEquals("02:00", active().extras.getCharSequence(Notification.EXTRA_TITLE).toString())
            shadowOf(power).setIsInteractive(true)
            app.sendBroadcast(Intent(Intent.ACTION_SCREEN_ON))
            shadowOf(Looper.getMainLooper()).idle()
            assertEquals("01:55", active().extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        } finally { controller.destroy() }
    }

    @Test fun classEndKeepsDismissibleCompletionAfterServiceDetaches() {
        val now = android.os.SystemClock.uptimeMillis(); val end = now + 2_000
        cache(now - 60_000, end); CourseLiveActivity.refresh(app)
        val controller = controller(end)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(3))
        controller.destroy()
        assertEquals("课程已完成", active().extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertEquals(0, active().flags and Notification.FLAG_ONGOING_EVENT)
    }

    @Test fun queuedStartCannotResurrectDisabledActivity() {
        val now = android.os.SystemClock.uptimeMillis(); val end = now + 120_000
        cache(now - 60_000, end); CourseLiveActivity.refresh(app)
        val intent = Intent(app, CourseCountdownService::class.java).putExtra("end", end).putExtra("notification", active())
        cache(now - 60_000, end, enabled = false); CourseLiveActivity.refresh(app)
        val controller = Robolectric.buildService(CourseCountdownService::class.java, intent).create().startCommand(0, 1)
        shadowOf(Looper.getMainLooper()).idle()
        controller.destroy()
        assertFalse(manager.activeNotifications.any { it.id == CourseLiveActivity.ID })
    }
}
