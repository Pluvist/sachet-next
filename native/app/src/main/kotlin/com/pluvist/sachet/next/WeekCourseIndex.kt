package com.pluvist.sachet.next

import androidx.compose.runtime.Immutable
import java.time.LocalTime

/** Piecewise timeline: real minutes within teaching periods, compressed long breaks. */
internal fun axisMinute(time:LocalTime):Float {
    val minute=time.hour*60+time.minute
    return when {
        minute<=730 -> (minute-480).toFloat()
        minute<840 -> 250f+(minute-730)*.15f
        minute<=1090 -> 266.5f+minute-840
        minute<1155 -> 516.5f+(minute-1090)*.25f
        else -> 532.75f+minute-1155
    }
}

@Immutable internal data class WeekCourseBlock(val course:Course,val topMinute:Float,val heightMinutes:Float)
@Immutable internal data class WeekCoursePage(val days:List<List<WeekCourseBlock>>)

/** Build once per schedule revision, rather than filtering/parsing during a pager drag. */
internal class WeekCourseIndex(courses:List<Course>) {
    private val blocks=courses.map { course ->
        val (start,end)=course.interval()
        val top=axisMinute(start)
        WeekCourseBlock(course,top,axisMinute(end)-top)
    }
    private val pages=List(60) { page ->
        WeekCoursePage(List(7) { day -> blocks.filter{it.course.weekday==day+1&&page+1 in it.course.weeks} })
    }
    operator fun get(week:Int)=pages[week-1]
}
