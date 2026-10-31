package com.pluvist.sachet.next

import android.content.Context
import org.json.JSONObject

/** Synthetic, read-only UI workload. Never installed in the preview or public app. */
internal class AcademicUiBenchmark(context:Context) {
    init { check(BuildConfig.APPLICATION_ID.endsWith(".benchmark")&&context.packageName.endsWith(".benchmark")) }
    private val year=java.time.LocalDate.now().year.toString()
    private val savedAt=System.currentTimeMillis()
    private val data=QueryFeature.all.associate { feature -> feature.key to List(160) { index ->
        JSONObject().put("kcmc","性能测试课程 ${index+1}").put("cdmc","教学楼 ${index%12+1}-${index%40+101}")
            .apply { when(feature.key) {
                "grades"->{put("cj","90");put("jd","4.0");put("xf","3.0");put("kcxzmc","必修");put("khfsmc","考试")}
                "exams"->{put("kssj","2026-12-01 09:00–11:00");put("ksmc","期末考试")}
                "gpa"->{put("pjxfjd","3.8");put("jdbjpm","8");put("jdzycp","20")}
                "textbooks"->{put("jcmc","测试教材 ${index+1}");put("isbn","9780000000000");put("cbs","测试出版社");put("zz","测试作者");put("sl","1")}
                "classrooms"->{remove("kcmc");put("zws","60");put("jxlmc","测试教学楼");put("cdxqmc","测试校区")}
                "cultivation"->{put("zymc","测试专业");put("xf","3");put("kcxzmc","必修");put("kkbmmc","测试学院")}
            } }
    } }
    fun choices(feature:QueryFeature):List<QueryChoice> = listOf(
        QueryChoice("xnm","学年",(0..30).map{(year.toInt()-it).toString() to "${year.toInt()-it}–${year.toInt()-it+1}"},year),
        QueryChoice("xqm","学期",listOf("3" to "第一学期","12" to "第二学期"),"3")) +
        if(feature.key=="classrooms")listOf(QueryChoice("lh","教学楼",(1..30).map{"$it" to "测试教学楼 $it"},"1"))else emptyList()
    fun cached(feature:QueryFeature)=CachedQuery(mapOf("xnm" to year,"xqm" to "3"),data.getValue(feature.key),savedAt)
}
