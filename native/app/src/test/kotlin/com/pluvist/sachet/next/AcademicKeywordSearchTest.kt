package com.pluvist.sachet.next

import androidx.compose.ui.text.input.TextFieldValue
import org.junit.Assert.*
import org.junit.Test

class AcademicKeywordSearchTest {
    private val course=AcademicRecord("高等数学 A",listOf("课程号" to "MATH-101","课程性质" to "必修","开课学院" to "数学学院"))
    private val book=AcademicRecord("大学物理",listOf("教材名称" to "大学物理学","作者" to "测试作者","ISBN" to "978-7-12345","出版社" to "高等教育出版社"))
    @Test fun chineseKeywordsMatchCourseMetadata() {
        assertTrue(AcademicKeywordSearch.matches(course,"数学"))
        assertTrue(AcademicKeywordSearch.matches(course,"必修"))
        assertFalse(AcademicKeywordSearch.matches(course,"大学物理"))
    }
    @Test fun courseCodesAreCaseInsensitiveAndNormalizeWidth() {
        assertTrue(AcademicKeywordSearch.matches(course,"math-101"))
        assertTrue(AcademicKeywordSearch.matches(course,"ＭＡＴＨ－１０１"))
    }
    @Test fun bookAuthorPublisherAndIsbnAreSearchable() {
        assertTrue(AcademicKeywordSearch.matches(book,"测试作者"))
        assertTrue(AcademicKeywordSearch.matches(book,"高等教育"))
        assertTrue(AcademicKeywordSearch.matches(book,"978-7-12345"))
    }
    @Test fun severalKeywordsMustAllMatchAndEmptyQueryRestoresResults() {
        assertTrue(AcademicKeywordSearch.matches(course,"  数学  MATH-101 "))
        assertFalse(AcademicKeywordSearch.matches(course,"数学 物理"))
        assertTrue(AcademicKeywordSearch.matches(course," \t\n"))
    }
    @Test fun fieldLabelsDoNotProduceFalseMatches() {
        assertFalse(AcademicKeywordSearch.matches(course,"课程号"))
    }
    @Test fun retiredPageCannotDetachTheNewSearchOwner() {
        val controller=AcademicSearchController()
        val previous=AcademicSearchSession("cultivation","搜索课程")
        val current=AcademicSearchSession("textbooks","搜索教材")
        controller.attach(previous);controller.attach(current);controller.detach(previous)
        assertSame(current,controller.session)
        controller.detach(current);assertNull(controller.session)
    }
    @Test fun cancelSearchClearsFilterAndCollapseStateTogether() {
        val session=AcademicSearchSession("cultivation","搜索课程")
        session.query=TextFieldValue("math");session.expanded=true;session.close()
        assertEquals("",session.query.text);assertFalse(session.expanded)
    }
    @Test fun expandedSearchOnAnotherRouteCannotDimOrInterceptTheCurrentPage() {
        val controller=AcademicSearchController()
        val session=AcademicSearchSession("cultivation","搜索课程")
        controller.attach(session);session.expanded=true
        assertSame(session,controller.forRoute("cultivation"))
        assertNull(controller.forRoute("textbooks"));assertNull(controller.forRoute(null))
        controller.detach(session);assertNull(controller.forRoute("cultivation"))
    }
}
