package com.pluvist.sachet.next
import org.junit.Assert.*
import org.junit.Test
import java.time.*
class CalendarExportTest {
    @Test fun exportsExamTimeAndReminder() {
        val row=org.json.JSONObject().put("kssj","2026-12-23(9:00-11:00)").put("kcmc","数学").put("cdmc","一教")
        val output=CalendarExport.exams(listOf(row),ZoneId.of("Asia/Shanghai"))
        assertTrue(output.contains("DTSTART:20261223T010000Z"));assertTrue(output.contains("DTEND:20261223T030000Z"))
        assertTrue(output.contains("SUMMARY:数学考试"));assertTrue(output.contains("TRIGGER:-PT60M"))
    }
    @Test(expected=IllegalStateException::class) fun rejectsUnscheduledExamInsteadOfInventingTime() {
        CalendarExport.exams(listOf(org.json.JSONObject().put("kssj","待安排")))
    }
    @Test fun exportsActualBuildingTimesAndEscapesFields() {
        val course=Course("course","数学,实验","逸夫楼;101","张老师",1,1,2,setOf(1))
        val output=CalendarExport.ics(listOf(course),LocalDate.of(2026,10,26),ZoneId.of("Asia/Shanghai"))
        assertTrue(output.contains("DTSTART:20261026T001000Z\r\n"))
        assertTrue(output.contains("DTEND:20261026T015000Z\r\n"))
        assertTrue(output.contains("SUMMARY:数学\\,实验"));assertTrue(output.contains("LOCATION:逸夫楼\\;101"))
        assertTrue(output.endsWith("END:VCALENDAR\r\n"))
    }
    @Test fun sharedTeachingClassIdsHaveDistinctOccurrences() {
        val body="""{"kbList":[{"jxb_id":"same","kcmc":"数学","cdmc":"一教","xqj":"1","jc":"1-2节","zcd":"1周"},{"jxb_id":"same","kcmc":"数学","cdmc":"一教","xqj":"1","jc":"3-4节","zcd":"1周"}]}"""
        val courses=CourseParser.fromServer(body)
        assertNotEquals(courses[0].id,courses[1].id)
    }
}
