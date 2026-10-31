package com.pluvist.sachet.next

import org.junit.Assert.*
import org.junit.Test
import java.time.*

class WeekCourseIndexTest {
    @Test fun cachedPagesMatchDailyCourseMembershipAndBuildingTimes() {
        val semester=LocalDate.of(2026,10,26)
        val courses=listOf(
            Course("a","普通","一教","",1,1,2,setOf(1,2,12,60)),
            Course("b","错峰","逸夫楼201","",1,3,4,setOf(2,12)),
            Course("c","晚课","信息科技大楼","",7,9,11,setOf(1,12,60)))
        val index=WeekCourseIndex(courses)
        for(week in 1..60)for(day in 1..7) {
            val expected=CourseClock.onDate(courses,semester,semester.plusWeeks((week-1).toLong()).plusDays((day-1).toLong()),ZoneId.of("Asia/Shanghai"))
                .map{it.course}.distinct()
            val actual=index[week].days[day-1]
            assertEquals(expected.map{it.id},actual.map{it.course.id})
            for(block in actual) {
                val (start,end)=block.course.interval()
                assertEquals(axisMinute(start),block.topMinute,0f)
                assertEquals(axisMinute(end)-axisMinute(start),block.heightMinutes,0f)
            }
        }
    }
    @Test fun repeatedPageReadsReusePreparedBlocks() {
        val course=Course("a","课程","逸夫楼","",3,1,2,setOf(1,2))
        val index=WeekCourseIndex(listOf(course))
        assertSame(index[1],index[1])
        assertSame(index[1].days[2].single(),index[2].days[2].single())
        assertTrue(index[60].days.all{it.isEmpty()})
        assertEquals(10f,index[1].days[2].single().topMinute,0f)
    }
}
