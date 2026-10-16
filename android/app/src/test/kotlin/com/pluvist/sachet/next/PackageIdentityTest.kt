package com.pluvist.sachet.next

import android.app.Application
import android.content.ComponentName
import android.content.pm.PackageManager
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = Application::class,
    instrumentedPackages = ["com.pluvist.sachet.next"])
class PackageIdentityTest {
    private val app get() = RuntimeEnvironment.getApplication() as Application
    @Test fun manifestResolvesRenamedActivityServiceAndWidget() {
        assertTrue(app.packageName in setOf("com.pluvist.sachet.next", "com.pluvist.sachet.next.localtest"))
        val manager = app.packageManager
        val main = manager.getActivityInfo(ComponentName(app, MainActivity::class.java), 0)
        assertEquals("com.pluvist.sachet.next.MainActivity", main.name)
        assertTrue(main.exported)
        val service = manager.getServiceInfo(ComponentName(app, CourseCountdownService::class.java), 0)
        assertEquals("com.pluvist.sachet.next.CourseCountdownService", service.name)
        assertFalse(service.exported)
        val widget = manager.getReceiverInfo(ComponentName(app, CourseWidgetProvider::class.java), PackageManager.GET_META_DATA)
        assertFalse(widget.exported)
        assertTrue(widget.metaData.getInt("android.appwidget.provider") != 0)
        assertFalse(manager.getReceiverInfo(ComponentName(app, CourseLiveActivityReceiver::class.java), 0).exported)
    }
    @Test fun activityAndWidgetActionsBelongToTheNewNamespace() {
        assertEquals("com.pluvist.sachet.next.LIVE_REFRESH", CourseLiveActivity.REFRESH)
        assertEquals("com.pluvist.sachet.next.LIVE_DISMISS", CourseLiveActivity.DISMISS)
        assertEquals("com.pluvist.sachet.next.CourseWidgetProvider", CourseWidgetProvider::class.java.name)
        assertEquals("com.pluvist.sachet.next.CourseLiveActivityReceiver", CourseLiveActivityReceiver::class.java.name)
    }
}
