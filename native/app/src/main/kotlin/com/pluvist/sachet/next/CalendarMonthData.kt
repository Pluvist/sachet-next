package com.pluvist.sachet.next

import java.time.LocalDate
import java.time.YearMonth

/** Counts lesson sections without allocating instants and per-section lesson objects per cell. */
internal object CalendarMonthData {
    fun counts(courses:List<Course>,semester:LocalDate,month:YearMonth):Map<Int,Int> = buildMap {
        for(day in 1..month.lengthOfMonth()) {
            val date=month.atDay(day)
            val week=CourseClock.week(date,semester)
            val count=courses.sumOf{if(it.weekday==date.dayOfWeek.value&&week in it.weeks)it.last-it.first+1 else 0}
            if(count>0)put(day,count)
        }
    }
}
