package com.pluvist.sachet.next

import java.time.*
import java.time.temporal.ChronoUnit
import org.json.JSONArray
import org.json.JSONObject

data class Course(
    val id: String, val title: String, val place: String, val teacher: String,
    val weekday: Int, val first: Int, val last: Int, val weeks: Set<Int>,
    val routine: String = "auto",
) {
    val staggered: Boolean get() = routine == "staggered" ||
        (routine == "auto" && (place.contains("逸夫楼") || place.contains("信息科技大楼")))
    fun interval(): Pair<LocalTime, LocalTime> =
        LessonTimes.start(first, staggered) to LessonTimes.end(last, staggered)
}

object LessonTimes {
    private val starts = listOf("08:00", "08:55", "10:20", "11:15", "14:00", "14:55", "16:20", "17:15", "19:15", "20:10", "21:05").map(LocalTime::parse)
    fun start(section: Int, staggered: Boolean): LocalTime {
        require(section in 1..11) { "课程节次超出范围" }
        return starts[section - 1].plusMinutes(if (staggered && section <= 8) 10 else 0)
    }
    fun end(section: Int, staggered: Boolean): LocalTime = start(section, staggered).plusMinutes(45)
}

object CourseParser {
    fun weeks(raw: String): Set<Int> {
        val result = sortedSetOf<Int>()
        raw.replace("周", "").replace('，', ',').replace(Regex("\\s"), "").split(',').filter(String::isNotEmpty).forEach { part ->
            val values = Regex("\\d+").findAll(part).map { it.value.toInt() }.toList()
            require(values.isNotEmpty() && values.size <= 2) { "无法解析周次：$raw" }
            val end = values.last(); val start = values.first()
            require(start in 1..60 && end in start..60) { "周次范围无效：$raw" }
            (start..end).filterTo(result) { (!part.contains("单") || it % 2 == 1) && (!part.contains("双") || it % 2 == 0) }
        }
        require(result.isNotEmpty()) { "课程周次为空" }
        return result
    }

    fun fromServer(body: String): List<Course> {
        val rows = JSONObject(body).getJSONArray("kbList")
        return (0 until rows.length()).map { index ->
            val row = rows.getJSONObject(index)
            val sections = Regex("\\d+").findAll(row.getString("jc")).map { it.value.toInt() }.toList()
            val first = sections.firstOrNull() ?: error("课程节次为空")
            val last = sections.last()
            require(first in 1..11 && last in first..11) { "课程节次无效" }
            val day = row.getString("xqj").toInt()
            require(day in 1..7) { "课程星期无效" }
            Course("${row.optString("jxb_id").ifBlank { row.optString("kcmc") }}-$day-$first-$last-${row.optString("cdmc")}-${row.optString("zcd")}",
                row.getString("kcmc"), row.optString("cdmc"), row.optString("xm"), day, first, last,
                weeks(row.getString("zcd")))
        }
    }

    fun fromLegacy(body: String): List<Course> {
        val slots = JSONArray(body)
        return buildList {
            for (slot in 0 until slots.length()) {
                val rows = slots.getJSONArray(slot)
                for (i in 0 until rows.length()) {
                    val row = rows.getJSONObject(i)
                    val item = row.optInt("item", slot)
                    val first = listOf(1, 3, 5, 7, 9)[item % 5]
                    val weeks = row.getJSONArray("weeks")
                    add(Course("$item-$i-${row.optString("title")}", row.getString("title"), row.optString("place"),
                        row.optString("instructor"), item / 5 + 1, first,
                        (first + row.optInt("length", 2) - 1).coerceAtMost(11),
                        (0 until weeks.length()).map { weeks.getInt(it) }.toSet()))
                }
            }
        }
    }
}

data class DatedCourse(val course: Course, val start: Instant, val end: Instant,val section:Int=course.first) {
    fun startTime(zone:ZoneId=ZoneId.systemDefault())=start.atZone(zone).toLocalTime()
    fun endTime(zone:ZoneId=ZoneId.systemDefault())=end.atZone(zone).toLocalTime()
}
data class CourseStatus(val current: DatedCourse?, val next: DatedCourse?, val today: List<DatedCourse>) {
    val completed: Boolean get() = today.isNotEmpty() && current == null && next == null
}

object CourseClock {
    fun week(date: LocalDate, semester: LocalDate) = Math.floorDiv(ChronoUnit.DAYS.between(semester, date).toInt(), 7) + 1
    fun onDate(courses: List<Course>, semester: LocalDate, date: LocalDate, zone: ZoneId): List<DatedCourse> {
        val week = week(date, semester)
        return courses.filter { it.weekday == date.dayOfWeek.value && week in it.weeks }.flatMap { course ->
            (course.first..course.last).map{section->
                val start=LessonTimes.start(section,course.staggered);val end=LessonTimes.end(section,course.staggered)
                DatedCourse(course, date.atTime(start).atZone(zone).toInstant(), date.atTime(end).atZone(zone).toInstant(),section)
            }
        }.sortedBy { it.start }
    }
    fun status(courses: List<Course>, semester: LocalDate, now: Instant, zone: ZoneId = ZoneId.systemDefault()): CourseStatus {
        val today = onDate(courses, semester, now.atZone(zone).toLocalDate(), zone)
        val current = today.firstOrNull { !now.isBefore(it.start) && now.isBefore(it.end) }
        val next = today.firstOrNull { if (current == null) it.start.isAfter(now) else !it.start.isBefore(current.end) }
        return CourseStatus(current, next, today)
    }
}
