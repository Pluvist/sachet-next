package com.pluvist.sachet.next

import androidx.compose.animation.core.TargetBasedAnimation
import androidx.compose.animation.core.VectorConverter
import org.junit.Assert.*
import org.junit.Test

class CourseMorphMotionTest {
    private val lesson=CourseMorphContent.Lesson(Course("test","测试课程","一教101","教师",1,1,2,setOf(1)))
    @Test fun lessonOpeningHasOnlySubtleOvershootAndStillSettlesPromptly() {
        val motion=TargetBasedAnimation(CourseMorphMotion.open(lesson),Float.VectorConverter,0f,1f)
        val peak=(0..1000 step 2).maxOf{motion.getValueFromNanos(it*1_000_000L)}
        assertTrue("Detail should retain a subtle spring",peak>1f)
        assertTrue("Detail overshoot should be below 1%",peak<1.01f)
        assertEquals(1f,motion.getValueFromNanos(1_000_000_000L),.001f)
    }
    @Test fun lessonClosingDoesNotBounceVisiblyPastItsCard() {
        val motion=TargetBasedAnimation(CourseMorphMotion.close(lesson,false),Float.VectorConverter,1f,0f)
        val trough=(0..1000 step 2).minOf{motion.getValueFromNanos(it*1_000_000L)}
        assertTrue(trough>-.01f)
        assertEquals(0f,motion.getValueFromNanos(1_000_000_000L),.001f)
    }
}
