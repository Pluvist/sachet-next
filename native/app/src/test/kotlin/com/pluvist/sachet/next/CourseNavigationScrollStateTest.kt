package com.pluvist.sachet.next

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import org.junit.Assert.*
import org.junit.Test

class CourseNavigationScrollStateTest {
    private class Viewport(override val rangePx:Float=1000f):BottomNavigationViewport {
        override val distanceToStartPx=200f
        override val atStart=false
        override val atEnd=false
        override val isScrolling=true
    }
    @Test fun collapsesAfterForwardScrollAndRevealsAfterReverseScroll() {
        val state=CourseNavigationScrollState(false)
        state.bind(true,64f,Viewport())
        val observer=state.nestedScrollConnection
        assertEquals(Offset.Zero,observer.onPreScroll(Offset(0f,-80f),NestedScrollSource.UserInput))
        assertEquals(Offset.Zero,observer.onPostScroll(Offset(0f,-80f),Offset.Zero,NestedScrollSource.UserInput))
        assertTrue(state.compactTarget)
        state.finishGesture()
        observer.onPreScroll(Offset(0f,80f),NestedScrollSource.UserInput)
        observer.onPostScroll(Offset(0f,80f),Offset.Zero,NestedScrollSource.UserInput)
        assertFalse(state.compactTarget)
    }
    @Test fun shortContentDoesNotCollapseOrConsumeScroll() {
        val state=CourseNavigationScrollState(false)
        state.bind(true,64f,Viewport(60f))
        val observer=state.nestedScrollConnection
        observer.onPreScroll(Offset(0f,-200f),NestedScrollSource.UserInput)
        assertEquals(Offset.Zero,observer.onPostScroll(Offset(0f,-200f),Offset.Zero,NestedScrollSource.UserInput))
        state.finishGesture()
        assertFalse(state.compactTarget)
    }
    @Test fun compactNavigationTapExpandsWithoutChangingRoutes() {
        val state=CourseNavigationScrollState(true)
        state.expand()
        assertFalse(state.compactTarget)
    }
}
