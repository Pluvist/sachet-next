package com.pluvist.sachet.next

import org.junit.Assert.*
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.TimeZone

class CourseTimelineTest {
    private val zone = TimeZone.getTimeZone("Asia/Shanghai")
    private fun at(value: String, tz: TimeZone = zone) =
        SimpleDateFormat("yyyy-MM-dd HH:mm").apply { timeZone = tz }.parse(value)!!.time
    private fun t(time: String) = at("2026-10-16 $time")
    private val first get() = LiveLesson("数学", "逸夫楼201", t("08:10"), t("08:55"))
    private val second get() = LiveLesson("数学", "逸夫楼201", t("09:05"), t("09:50"))
    private val afternoon get() = LiveLesson("物理", "第一教学楼102", t("14:00"), t("14:45"))
    private val lessons get() = listOf(afternoon, second, first)
    private fun state(time: String, source: List<LiveLesson> = lessons) = CourseTimeline.resolve(t(time), source, zone)

    @Test fun emptyDayNeverProducesAnActivityEvenWithFutureCachedCourses() {
        val tomorrow = LiveLesson("明天", "教三", at("2026-10-17 08:00"), at("2026-10-17 08:45"))
        val empty = state("12:00", listOf(tomorrow))
        assertEquals(LiveCoursePhase.NONE, empty.phase)
        assertNull(empty.current); assertNull(empty.next)
        assertFalse(CourseTimeline.promote(empty, t("12:00")))
        assertEquals(at("2026-10-17 00:00"), CourseTimeline.nextWake(t("12:00"), listOf(tomorrow), empty, zone = zone))
        assertNull(CourseTimeline.nextWake(t("12:00"), emptyList(), state("12:00", emptyList()), zone = zone))
    }

    @Test fun firstLessonIsShownBeforeClassAndStartsInclusively() {
        val waiting = state("08:09")
        assertEquals(LiveCoursePhase.WAITING, waiting.phase)
        assertEquals(first, waiting.next)
        val current = state("08:10")
        assertEquals(LiveCoursePhase.IN_CLASS, current.phase)
        assertEquals(first, current.current)
        assertEquals(second, current.next)
        assertEquals(45 * 60_000L, current.current!!.end - t("08:10"))
    }

    @Test fun exactEndSwitchesToNextClassWithCorrectLocationDuringTheBreak() {
        val end = state("08:55")
        assertEquals(LiveCoursePhase.WAITING, end.phase)
        assertNull(end.current)
        assertEquals(second, end.next)
        assertEquals(LiveCoursePhase.IN_CLASS, state("09:05").phase)
        val lunch = state("09:50")
        assertEquals(LiveCoursePhase.WAITING, lunch.phase)
        assertEquals("第一教学楼102", lunch.next!!.place)
        assertEquals(t("14:00"), lunch.next!!.start)
    }

    @Test fun afterLastClassCompletesTodayWithoutSubstitutingTomorrow() {
        val tomorrow = LiveLesson("明天", "教三", at("2026-10-17 08:00"), at("2026-10-17 08:45"))
        val end = state("14:45", lessons + tomorrow)
        assertEquals(LiveCoursePhase.COMPLETED, end.phase)
        assertNull(end.current); assertNull(end.next)
        assertFalse(CourseTimeline.promote(end, t("14:45")))
        assertEquals(at("2026-10-17 00:00"), CourseTimeline.nextWake(t("14:45"), lessons + tomorrow, end, zone = zone))
        assertEquals(LiveCoursePhase.NONE, CourseTimeline.resolve(at("2026-10-17 00:00"), lessons, zone).phase)
    }

    @Test fun promotionStartsNearFirstClassAndStopsWhenFinished() {
        assertFalse(CourseTimeline.promote(state("07:39"), t("07:39")))
        assertTrue(CourseTimeline.promote(state("07:40"), t("07:40")))
        assertTrue(CourseTimeline.promote(state("08:30"), t("08:30")))
        assertTrue(CourseTimeline.promote(state("12:00"), t("12:00")))
        assertFalse(CourseTimeline.promote(state("18:00"), t("18:00")))
    }

    @Test fun alarmsAdvanceAtPromotionStartClassStartEndAndNextClass() {
        fun wake(time: String) = CourseTimeline.nextWake(t(time), lessons, state(time), zone = zone)
        assertEquals(t("07:40"), wake("06:00"))
        assertEquals(t("08:10"), wake("07:40"))
        assertEquals(t("08:55"), wake("08:10"))
        assertEquals(t("09:05"), wake("08:55"))
        assertEquals(t("09:50"), wake("09:05"))
    }

    @Test fun dismissalSkipsTheRestOfTodayAndResumesOnNextTeachingDay() {
        val future = LiveLesson("下周", "教三", at("2026-10-19 08:00"), at("2026-10-19 08:45"))
        assertEquals(at("2026-10-19 00:00"),
            CourseTimeline.nextWake(t("08:30"), lessons + future, state("08:30"), dismissed = true, zone = zone))
        assertNull(CourseTimeline.nextWake(t("08:30"), lessons, state("08:30"), dismissed = true, zone = zone))
    }

    @Test fun unsortedAndInvalidCoursesCannotCreatePhantomLessons() {
        val invalid = first.copy(start = t("10:00"), end = t("09:00"))
        assertEquals(listOf(first, second, afternoon), state("08:30", lessons + invalid).today)
        assertEquals(LiveCoursePhase.NONE, state("08:30", listOf(invalid)).phase)
    }

    @Test fun midnightUsesCalendarDaysAcrossDaylightSavingTime() {
        val tz = TimeZone.getTimeZone("America/New_York")
        val now = at("2026-03-08 12:00", tz)
        val day = CourseTimeline.resolve(now, emptyList(), tz)
        assertEquals(at("2026-03-08 00:00", tz), day.midnight)
        assertEquals(at("2026-03-09 00:00", tz), day.tomorrow)
        assertEquals(23 * 60 * 60_000L, day.tomorrow - day.midnight)
    }

    @Test fun numericCountdownRoundsWithoutWordsAndClampsAtZero() {
        assertEquals("45:00", CourseTimeline.countdown(2_700_000))
        assertEquals("42:18", CourseTimeline.countdown(2_538_000))
        assertEquals("00:01", CourseTimeline.countdown(1))
        assertEquals("00:00", CourseTimeline.countdown(-1))
        assertEquals("01:00:00", CourseTimeline.countdown(3_600_000))
        assertTrue(CourseTimeline.countdown(2_538_000).matches(Regex("[0-9:]+")))
    }

    @Test fun compactChipRetainsTimeAndRecognizableBuildingName() {
        assertEquals("信科", CourseTimeline.compactPlace("信息科技大楼204"))
        assertEquals("逸夫", CourseTimeline.compactPlace("逸夫楼201"))
        assertEquals("教三", CourseTimeline.compactPlace("第三教学楼217"))
        assertEquals("一教", CourseTimeline.compactPlace("第一教学楼102"))
        assertEquals("体育", CourseTimeline.compactPlace("  体育馆  "))
    }
}
