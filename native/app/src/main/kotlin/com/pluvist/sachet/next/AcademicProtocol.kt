package com.pluvist.sachet.next

import org.jsoup.Jsoup
import org.json.JSONObject
import org.json.JSONTokener
import java.net.URI

data class AcademicForm(val choices:List<QueryChoice>,val notices:List<String> = emptyList())
class AcademicFailure(val reason:String,message:String):IllegalStateException(message)

/** The seven ZF modules have distinct forms; DOM names are not a universal API contract. */
object AcademicProtocol {
    fun checkAvailability(html:String) {
        if(!html.trimStart().startsWith('<'))return
        val text=Jsoup.parse(html).text()
        if(listOf("无功能权限","没有功能权限","您没有该功能权限").any{text.contains(it)})
            throw AcademicFailure("permission","教务系统未向当前账号开放此功能（无功能权限）")
        if(text.contains("系统运行异常"))throw AcademicFailure("server-error","教务系统运行异常，请稍后重试")
    }
    fun isLoginPage(html:String):Boolean {
        if(!html.contains("<form",ignoreCase=true))return false
        return Jsoup.parse(html).select("form").any { form ->
            form.select("input#yhm,input[name=yhm]").isNotEmpty() &&
                form.select("input#mm,input[name=mm]").isNotEmpty()
        }
    }
    fun form(feature:String,html:String):AcademicForm {
        checkAvailability(html)
        val doc=Jsoup.parse(html)
        fun choice(id:String,label:String,all:Boolean=false,default:String?=null):QueryChoice {
            val element=doc.getElementById(id) ?: throw AcademicFailure("missing-form","教务系统未返回${label}选项，请重试")
            val options=element.select("option[value]").map{it.attr("value") to it.text().trim()}.filter{it.second.isNotBlank()}.distinctBy{it.first}.toMutableList()
            if(all && options.none{it.first.isBlank()})options.add(0,"" to "全部")
            require(options.isNotEmpty()){ "${label}选项为空" }
            val selected=default ?: element.selectFirst("option[selected]")?.attr("value") ?: options.first().first
            return QueryChoice(id,label,options,selected)
        }
        val choices=when(feature) {
            "grades"->listOf(choice("xnm","学年",true),choice("xqm","学期",true))
            "exams"->listOf(choice("cx_xnm","学年",true),choice("cx_xqm","学期",true))
            "textbooks"->listOf(choice("xnm_cx","学年",true),choice("xqm_cx","学期",true))
            "gpa"->listOf(choice("qsXnxq","起始学期",true,""),choice("zzXnxq","截止学期",true,""),
                QueryChoice("xbx","课程属性",listOf("" to "全部","bx" to "必修","xx" to "选修"),""))
            "cultivation"->listOf(choice("nj_cx","年级",true),choice("jg_id","学院",true),choice("zyh_id_cx","专业",true))
            "classrooms"->listOf(choice("dm_cx","学年学期"),choice("xqh_id","校区"),choice("lh","教学楼",true),choice("cdlb_id","教室类型",true))
            else->error("不支持的教务查询")
        }
        val notices=if(feature=="grades")doc.select(".text-danger").map{it.text().trim()}.filter{it.isNotBlank() && it!="不合格的用红色标识，通过补考或重修及格的用蓝色标识"}.distinct()else emptyList()
        return AcademicForm(choices,notices)
    }
    fun rows(body:String):Pair<List<JSONObject>,Int> {
        checkAvailability(body)
        val root=runCatching{JSONObject(body)}.getOrElse {
            throw AcademicFailure("not-json","教务系统未返回查询数据，请稍后重试")
        }
        val items=root.optJSONArray("items") ?: throw AcademicFailure("missing-items","教务系统未返回记录列表，请稍后重试")
        val rows=(0 until items.length()).map { items.optJSONObject(it) ?: throw AcademicFailure("invalid-row","教务记录格式异常") }
        return rows to listOf("totalResult","totalCount","records").maxOf{root.optInt(it,rows.size)}
    }
    fun transcriptUrl(body:String):String {
        val raw=body.trim()
        val decoded=if(raw.startsWith('"'))runCatching{JSONTokener(raw).nextValue() as String}.getOrElse{raw}else raw
        val path=decoded.substringBefore('#').trim()
        val uri=runCatching{URI("https://jw.xtu.edu.cn").resolve(path)}.getOrElse{throw AcademicFailure("pdf-url","成绩单下载地址无效")}
        require(uri.scheme=="https" && uri.host=="jw.xtu.edu.cn" && uri.port in listOf(-1,443) && uri.rawUserInfo==null &&
            uri.path.startsWith("/jwglxt/templete/scorePrint/") && uri.path.endsWith(".pdf",true) &&
            uri.normalize().path==uri.path && uri.path.split('/').none{it=="."||it==".."} && uri.rawQuery==null) { "成绩单下载地址无效" }
        return uri.toASCIIString()
    }
}
