package com.pluvist.sachet.next

import org.junit.Assert.*
import org.junit.Test
import java.time.*

class CalendarMonthDataTest {
    @Test fun countsMatchDailyTimelineAcrossMonthAndWeekBoundaries() {
        val start=LocalDate.of(2026,10,26)
        val courses=listOf(
            Course("a","测试","逸夫楼","",1,1,2,setOf(1,3)),
            Course("b","测试","一教","",7,9,11,setOf(1,2,3)))
        val month=YearMonth.of(2026,11)
        val counts=CalendarMonthData.counts(courses,start,month)
        for(day in 1..month.lengthOfMonth())assertEquals(CourseClock.onDate(courses,start,month.atDay(day),ZoneId.of("Asia/Shanghai")).size,counts[day]?:0)
        assertEquals(3,counts[1]);assertNull(counts[2]);assertEquals(2,counts[9])
    }
    @Test fun emptyScheduleHasNoCourseMarks() {
        assertTrue(CalendarMonthData.counts(emptyList(),LocalDate.of(2026,10,26),YearMonth.of(2026,11)).isEmpty())
    }
}
