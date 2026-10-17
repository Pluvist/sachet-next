package com.pluvist.sachet.next

import android.app.Application
import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.res.Configuration
import android.graphics.Rect
import android.os.SystemClock
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.text.SimpleDateFormat
import java.util.TimeZone

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = Application::class,
    instrumentedPackages = ["com.pluvist.sachet.next"])
class WideCourseWidgetTest {
    private val app get() = RuntimeEnvironment.getApplication() as Application
    private val originalZone = TimeZone.getDefault()
    private fun at(time: String) = SimpleDateFormat("yyyy-MM-dd HH:mm").parse("2026-10-19 $time")!!.time
    @Before fun prepare() { TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai")) }
    @After fun reset() { TimeZone.setDefault(originalZone) }
    private fun lesson(title: String, place: String, start: String, end: String) = JSONObject()
        .put("title", title).put("place", place).put("start", at(start)).put("end", at(end))
    private fun payload() = JSONObject().put("ready", true).put("themeMode", 2)
        .put("semester", "2026-09-07T00:00:00").put("lessons", JSONArray()
            .put(lesson("高等数学", "逸夫楼201", "08:10", "08:55"))
            .put(lesson("大学英语", "信息科技大楼305", "09:05", "09:50")))
    private fun render(data: JSONObject, time: String, width: Int = 320, height: Int = 160,
        fontScale: Float = 1f): View {
        val config = Configuration(app.resources.configuration).apply { this.fontScale = fontScale }
        val context = app.createConfigurationContext(config)
        val view = CourseWidgetWideRenderer.render(context, data, at(time), width, height)
            .apply(context, FrameLayout(context))
        val density = context.resources.displayMetrics.density
        view.measure(View.MeasureSpec.makeMeasureSpec((width * density).toInt(), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec((height * density).toInt(), View.MeasureSpec.EXACTLY))
        view.layout(0, 0, view.measuredWidth, view.measuredHeight)
        return view
    }
    private fun View.text(id: Int) = findViewById<TextView>(id).text.toString()
    @Test fun inClassShowsCurrentAndNextInSeparatePanels() {
        val view = render(payload(), "08:20")
        assertEquals("正在上课", view.text(R.id.widget_current_status))
        assertEquals("高等数学", view.text(R.id.widget_title))
        assertEquals("距下课 35 分钟", view.text(R.id.widget_countdown))
        assertEquals("大学英语", view.text(R.id.widget_next_title))
        assertEquals("09:05–09:50", view.text(R.id.widget_next_time))
        assertEquals("信息科技大楼305", view.text(R.id.widget_next_place))
        assertTrue(view.findViewById<View>(R.id.widget_current_panel).right < view.findViewById<View>(R.id.widget_divider).left)
        assertTrue(view.findViewById<View>(R.id.widget_divider).right < view.findViewById<View>(R.id.widget_next_panel).left)
    }
    @Test fun breakCompletionEmptyAndUnimportedStatesReplaceStaleDetails() {
        val waiting = render(payload(), "08:55")
        assertEquals("当前未在上课", waiting.text(R.id.widget_title))
        assertEquals("距上课 10 分钟", waiting.text(R.id.widget_footer))
        assertEquals("09:05–09:50", waiting.text(R.id.widget_next_time))
        val finished = render(payload(), "09:50")
        assertEquals("今日课程已完成", finished.text(R.id.widget_title))
        assertEquals(View.GONE, finished.findViewById<View>(R.id.widget_next_time).visibility)
        val empty = render(payload().put("lessons", JSONArray()), "08:00")
        assertEquals("今日无课喵~", empty.text(R.id.widget_title))
        val unimported = render(payload().put("ready", false), "08:20")
        assertEquals("请先导入课表", unimported.text(R.id.widget_title))
        assertEquals(View.GONE, unimported.findViewById<View>(R.id.widget_countdown).visibility)
        assertEquals(View.GONE, unimported.findViewById<View>(R.id.widget_next_time).visibility)
    }
    @Test fun nextLessonSkipsAnOverlappingLessonAndUsesResolvedStaggeredTimes() {
        val data = payload()
        data.getJSONArray("lessons").put(lesson("重叠课程", "第一教学楼", "08:30", "08:45"))
        val view = render(data, "08:20")
        assertEquals("大学英语", view.text(R.id.widget_next_title))
        assertEquals("09:05–09:50", view.text(R.id.widget_next_time))
    }
    @Test fun shortWideAndLargeFontAllocationsStayInsideTheWidget() {
        for (width in listOf(220, 320, 480)) for (height in listOf(100, 110, 150, 220))
            for (font in listOf(1f, 2f)) {
                val view = render(payload(), "08:20", width, height, font) as android.view.ViewGroup
                for (id in listOf(R.id.widget_current_status, R.id.widget_title, R.id.widget_place,
                        R.id.widget_countdown, R.id.widget_next_label, R.id.widget_next_title,
                        R.id.widget_next_time, R.id.widget_next_place)) {
                    val text = view.findViewById<TextView>(id)
                    if (text.visibility != View.VISIBLE) continue
                    val rect = Rect(); text.getDrawingRect(rect); view.offsetDescendantRectToMyCoords(text, rect)
                    assertTrue("text escapes top: $width/$height/$font/$id", rect.top >= 0)
                    assertTrue("text escapes bottom: $width/$height/$font/$id", rect.bottom <= view.height)
                }
            }
    }
    @Test fun layoutIsSelectableAndSharedRefreshDoesNotStopTheOtherWidget() {
        val component = ComponentName(app, CourseWidgetWideProvider::class.java)
        val info = app.packageManager.getReceiverInfo(component, android.content.pm.PackageManager.GET_META_DATA)
        assertFalse(info.exported)
        val xml = app.resources.getXml(info.metaData.getInt("android.appwidget.provider"))
        while (xml.next() != org.xmlpull.v1.XmlPullParser.START_TAG) { /* skip document and comments */ }
        val ns = "http://schemas.android.com/apk/res/android"
        assertEquals(4, xml.getAttributeIntValue(ns, "targetCellWidth", 0))
        assertEquals(2, xml.getAttributeIntValue(ns, "targetCellHeight", 0))
        SystemClock.setCurrentTimeMillis(at("08:20"))
        app.getSharedPreferences("course_widget", Context.MODE_PRIVATE).edit()
            .putString("data", payload().toString()).commit()
        val manager = AppWidgetManager.getInstance(app); val shadow = shadowOf(manager)
        val id = shadow.createWidget(CourseWidgetWideProvider::class.java, R.layout.course_widget_wide)
        CourseWidgetProvider.refresh(app)
        assertEquals("高等数学", shadow.getViewFor(id).text(R.id.widget_title))
        CourseWidgetProvider().onDisabled(app)
        assertTrue(shadowOf(app.getSystemService(Context.ALARM_SERVICE) as AlarmManager).scheduledAlarms.isNotEmpty())
        assertEquals("大学英语", shadow.getViewFor(id).text(R.id.widget_next_title))
    }
    @Test fun lightAndDarkUseReadableForegroundColors() {
        val dark = render(payload().put("themeMode", 2), "08:20")
        val light = render(payload().put("themeMode", 1), "08:20")
        assertEquals(0xffeeeeee.toInt(), dark.findViewById<TextView>(R.id.widget_title).currentTextColor)
        assertEquals(0xff171717.toInt(), light.findViewById<TextView>(R.id.widget_title).currentTextColor)
    }
    @Test @GraphicsMode(GraphicsMode.Mode.NATIVE)
    fun renderOptionalVisualPreviews() {
        val folder = System.getenv("SACHET_WIDGET_PREVIEW_DIR") ?: return
        java.io.File(folder).mkdirs()
        for (mode in listOf(1, 2)) for (time in listOf("08:20", "08:55", "09:50")) {
            val view = render(payload().put("themeMode", mode), time, 350, 180)
            val bitmap = android.graphics.Bitmap.createBitmap(view.width, view.height,
                android.graphics.Bitmap.Config.ARGB_8888)
            view.draw(android.graphics.Canvas(bitmap))
            java.io.File(folder, "wide-$mode-${time.replace(":", "")}.png").outputStream().use {
                bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
            }
            bitmap.recycle()
        }
    }
}
