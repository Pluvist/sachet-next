package com.pluvist.sachet.next

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class AcademicProtocolTest {
    @Test fun deniedModuleDoesNotMasqueradeAsAnExpiredLoginOrEmptyList() {
        val body="<html><body>教材预订 无功能权限</body></html>"
        assertFalse(AcademicProtocol.isLoginPage(body))
        try{AcademicProtocol.rows(body);fail()}catch(e:AcademicFailure){assertEquals("permission",e.reason)}
    }
    @Test fun academicPageWithUnrelatedUsernameInputIsNotLogin() {
        val html="<select id=xnm><option value=2026 selected>2026-2027</option></select><input id=yhm>"
        assertFalse(AcademicProtocol.isLoginPage(html))
        assertTrue(AcademicProtocol.isLoginPage("<form><input id=yhm><input name=mm type=password></form>"))
        assertFalse(AcademicProtocol.isLoginPage("<form><input id=yhm></form><form><input id=mm></form>"))
    }
    @Test fun escapedTranscriptResponseFromServerIsDecoded() {
        assertEquals("https://jw.xtu.edu.cn/jwglxt/templete/scorePrint/score_test_123.pdf",
            AcademicProtocol.transcriptUrl("\"\\/jwglxt\\/templete\\/scorePrint\\/score_test_123.pdf#xx\""))
    }
    @Test fun transcriptAbsoluteSameOriginIsAccepted() {
        assertEquals("https://jw.xtu.edu.cn/jwglxt/templete/scorePrint/test.pdf",AcademicProtocol.transcriptUrl("https://jw.xtu.edu.cn/jwglxt/templete/scorePrint/test.pdf#ok"))
    }
    @Test(expected=IllegalArgumentException::class) fun transcriptCannotSendCookieToOtherHost() {
        AcademicProtocol.transcriptUrl("https://example.com/jwglxt/templete/scorePrint/test.pdf")
    }
    @Test(expected=IllegalArgumentException::class) fun transcriptCannotEscapePrintFolder() {
        AcademicProtocol.transcriptUrl("/jwglxt/templete/scorePrint/../private.pdf")
    }
    @Test(expected=IllegalArgumentException::class) fun transcriptCannotUseEncodedTraversal() {
        AcademicProtocol.transcriptUrl("/jwglxt/templete/scorePrint/%2e%2e/private.pdf")
    }
    @Test fun optionsRetainServerDefaultsAndOfferAllSemesters() {
        val form=AcademicProtocol.form("exams","<select id=cx_xnm><option value=2026 selected>2026-2027</option></select><select id=cx_xqm><option value=3 selected>1</option><option value=12>2</option></select><select id=unrelated><option value=restrict>restrict</option></select>")
        assertEquals(listOf("cx_xnm","cx_xqm"),form.choices.map{it.key})
        assertEquals("2026",form.choices.first().selected)
        assertEquals("",form.choices.last().values.first().first)
    }
    @Test fun missingFormFailsInsteadOfRenderingAnEmptyUnusableQuery() {
        try {AcademicProtocol.form("textbooks","<html><body>not available</body></html>");fail()}
        catch(e:AcademicFailure){assertEquals("missing-form",e.reason)}
    }
    @Test fun emptyResultsAreSuccessButMissingItemsIsFailure() {
        assertTrue(AcademicProtocol.rows("{\"items\":[],\"totalResult\":0}").first.isEmpty())
        try{AcademicProtocol.rows("{\"message\":\"failed\"}");fail()}catch(e:AcademicFailure){assertEquals("missing-items",e.reason)}
    }
    @Test fun curriculumParametersContainLegacyEmptyFilters() {
        val data=AcademicRequests.parameters("curriculum",mapOf("jxzxjhxx_id" to "plan"),123L)
        assertEquals("",data["jyxdxnm"]);assertEquals("",data["yxxdxqm"]);assertEquals("",data["xdlx"])
        assertEquals("123",data["nd"]);assertEquals("plan",data["jxzxjhxx_id"])
        assertEquals("jyxdxnm,jyxdxqm,kch ",data["queryModel.sortName"])
    }
    @Test fun cultivationDoesNotLeakUnrelatedHtmlSelectFilters() {
        val data=AcademicRequests.parameters("cultivation",mapOf("nj_cx" to "2026","jg_id" to "school","zyh_id_cx" to "major","jyxdxnm_cx" to "1990"))
        assertEquals("major",data["zyh_id"]);assertEquals("2026",data["njdm_id"])
        assertEquals("zymc+",data["queryModel.sortName"]);assertFalse(data.containsKey("jyxdxnm_cx"))
    }
    @Test fun textbooksPreserveEmptyFilterFieldsAndOriginalPageSize() {
        val data=AcademicRequests.parameters("textbooks",mapOf("xnm_cx" to "2026","xqm_cx" to "3"))
        assertEquals("",data["jczz"]);assertEquals("",data["isbn"]);assertEquals("100",data["queryModel.showCount"])
        assertEquals("query",data["doType"])
    }
    @Test fun availableTextbookFormUsesItsOwnSemesterNames() {
        val form=AcademicProtocol.form("textbooks","<select id=xnm_cx><option value=2026 selected>2026-2027</option></select><select id=xqm_cx><option value=3 selected>1</option><option value=12>2</option></select>")
        val data=AcademicRequests.parameters("textbooks",form.choices.associate{it.key to it.selected})
        assertEquals("2026",data["xnm"]);assertEquals("3",data["xqm"])
    }
    @Test fun gpaKeepsCombinedSemesterCodesInsteadOfYearTermAliases() {
        val data=AcademicRequests.parameters("gpa",mapOf("qsXnxq" to "202503","zzXnxq" to "202512","xbx" to "bx"))
        assertEquals("202503",data["qsXnxq"]);assertEquals("202512",data["zzXnxq"])
        assertEquals("bx",data["xbx"]);assertFalse(data.containsKey("xnm"))
    }
    @Test fun classroomMatrixReflectsOnlyActuallyReturnedAvailability() {
        fun room(name:String)=JSONObject().put("cdmc",name).put("zws","50")
        val rows=AcademicRecords.mergeClassrooms(listOf(listOf(room("A")),emptyList(),listOf(room("B")),listOf(room("A")),emptyList()))
        assertEquals(listOf("A","B"),rows.map{it.getString("cdmc")})
        assertEquals("03",rows[0].getString("_freeSessions"));assertEquals("2",rows[1].getString("_freeSessions"))
    }
    @Test fun classroomCampusAndSeatFiltersArePreserved() {
        val input=mapOf("dm_cx" to "2026-3","weeks" to "1","weekdays" to "1","sessions" to "1-2","xqh_id" to "03","qszws" to "40","jszws" to "80")
        val data=AcademicRequests.parameters("classrooms",input)
        assertEquals("03",data["xqh_id"]);assertEquals("40",data["qszws"]);assertEquals("80",data["jszws"])
        try{AcademicRequests.parameters("classrooms",input+("jszws" to "20"));fail()}catch(e:IllegalArgumentException){assertTrue(e.message!!.contains("座位数"))}
    }
    @Test fun gpaAndTextbookFieldsUseOriginalResponseNames() {
        assertTrue(AcademicRecords.record("gpa",JSONObject().put("jdnjzypm",7)).fields.contains("年级专业排名" to "7"))
        assertTrue(AcademicRecords.record("textbooks",JSONObject().put("jczz","Author").put("discount_price","28.5")).fields.contains("作者" to "Author"))
    }
}
