package io.github.wyvern1723.sachet

import java.util.Calendar
import java.util.TimeZone

data class LiveLesson(val title: String, val place: String, val start: Long, val end: Long)
enum class LiveCoursePhase { NONE, WAITING, IN_CLASS, COMPLETED }
data class LiveCourseState(val phase: LiveCoursePhase, val today: List<LiveLesson>,
    val current: LiveLesson?, val next: LiveLesson?, val midnight: Long, val tomorrow: Long)

/** Uses the exact lesson timestamps already resolved by Flutter's homepage. */
object CourseTimeline {
    fun dayStart(time: Long, zone: TimeZone = TimeZone.getDefault()): Long =
        Calendar.getInstance(zone).apply {
            timeInMillis = time; set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    fun resolve(now: Long, lessons: List<LiveLesson>, zone: TimeZone = TimeZone.getDefault()): LiveCourseState {
        val midnight = dayStart(now, zone)
        val tomorrow = Calendar.getInstance(zone).apply {
            timeInMillis = midnight; add(Calendar.DAY_OF_MONTH, 1)
        }.timeInMillis
        val today = lessons.filter { it.start >= midnight && it.start < tomorrow && it.end > it.start }
            .sortedBy { it.start }
        val current = today.firstOrNull { it.start <= now && it.end > now }
        val next = today.firstOrNull { if (current == null) it.start > now else it.start >= current.end }
        val phase = when {
            today.isEmpty() -> LiveCoursePhase.NONE
            current != null -> LiveCoursePhase.IN_CLASS
            next != null -> LiveCoursePhase.WAITING
            else -> LiveCoursePhase.COMPLETED
        }
        return LiveCourseState(phase, today, current, next, midnight, tomorrow)
    }

    fun promote(state: LiveCourseState, now: Long): Boolean =
        state.current != null || (state.next != null &&
            (state.today.any { it.start <= now } || state.next.start - now <= 30*60_000L))

    fun nextWake(now: Long, lessons: List<LiveLesson>, state: LiveCourseState,
        dismissed: Boolean = false, zone: TimeZone = TimeZone.getDefault()): Long? {
        val futureDay = lessons.filter { it.start >= state.tomorrow && it.end > it.start }
            .minByOrNull { it.start }?.let { dayStart(it.start, zone) }
        if (dismissed || state.phase == LiveCoursePhase.NONE) return futureDay
        if (state.phase == LiveCoursePhase.COMPLETED) return state.tomorrow
        val boundary = state.today.flatMap { listOf(it.start, it.end) }.filter { it > now }.minOrNull()
        val promoteAt = if (promote(state, now)) null else
            state.next?.start?.minus(30*60_000L)?.takeIf { it > now }
        return listOfNotNull(boundary, promoteAt, state.tomorrow).minOrNull()
    }

    fun compactPlace(place: String): String = when {
        place.contains("信息科技") -> "信科"
        place.contains("逸夫") -> "逸夫"
        place.contains("第三教学") || place.contains("教三") -> "教三"
        place.contains("第二教学") || place.contains("教二") -> "教二"
        place.contains("第一教学") || place.contains("一教") -> "一教"
        else -> place.trim().take(2)
    }
}
