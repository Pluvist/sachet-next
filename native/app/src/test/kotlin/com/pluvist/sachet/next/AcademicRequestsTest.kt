package com.pluvist.sachet.next
import org.junit.Assert.*
import org.junit.Test

class AcademicRequestsTest {
    @Test fun freeClassroomMasksMatchLegacyRequest() {
        val data=AcademicRequests.parameters("classrooms",mapOf("dm_cx" to "2026-3","weeks" to "1,3","weekdays" to "1-2","sessions" to "1-2,5"))
        assertEquals("2026",data["xnm"]);assertEquals("3",data["xqm"])
        assertEquals("5",data["zcd"]);assertEquals("19",data["jcd"]);assertEquals("1,2",data["xqj"])
        assertFalse(data.containsKey("dm_cx"))
    }
    @Test fun semesterAliasesBecomePostParameters() {
        val data=AcademicRequests.parameters("exams",mapOf("cx_xnm" to "2026","cx_xqm" to "12"))
        assertEquals("2026",data["xnm"]);assertEquals("12",data["xqm"])
        assertEquals("kssj+",data["queryModel.sortName"])
    }
    @Test(expected=IllegalArgumentException::class) fun invalidClassroomSessionRejected() {
        AcademicRequests.numberSet("0,12",11)
    }
}
