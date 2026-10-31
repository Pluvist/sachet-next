package com.pluvist.sachet.next

import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import org.junit.Assert.*
import org.junit.Test

class StatusCompanionFlightTest {
    private fun status()=MorphRequest(MorphSnapshot("course-status",Rect(20f,600f,300f,648f),24f,Color.Transparent,emptyList()),CourseMorphContent.Status)
    @Test fun companionsLeaveOnAcceptedRequestAndReturnImmediatelyOnCancellation() {
        val controller=CourseMorphController()
        controller.request(status())
        assertTrue(controller.statusChromeRequested)
        assertNull(controller.flight) // Both animations observe the intent on their next frame.
        controller.dismiss()
        assertFalse(controller.statusChromeRequested)
        assertFalse(controller.isBusy)
    }
    @Test fun reopeningDuringReturnReversesCompanionsWithoutReplacingThePanel() {
        val controller=CourseMorphController();val request=status()
        controller.request(request)
        val flight=CourseMorphFlight(request);controller.flight=flight
        controller.dismiss()
        assertFalse(controller.statusChromeRequested)
        assertTrue(flight.returning)
        controller.request(request)
        assertTrue(controller.statusChromeRequested)
        assertSame(flight,controller.flight)
    }
    @Test fun individualCourseDetailsDoNotSendNavigationAway() {
        val controller=CourseMorphController()
        val lesson=CourseMorphContent.Lesson(Course("test","测试","一教101","教师",1,1,2,setOf(1)))
        controller.request(status().copy(content=lesson))
        assertFalse(controller.statusChromeRequested)
    }
}
