package com.pluvist.sachet.next

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import org.junit.Assert.*
import org.junit.Test

class CourseMorphTest {
    @Test fun animatedPanelKeepsTheRecognizedRectangularShapeAndStandardRadius() {
        val progress=androidx.compose.runtime.mutableStateOf(0f)
        val shape=courseMorphShape(progress,6f)
        assertTrue(shape is io.github.neoruaa.glasmio.core.G2RoundedRectangle)
        val rectangle=shape as androidx.compose.foundation.shape.CornerBasedShape
        val size=androidx.compose.ui.geometry.Size(320f,440f)
        assertEquals(6f,rectangle.topStart.toPx(size,androidx.compose.ui.unit.Density(1f)),0f)
        progress.value=1f
        assertEquals(31f,rectangle.topStart.toPx(size,androidx.compose.ui.unit.Density(1f)),0f)
    }
    @Test fun backgroundFrameStartsAndEndsAtTheActualComponentAndPanel() {
        val from=Rect(20f,600f,300f,648f);val to=Rect(16f,250f,324f,620f)
        assertEquals(from,CourseMorphGeometry.frame(from,to,0f,36f))
        assertEquals(to,CourseMorphGeometry.frame(from,to,1f,36f))
    }
    @Test fun sharedTextFollowsACurveRatherThanALinearDiagonal() {
        val start=Offset(20f,600f);val end=Offset(40f,280f)
        assertEquals(start,CourseMorphGeometry.curve(start,end,0f,36f))
        assertEquals(end,CourseMorphGeometry.curve(start,end,1f,36f))
        val mid=CourseMorphGeometry.curve(start,end,.5f,36f)
        assertTrue(mid.y<(start.y+end.y)/2)
    }
    @Test fun elasticOvershootKeepsAValidWindow() {
        val frame=CourseMorphGeometry.frame(Rect(10f,20f,50f,80f),Rect(0f,0f,300f,400f),1.02f,36f)
        assertTrue(frame.width>300f);assertTrue(frame.height>0f)
        assertEquals(0f,CourseMorphGeometry.smooth(-1f),0f)
        assertEquals(1f,CourseMorphGeometry.smooth(2f),0f)
    }
    @Test fun anotherSourceIsBlockedWhileTheFirstOpenIsPending() {
        val queue=MorphIntentQueue();assertTrue(queue.request("status"));assertFalse(queue.request("course-A"))
        assertEquals("status",queue.desiredKey)
    }
    @Test fun returningPanelCanAcceptAnotherSourceBeforeReachingZero() {
        val queue=MorphIntentQueue();queue.request("status");queue.dismiss()
        assertTrue(queue.request("course-A",busy=true,returning=true))
        assertEquals("course-A",queue.desiredKey)
    }
    @Test fun repeatedSourceCannotQueueOrToggleAnAdditionalOpening() {
        val queue=MorphIntentQueue();queue.request("status");assertFalse(queue.request("status"))
        assertEquals("status",queue.desiredKey)
    }
    @Test fun dismissBeforeFirstFrameCancelsThePendingOpening() {
        val queue=MorphIntentQueue();queue.request("status");queue.dismiss()
        assertNull(queue.desiredKey);assertTrue(queue.request("course-A"))
    }
    @Test fun continuousRetargetingKeepsOnlyTheMostRecentSelection() {
        val queue=MorphIntentQueue();queue.request("A");queue.dismiss()
        for(key in listOf("B","A","C","B"))assertTrue(queue.request(key,busy=true,returning=true))
        assertEquals("B",queue.desiredKey)
        queue.dismiss();assertNull(queue.desiredKey)
    }
    @Test fun theSameSourceCanReverseItsClosingFlight() {
        val controller=CourseMorphController()
        val request=MorphRequest(MorphSnapshot("status",Rect(0f,0f,100f,48f),24f,androidx.compose.ui.graphics.Color.White,emptyList()),CourseMorphContent.Status)
        controller.request(request)
        val flight=CourseMorphFlight(request);controller.flight=flight
        controller.dismiss();assertTrue(flight.returning)
        val generation=controller.cacheEpoch
        controller.request(request)
        assertSame(flight,controller.flight);assertEquals("status",controller.intents.desiredKey)
        assertEquals(generation,controller.cacheEpoch)
    }
    @Test fun rapidReplacementDoesNotChangeTheVisibleFlightUntilItReturns() {
        val controller=CourseMorphController()
        fun request(key:String)=MorphRequest(MorphSnapshot(key,Rect(0f,0f,100f,48f),24f,androidx.compose.ui.graphics.Color.White,emptyList()),CourseMorphContent.Status)
        val original=request("A");controller.request(original)
        val flight=CourseMorphFlight(original);controller.flight=flight;controller.dismiss()
        controller.request(request("B"));controller.request(request("C"))
        assertSame(flight,controller.flight);assertTrue(controller.retargeting)
        assertEquals("C",controller.desired?.snapshot?.key)
        controller.dismiss();assertNull(controller.desired);assertFalse(controller.retargeting)
    }
    @Test fun outsideTapDuringOpeningOnlyDismissesWithoutPreparingAnotherOpen() {
        val controller=CourseMorphController()
        val request=MorphRequest(MorphSnapshot("status",Rect(0f,0f,100f,48f),24f,androidx.compose.ui.graphics.Color.White,emptyList()),CourseMorphContent.Status)
        controller.request(request)
        val flight=CourseMorphFlight(request);controller.flight=flight
        val generation=controller.cacheEpoch
        controller.animationTap(Offset(300f,100f))
        assertTrue(flight.returning);assertNull(controller.desired);assertNull(controller.intents.desiredKey)
        assertEquals(generation,controller.cacheEpoch);assertFalse(controller.retargeting)
    }
}
