package com.pluvist.sachet.next

import android.app.Application
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.drawable.BitmapDrawable
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
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
import java.io.File
import java.text.SimpleDateFormat
import java.util.TimeZone

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = Application::class, instrumentedPackages = ["com.pluvist.sachet.next"])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CourseWidgetGlowTest {
    private val app get() = RuntimeEnvironment.getApplication() as Application
    private val originalZone = TimeZone.getDefault()
    @Before fun prepare() { TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai")) }
    @After fun reset() { TimeZone.setDefault(originalZone) }
    private fun time(value: String) = SimpleDateFormat("yyyy-MM-dd HH:mm").parse("2026-10-19 $value")!!.time
    private fun payload(mode: Int) = JSONObject().put("ready", true).put("themeMode", mode)
        .put("semester", "2026-09-07").put("lessons", JSONArray()
            .put(JSONObject().put("title", "高等数学").put("place", "逸夫楼201")
                .put("start", time("08:10")).put("end", time("08:55")).put("group", "math"))
            .put(JSONObject().put("title", "大学英语").put("place", "信息科技大楼305")
                .put("start", time("09:05")).put("end", time("09:50")).put("group", "english")))
    private fun render(wide: Boolean, width: Int, height: Int, mode: Int = 2): ViewGroup {
        app.getSharedPreferences("course_widget", Context.MODE_PRIVATE).edit()
            .putString("data", payload(mode).toString()).commit()
        val manager = AppWidgetManager.getInstance(app)
        val shadow = shadowOf(manager)
        val id = if (wide) shadow.createWidget(CourseWidgetWideProvider::class.java, R.layout.course_widget_wide)
            else shadow.createWidget(CourseWidgetProvider::class.java, R.layout.course_widget_compact)
        manager.updateAppWidgetOptions(id, Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
        })
        CourseWidgetProvider.refresh(app, time("08:20"))
        val view = shadow.getViewFor(id) as ViewGroup
        assertEquals("高等数学", view.findViewById<TextView>(R.id.widget_title).text.toString())
        val density = app.resources.displayMetrics.density
        view.measure(View.MeasureSpec.makeMeasureSpec((width * density).toInt(), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec((height * density).toInt(), View.MeasureSpec.EXACTLY))
        view.layout(0, 0, view.measuredWidth, view.measuredHeight)
        return view
    }
    @Test fun bothLayoutsHaveShorterMetadataAndVisiblyInsetRoundedSurfaces() {
        for (wide in listOf(false, true)) {
            val component = ComponentName(app, if (wide) CourseWidgetWideProvider::class.java else CourseWidgetProvider::class.java)
            val info = app.packageManager.getReceiverInfo(component, android.content.pm.PackageManager.GET_META_DATA)
            val xml = app.resources.getXml(info.metaData.getInt("android.appwidget.provider"))
            while (xml.next() != org.xmlpull.v1.XmlPullParser.START_TAG) { }
            val ns = "http://schemas.android.com/apk/res/android"
            assertEquals("100.0dip", xml.getAttributeValue(ns, "minHeight"))
            assertEquals(if (wide) 4 else 2, xml.getAttributeIntValue(ns, "targetCellWidth", 0))
            assertEquals(2, xml.getAttributeIntValue(ns, "targetCellHeight", 0))
            val view = render(wide, if (wide) 350 else 160, 170)
            val surface = view.findViewById<View>(R.id.widget_surface)
            val inset = (6 * app.resources.displayMetrics.density + .5f).toInt()
            assertEquals(inset, surface.top)
            assertEquals(view.height - inset, surface.bottom)
            assertTrue(surface.clipToOutline)
        }
    }
    @Test fun shortAllocationsAndLargeFontsKeepAllVisibleCourseTextInsideSurface() {
        for (font in listOf(1f, 2f)) {
            RuntimeEnvironment.setFontScale(font)
            for (wide in listOf(false, true)) for (height in listOf(100, 130, 160, 200)) {
                val view = render(wide, if (wide) 320 else 160, height)
                val surface = view.findViewById<ViewGroup>(R.id.widget_surface)
                fun inspect(parent: ViewGroup) {
                    for (i in 0 until parent.childCount) {
                        val child = parent.getChildAt(i)
                        if (child.visibility != View.VISIBLE) continue
                        if (child is TextView && child.text.isNotEmpty()) {
                            val rect = Rect(); child.getDrawingRect(rect)
                            surface.offsetDescendantRectToMyCoords(child, rect)
                            assertTrue("top overflow: wide=$wide height=$height font=$font id=${child.id}", rect.top >= 0)
                            assertTrue("bottom overflow: wide=$wide height=$height font=$font id=${child.id}", rect.bottom <= surface.height)
                        }
                        if (child is ViewGroup) inspect(child)
                    }
                }
                inspect(surface)
            }
        }
    }
    @Test fun glowIsStaticColoredAndReadableInBothThemes() {
        for (wide in listOf(false, true)) for (mode in listOf(1, 2)) {
            val view = render(wide, if (wide) 350 else 160, 170, mode)
            val bitmap = (view.findViewById<ImageView>(R.id.widget_glow).drawable as BitmapDrawable).bitmap
            assertNotEquals(bitmap.getPixel(20, 20), bitmap.getPixel(250, bitmap.height - 20))
            assertEquals(255, android.graphics.Color.alpha(bitmap.getPixel(bitmap.width / 2, bitmap.height / 2)))
            assertEquals(0, android.graphics.Color.alpha(bitmap.getPixel(0, 0)))
            val again = render(wide, if (wide) 350 else 160, 170, mode)
            val repeated = (again.findViewById<ImageView>(R.id.widget_glow).drawable as BitmapDrawable).bitmap
            assertTrue(bitmap.sameAs(repeated))
            val folder = System.getenv("SACHET_WIDGET_PREVIEW_DIR") ?: continue
            File(folder).mkdirs()
            val preview = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
            view.draw(Canvas(preview))
            File(folder, "glow-${if (wide) "wide" else "compact"}-$mode.png").outputStream().use {
                preview.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
            preview.recycle()
        }
    }
}
