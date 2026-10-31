package com.pluvist.sachet.next

import org.json.JSONObject
import org.jsoup.Jsoup

data class AcademicRecord(val title:String,val fields:List<Pair<String,String>>)
object AcademicRecords {
    private fun JSONObject.text(key:String)=if(isNull(key))"" else Jsoup.parseBodyFragment(optString(key)).text().trim()
    fun record(feature:String,row:JSONObject):AcademicRecord {
        val fields=when(feature) {
            "grades"->listOf("成绩" to "cj","绩点" to "jd","学分" to "xf","课程性质" to "kcxzmc","任课教师" to "czr","学年" to "xnmmc","学期" to "xqmmc")
            "exams"->listOf("考试时间" to "kssj","地点" to "cdmc","地点简称" to "cdjc","校区" to "cdxqmc","教师" to "jsxx","考试名称" to "ksmc","开课学院" to "kkxy","学年" to "xnmc","学期" to "xqmmc")
            "gpa"->listOf("平均学分绩点" to "pjxfjd","班级排名" to "jdbjpm","年级专业排名" to "jdnjzypm","平均成绩" to "pjcj","年级" to "njmc","学院" to "jgmc","专业" to "zymc","班级" to "bj")
            "textbooks"->listOf("教材名称" to "jcmc","作者" to "jczz","出版社" to "cbs","ISBN" to "isbn","版号" to "bbh","出版日期" to "cbrq","定价" to "price","折后价格" to "discount_price","已预订数" to "yyds","预订状态" to "jcydztmc","缴费状态" to "jfztmc","教师" to "rkjsxx","上课地点" to "jxdd","学年" to "xnmmc","学期" to "xqmmc")
            "cultivation"->listOf("年级" to "njmc","校区" to "xqmc","学制" to "xz","计划学分" to "zdxf","课程数" to "kcs","计划人数" to "jhrs")
            "curriculum"->listOf("课程号" to "kch","学分" to "xf","总学时" to "zxs","课程性质" to "kcxzmc","课程类别" to "kclbmc","建议修读学年" to "jyxdxnm","建议修读学期" to "jyxdxqm","开课学院" to "kkbmmc","考试形式" to "khfsdm","备注" to "bz")
            "classrooms"->listOf("座位数" to "zws","考试座位数" to "kszws1","教学楼" to "jxlmc","场地类别" to "cdlbmc","场地二级类别" to "cdejlbmc")
            else->emptyList()
        }
        val title=when(feature){"gpa"->"学分绩点与排名";"classrooms"->row.text("cdmc");"cultivation"->row.text("zymc");else->row.text("kcmc")}.ifBlank{"查询记录"}
        return AcademicRecord(title,fields.mapNotNull{(label,key)->row.text(key).takeIf{it.isNotBlank()}?.let{label to it}})
    }
    val daySessions=listOf("1-2","3-4","5-6","7-8","9-11")
    fun mergeClassrooms(groups:List<List<JSONObject>>):List<JSONObject> {
        require(groups.size==daySessions.size)
        val rooms=linkedMapOf<String,JSONObject>()
        groups.forEachIndexed{index,rows->rows.forEach{row->
            val name=row.text("cdmc");require(name.isNotBlank()){ "教室名称缺失" }
            val id=row.text("cd_id").ifBlank{name}
            val room=rooms.getOrPut(id){JSONObject(row.toString()).put("_freeSessions","")}
            room.put("_freeSessions",room.optString("_freeSessions")+index.toString())
        }}
        return rooms.values.sortedBy{it.text("cdmc")}
    }
}
