package com.pluvist.sachet.next

import android.content.Context
import android.util.AtomicFile
import android.util.Base64
import com.it_nomads.fluttersecurestorage.FlutterSecureStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.jsoup.Jsoup
import org.json.JSONObject
import org.json.JSONArray
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.math.BigInteger
import java.security.KeyFactory
import java.security.spec.RSAPublicKeySpec
import javax.crypto.Cipher
import java.time.*

class SessionExpired : IllegalStateException("登录状态已过期")
data class Account(val name:String="",val studentID:String="",val cookie:String="",val password:String="") {
    fun json()=JSONObject().put("name",name).put("studentID",studentID).put("cookie",cookie).put("password",password)
}

/** Uses the original MIT secure-storage implementation, without a Flutter engine. */
class AccountStore(context: Context) {
    private val secure = FlutterSecureStorage(context.applicationContext, hashMapOf())
    @Synchronized fun read(): Account {
        fun field(name:String)=secure.read(secure.addPrefixToKey(name)).orEmpty()
        val snapshot=field("sessionZF")
        if(snapshot.isNotBlank()) {
            val obj=JSONObject(snapshot)
            fun text(k:String)=if(obj.isNull(k)) "" else obj.optString(k)
            return Account(text("name"),text("studentID"),text("cookie"),text("password"))
        }
        return Account(field("nameZF"),field("studentIDZF"),field("cookieZF"),field("passwordZF"))
    }
    @Synchronized fun save(value:Account) { secure.write(secure.addPrefixToKey("sessionZF"),value.json().toString()) }
    @Synchronized fun logout() { save(Account()); listOf("nameZF","studentIDZF","cookieZF","passwordZF").forEach { secure.delete(secure.addPrefixToKey(it)) } }
}

data class HttpResult(val status:Int,val body:String,val headers:Map<String?,List<String>>)
class AcademicHttp {
    private fun referer(path:String):String {
        val feature=QueryFeature.all.firstOrNull{path.substringBefore('/').let{prefix->it.index.startsWith("$prefix/")}}
        return feature?.index ?: if(path.startsWith("bysxxcx/"))"bysxxcx/xscjzbdy_cxXscjzbdyIndex.html?gnmkdm=N558020&layout=default" else "xtgl/index_initMenu.html"
    }
    companion object { const val BASE="https://jw.xtu.edu.cn/jwglxt/" }
    fun request(path:String,cookie:String="",form:Map<String,String>?=null,timeoutMillis:Int=30_000):HttpResult {
        val url=URL(BASE+path)
        val connection=(url.openConnection() as HttpURLConnection).apply {
            instanceFollowRedirects=false; connectTimeout=10_000; readTimeout=timeoutMillis; useCaches=false
            setRequestProperty("Cookie",cookie); setRequestProperty("User-Agent","Mozilla/5.0 Firefox/140.0")
            setRequestProperty("Referer",BASE+referer(path))
            setRequestProperty("Origin","https://jw.xtu.edu.cn")
            setRequestProperty("Accept",if(form==null) "text/html,application/json;q=0.9,*/*;q=0.8" else "application/json, text/javascript, */*; q=0.01")
            if(form!=null) {
                requestMethod="POST"; doOutput=true
                setRequestProperty("Content-Type","application/x-www-form-urlencoded;charset=utf-8")
                setRequestProperty("X-Requested-With","XMLHttpRequest")
                outputStream.use { stream -> stream.write(form.entries.joinToString("&") { (k,v)-> "${URLEncoder.encode(k,"UTF-8")}=${URLEncoder.encode(v,"UTF-8")}" }.toByteArray()) }
            }
        }
        try {
            val code=connection.responseCode
            val body=(if(code>=400) connection.errorStream else connection.inputStream)?.bufferedReader()?.use{it.readText()}.orEmpty()
            AcademicDiagnostics.observe(path,code,body)
            return HttpResult(code,body,connection.headerFields)
        } finally { connection.disconnect() }
    }
    fun authenticated(path:String,cookie:String,form:Map<String,String>?=null,timeoutMillis:Int=30_000):String {
        val response=request(path,cookie,form,timeoutMillis)
        if(response.status in listOf(301,302,303,307,308,401,901) || AcademicProtocol.isLoginPage(response.body)) throw SessionExpired()
        check(response.status==200) { "教务系统请求失败（${response.status}）" }
        AcademicProtocol.checkAvailability(response.body)
        return response.body
    }
    fun verifyProfile(cookie:String):Account {
        val jar=linkedMapOf<String,String>()
        cookie.split(';').forEach{part->val pair=part.trim().split('=',limit=2);if(pair.size==2)jar[pair[0]]=pair[1]}
        var path="xtgl/index_cxYhxxIndex.html?xt=jw&localeKey=zh_CN&gnmkdm=index"
        repeat(6){
            val response=request(path,jar.entries.joinToString("; "){"${it.key}=${it.value}"})
            response.headers.filterKeys{it.equals("Set-Cookie",true)}.values.flatten().forEach{line->
                val pair=line.substringBefore(';').split('=',limit=2)
                if(pair.size==2&&pair[0] in setOf("JSESSIONID","route"))jar[pair[0]]=pair[1]
            }
            if(response.status in listOf(301,302,303,307,308)) {
                val location=response.headers.entries.firstOrNull{it.key.equals("Location",true)}?.value?.firstOrNull()?:error("教务跳转地址为空")
                val target=URL(URL(BASE+path),location)
                require(target.protocol=="https"&&target.host=="jw.xtu.edu.cn"&&target.port in listOf(-1,443)&&target.userInfo==null&&target.path.startsWith("/jwglxt/")){"教务跳转地址无效"}
                if(target.path.contains("login",true))throw SessionExpired()
                path=target.toString().removePrefix(BASE)
            } else {
                check(response.status==200){"验证登录失败（${response.status}）"}
                val document=Jsoup.parse(response.body)
                if(document.select("input#yhm,input[name=yhm]").isNotEmpty())throw SessionExpired()
                val name=document.selectFirst(".media-heading")?.text()?.substringBefore(' ').orEmpty()
                check(name.isNotBlank()){ "未能确认教务登录状态" }
                return Account(name=name,cookie=jar.entries.joinToString("; "){"${it.key}=${it.value}"})
            }
        }
        error("验证登录跳转次数过多")
    }
    fun login(username:String,password:String):Account {
        val jar=linkedMapOf<String,String>()
        fun cookie()=jar.entries.joinToString("; "){"${it.key}=${it.value}"}
        fun send(path:String,form:Map<String,String>?=null):HttpResult {
            val response=request(path,cookie(),form)
            response.headers.filterKeys { it.equals("Set-Cookie",true) }.values.flatten().forEach {
                val pair=it.substringBefore(';').split('=',limit=2)
                if(pair.size==2 && pair[0] in setOf("JSESSIONID","route")) jar[pair[0]]=pair[1]
            }
            return response
        }
        var response=send("xtgl/login_slogin.html")
        repeat(6) {
            if(response.status in listOf(301,302,303,307,308)) {
                val location=response.headers.entries.firstOrNull { it.key.equals("Location",true) }?.value?.firstOrNull() ?: error("登录跳转地址为空")
                val target=URL(URL(BASE),location)
                require(target.protocol=="https" && target.host=="jw.xtu.edu.cn" && target.path.startsWith("/jwglxt/")) { "教务系统跳转地址无效" }
                response=send(target.toString().removePrefix(BASE))
            }
        }
        check(response.status==200) { "无法打开登录页" }
        val token=Jsoup.parse(response.body).getElementById("csrftoken")?.attr("value") ?: error("未读取到登录令牌")
        val publicKey=JSONObject(send("xtgl/login_getPublicKey.html?time=${System.currentTimeMillis()}").body)
        val key=KeyFactory.getInstance("RSA").generatePublic(RSAPublicKeySpec(
            BigInteger(1,Base64.decode(publicKey.getString("modulus"),Base64.DEFAULT)),
            BigInteger(1,Base64.decode(publicKey.getString("exponent"),Base64.DEFAULT))))
        val cipher=Cipher.getInstance("RSA/ECB/PKCS1Padding").apply { init(Cipher.ENCRYPT_MODE,key) }
        val encoded=Base64.encodeToString(cipher.doFinal(password.toByteArray()),Base64.NO_WRAP)
        val result=send("xtgl/login_slogin.html",mapOf("csrftoken" to token,"yhm" to username,"mm" to encoded))
        val error=Jsoup.parse(result.body).getElementById("tips")?.text().orEmpty()
        check(error.isBlank()) { error }
        check(jar["JSESSIONID"].orEmpty().isNotBlank()){ "未能保留教务会话" }
        return verifyProfile(cookie()).copy(studentID=username,password=password)
    }
}

data class QueryFeature(val key:String,val title:String,val index:String,val query:String) {
    companion object {
        val all=listOf(
            QueryFeature("grades","成绩查询","cjcx/cjcx_cxDgXscj.html?gnmkdm=N305005&layout=default","cjcx/cjcx_cxXsgrcj.html?doType=query&gnmkdm=N305005"),
            QueryFeature("exams","考试时间","kwgl/kscx_cxXsksxxIndex.html?gnmkdm=N358105&layout=default","kwgl/kscx_cxXsksxxIndex.html?doType=query&gnmkdm=N358105"),
            QueryFeature("gpa","绩点排名","cjpmtj/cjpmtj_cxPjxfjdpmtjIndex.html?gnmkdm=N309104&layout=default","cjpmtj/cjpmtj_cxPjxfjdpmtjIndex.html?doType=query&gnmkdm=N309104"),
            QueryFeature("textbooks","教材预订","jcydgl/xsjcyd_cxXsjcydIndex.html?gnmkdm=N253545&layout=default","jcydgl/xsjcyd_cxXsjcydIndex.html?gnmkdm=N253545"),
            QueryFeature("classrooms","空闲教室","cdjy/cdjy_cxKxcdlb.html?gnmkdm=N2155&layout=default","cdjy/cdjy_cxKxcdlb.html?doType=query&gnmkdm=N2155"),
            QueryFeature("cultivation","培养方案","jxzxjhgl/jxzxjhck_cxJxzxjhckIndex.html?gnmkdm=N153540&layout=default","jxzxjhgl/jxzxjhck_cxJxzxjhckIndex.html?doType=query&gnmkdm=N153540"))
    }
}
data class QueryChoice(val key:String,val label:String,val values:List<Pair<String,String>>,val selected:String)
data class CachedQuery(val parameters:Map<String,String>,val rows:List<JSONObject>,val savedAt:Long)
data class ManagedDataFile(val path:String,val name:String,val kind:String,val bytes:Long)

class AcademicRepository(private val context:Context) {
    @Volatile private var uiBenchmark:AcademicUiBenchmark?=null
    internal fun installUiBenchmark() {
        check(BuildConfig.APPLICATION_ID.endsWith(".benchmark"))
        uiBenchmark=AcademicUiBenchmark(context)
    }
    val accounts=AccountStore(context)
    private val http=AcademicHttp()
    private val sessionLock=Mutex()
    private val refreshLock=Mutex()
    private val prefs=context.getSharedPreferences("FlutterSharedPreferences",Context.MODE_PRIVATE)
    fun settings()=JSONObject(prefs.getString("flutter.appSettings","{}")?:"{}")
    fun appearance()=JSONObject(prefs.getString("flutter.courseCardSettings","{}")?:"{}")
    fun saveAppearance(value:JSONObject){check(prefs.edit().putString("flutter.courseCardSettings",value.toString()).commit()){ "保存课表外观失败" }}
    suspend fun colors():Map<String,String> = withContext(Dispatchers.IO) {
        val path=settings().optString("courseColorFilePath")
        if(path.isBlank())return@withContext emptyMap()
        val file=File(path).canonicalFile
        require(file.toPath().startsWith(context.filesDir.canonicalFile.toPath())) { "配色文件路径无效" }
        if(!file.isFile)return@withContext emptyMap()
        val objectValue=JSONObject(file.readText())
        objectValue.keys().asSequence().associateWith{objectValue.getString(it)}
    }
    suspend fun importColors(body:String):Map<String,String> = withContext(Dispatchers.IO) {
        val value=JSONObject(body)
        value.keys().forEach{android.graphics.Color.parseColor(value.getString(it))}
        val file=AtomicFile(File(context.filesDir,"native-colors.json"));val output=file.startWrite()
        try{output.write(body.toByteArray());file.finishWrite(output)}catch(e:Throwable){file.failWrite(output);throw e}
        val settings=settings().put("courseColorFilePath",file.baseFile.path)
        check(prefs.edit().putString("flutter.appSettings",settings.toString()).commit()) { "保存配色失败" }
        colors()
    }
    fun hasSchedule()=File(context.filesDir,"native-schedule.json").exists() || settings().optString("classScheduleFilePath").takeIf{it.isNotBlank()}?.let{File(it).isFile}==true
    private suspend fun <T> authorized(action:(Account)->T):T = withContext(Dispatchers.IO) {
        val account=accounts.read()
        require(account.cookie.isNotBlank() || account.password.isNotBlank()) { "请先登录教务账号" }
        try { action(account) } catch(expired:SessionExpired) {
            val renewed=sessionLock.withLock {
                val latest=accounts.read()
                check(latest.studentID==account.studentID) { "账号已切换，请重试" }
                if(latest.cookie!=account.cookie && latest.cookie.isNotBlank()) latest else {
                    require(latest.studentID.isNotBlank() && latest.password.isNotBlank()) { "登录已过期，请重新登录" }
                    http.login(latest.studentID,latest.password).also(accounts::save)
                }
            }
            action(renewed)
        }
    }
    suspend fun login(id:String,password:String,remember:Boolean)=withContext(Dispatchers.IO) {
        sessionLock.withLock { http.login(id.trim(),password).copy(password=if(remember) password else "").also(accounts::save) }
    }
    suspend fun cookieLogin(cookie:String)=withContext(Dispatchers.IO) {
        sessionLock.withLock {
            http.verifyProfile(cookie).also(accounts::save)
        }
    }
    suspend fun form(feature:QueryFeature):AcademicForm = uiBenchmark?.choices(feature)?.let{AcademicForm(it)} ?: authorized { account ->
        AcademicProtocol.form(feature.key,http.authenticated(feature.index,account.cookie))
    }
    suspend fun choices(feature:QueryFeature)=form(feature).choices
    private fun fetchRows(path:String,account:Account,data:Map<String,String>,timeout:Int=30_000):List<JSONObject> {
        val result=mutableListOf<JSONObject>()
        var page=1
        do {
            val (rows,total)=AcademicProtocol.rows(http.authenticated(path,account.cookie,data+("queryModel.currentPage" to page.toString()),timeout))
            result.addAll(rows)
            if(rows.isEmpty() || result.size>=total)break
            page++
            check(page<=100){ "记录数量过多，请缩小查询范围" }
        }while(true)
        return result
    }
    suspend fun query(feature:QueryFeature,parameters:Map<String,String>):List<JSONObject> = uiBenchmark?.cached(feature)?.rows ?: authorized { account ->
        val data=AcademicRequests.parameters(feature.key,parameters)
        val result=if(feature.key=="classrooms" && parameters["view"]=="day") {
            AcademicRecords.mergeClassrooms(AcademicRecords.daySessions.map{sessions->
                fetchRows(feature.query,account,AcademicRequests.parameters(feature.key,parameters+("sessions" to sessions)))
            })
        }else fetchRows(feature.query,account,data,if(feature.key=="gpa")600_000 else 30_000)
        check(accounts.read().studentID==account.studentID) { "账号已变更，未保存旧账号的查询结果" }
        val cached=JSONObject().put("parameters",JSONObject(parameters)).put("rows",JSONArray(result)).put("savedAt",System.currentTimeMillis())
        val file=AtomicFile(queryCache(feature,account));file.baseFile.parentFile?.mkdirs();val output=file.startWrite()
        try{output.write(cached.toString().toByteArray());file.finishWrite(output)}catch(e:Throwable){file.failWrite(output);throw e}
        result
    }
    suspend fun teachingBuildings(semester:String,campus:String="02"):List<Pair<String,String>> = authorized { account ->
        val parts=semester.split('-');require(parts.size==2){ "请选择学年学期" }
        val body=http.authenticated("cdjy/cdjy_cxXqjc.html?xqh_id=${URLEncoder.encode(campus,"UTF-8")}&xnm=${URLEncoder.encode(parts[0],"UTF-8")}&xqm=${URLEncoder.encode(parts[1],"UTF-8")}&gnmkdm=N2155",account.cookie)
        val rows=JSONObject(body).getJSONArray("lhList")
        listOf("" to "全部")+(0 until rows.length()).map{val row=rows.getJSONObject(it);row.getString("JXLDM") to row.getString("JXLMC")}
    }
    private fun queryCache(feature:QueryFeature,account:Account):File {
        val identity=account.studentID.ifBlank{account.cookie}
        val hash=java.security.MessageDigest.getInstance("SHA-256").digest(identity.toByteArray()).take(12).joinToString(""){"%02x".format(it)}
        return File(context.filesDir,"native-query-cache/$hash/${feature.key}.json")
    }
    suspend fun cachedQuery(feature:QueryFeature):CachedQuery? = withContext(Dispatchers.IO) {
        uiBenchmark?.let{return@withContext it.cached(feature)}
        val account=accounts.read()
        if(account.cookie.isBlank()&&account.password.isBlank())return@withContext null
        val file=AtomicFile(queryCache(feature,account));if(!file.baseFile.isFile)return@withContext null
        val root=JSONObject(String(file.readFully()));val rows=root.getJSONArray("rows");val parameters=root.getJSONObject("parameters")
        CachedQuery(parameters.keys().asSequence().associateWith{parameters.getString(it)},(0 until rows.length()).map{rows.getJSONObject(it)},root.optLong("savedAt"))
    }
    suspend fun refresh():List<Course> = refreshLock.withLock { authorized { account ->
        val html=http.authenticated("kbcx/xskbcx_cxXskbcxIndex.html?gnmkdm=N2151",account.cookie)
        val document=Jsoup.parse(html)
        fun selected(id:String)=document.selectFirst("select#$id option[selected]")?.attr("value") ?: document.selectFirst("select#$id option")?.attr("value") ?: error("无法读取当前学期")
        val body=http.authenticated("kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N2151",account.cookie,mapOf("xnm" to selected("xnm"),"xqm" to selected("xqm"),"kzlx" to "ck","xsdm" to "","kclbdm" to ""))
        val parsed=applyRoutines(CourseParser.fromServer(body))
        check(accounts.read().cookie==account.cookie) { "账号已变更，未保存旧账号的课表" }
        val calendar=runCatching{http.authenticated("xtgl/index_cxAreaFive.html?localeKey=zh_CN&gnmkdm=index",account.cookie)}.getOrNull()
        calendar?.let {
            Regex("学期[（(](\\d{4}-\\d{2}-\\d{2})至").find(Jsoup.parse(it).text())?.groupValues?.get(1)?.let { date ->
                val settings=settings().put("semesterStartDate",date)
                check(prefs.edit().putString("flutter.appSettings",settings.toString()).commit()) { "保存学期日期失败" }
            }
        }
        val file=AtomicFile(File(context.filesDir,"native-schedule.json"))
        val output=file.startWrite()
        try { output.write(body.toByteArray()); file.finishWrite(output) } catch(error:Throwable) { file.failWrite(output); throw error }
        publish(parsed)
        parsed
    } }
    suspend fun cached():List<Course> = withContext(Dispatchers.IO) {
        val file=AtomicFile(File(context.filesDir,"native-schedule.json"))
        if(file.baseFile.exists()) applyRoutines(CourseParser.fromServer(String(file.readFully()))) else {
            val path=settings().optString("classScheduleFilePath")
            if(path.isBlank()) emptyList() else {
                val legacy=File(path).canonicalFile
                require(legacy.toPath().startsWith(context.filesDir.canonicalFile.toPath())) { "原课表路径无效" }
                if(legacy.isFile)applyRoutines(CourseParser.fromLegacy(legacy.readText()))else emptyList()
            }
        }
    }
    private fun routineKey(course:Course)=JSONArray(listOf((course.weekday-1)*5+(course.first-1)/2,course.title,course.teacher,course.place,course.last-course.first+1)).toString()
    private fun applyRoutines(courses:List<Course>):List<Course> {
        val overrides=settings().optJSONObject("courseRoutineOverrides")?:JSONObject()
        return courses.map{it.copy(routine=overrides.optString(routineKey(it),"auto"))}
    }
    suspend fun setRoutine(course:Course,routine:String):List<Course> = withContext(Dispatchers.IO) {
        require(routine in setOf("auto","normal","staggered"))
        val settings=settings();val overrides=settings.optJSONObject("courseRoutineOverrides")?:JSONObject()
        if(routine=="auto")overrides.remove(routineKey(course))else overrides.put(routineKey(course),routine)
        settings.put("courseRoutineOverrides",overrides)
        check(prefs.edit().putString("flutter.appSettings",settings.toString()).commit()) { "保存作息失败" }
        cached().also{publish(it)}
    }
    suspend fun logout()=withContext(Dispatchers.IO){sessionLock.withLock{accounts.logout()}}
    suspend fun setSetting(key:String,value:Any)=withContext(Dispatchers.IO) {
        if(key=="semesterStartDate") require(LocalDate.parse(value.toString()).dayOfWeek==DayOfWeek.MONDAY) { "学期开始日期应为周一" }
        val updated=settings().put(key,value)
        check(prefs.edit().putString("flutter.appSettings",updated.toString()).commit()) { "保存设置失败" }
    }
    suspend fun importSchedule(body:String):List<Course> = withContext(Dispatchers.IO) {
        val courses=if(body.trimStart().startsWith("[")) CourseParser.fromLegacy(body) else CourseParser.fromServer(body)
        val rows=JSONArray()
        courses.forEach{row->rows.put(JSONObject().put("jxb_id",row.id).put("kcmc",row.title).put("cdmc",row.place).put("xm",row.teacher)
            .put("xqj",row.weekday.toString()).put("jc","${row.first}-${row.last}节").put("zcd",row.weeks.sorted().joinToString(",")))}
        val atomic=AtomicFile(File(context.filesDir,"native-schedule.json"));val stream=atomic.startWrite()
        try{stream.write(JSONObject().put("kbList",rows).toString().toByteArray());atomic.finishWrite(stream)}catch(e:Throwable){atomic.failWrite(stream);throw e}
        publish(courses);courses
    }
    suspend fun transcriptTypes():List<Pair<String,String>> = authorized { account ->
        val html=http.authenticated("bysxxcx/xscjzbdy_dyXscjzbView.html?dyly=dy&time=${System.currentTimeMillis()}&gnmkdm=N558020",account.cookie,
            listOf("jg_id","zyh_id","bh_id","njdm_id").associate{"mapper[$it]" to it})
        Jsoup.parse(html).select("select#gsdygx option").map{it.attr("value") to it.text()}.filter{it.first.isNotBlank()&&it.second.isNotBlank()}.also{require(it.isNotEmpty()){ "未读取到成绩单格式" }}
    }
    suspend fun transcript(type:String):File = authorized { account ->
        require(type.isNotBlank()) { "请选择成绩单格式" }
        val params=listOf("ids","bdykcxzDms","cytjkcxzDms","cytjkclbDms","cytjkcgsDms","bjgbdykcxzDms","bjgbdyxxkcxzDms","djksxmDms","cjbzmcDms","zdyfsxmDms","bdymaxcjbzmcDms","cjdySzxs").associateWith{""}+mapOf("gsdygx" to type,"wjlx" to "pdf")
        val rawLink=http.authenticated("bysxxcx/xscjzbdy_dyList.html?gnmkdm=N558020",account.cookie,params)
        val connection=URL(AcademicProtocol.transcriptUrl(rawLink)).openConnection() as HttpURLConnection
        connection.instanceFollowRedirects=false;connection.connectTimeout=10_000;connection.readTimeout=30_000
        connection.setRequestProperty("Cookie",account.cookie)
        connection.setRequestProperty("Referer",AcademicHttp.BASE)
        try {
            if(connection.responseCode in listOf(302,901))throw SessionExpired()
            check(connection.responseCode==200) { "成绩单下载失败" }
            val bytes=connection.inputStream.use{it.readBytes()}
            if(!bytes.take(5).toByteArray().contentEquals("%PDF-".toByteArray())) {
                if(String(bytes.take(2048).toByteArray()).contains("yhm"))throw SessionExpired()
                error("教务返回的文件不是 PDF")
            }
            File(context.cacheDir,"sachet-transcript.pdf").apply{writeBytes(bytes)}
        } finally{connection.disconnect()}
    }
    suspend fun curriculum(majorId:String):List<JSONObject> = authorized { account ->
        fetchRows("jxzxjhgl/jxzxjhkcxx_cxJxzxjhkcxxIndex.html?doType=query&gnmkdm=N153540",account,
            AcademicRequests.parameters("curriculum",mapOf("jxzxjhxx_id" to majorId)))
    }
    suspend fun schoolMajors(school:String):List<Pair<String,String>> = authorized { account ->
        val body=http.authenticated("xtgl/comm_cxZydmList.html?jg_id=${URLEncoder.encode(school,"UTF-8")}&_=${System.currentTimeMillis()}&gnmkdm=N153540",account.cookie)
        val items=JSONArray(body)
        (0 until items.length()).map{val row=items.getJSONObject(it);row.optString("zyh_id") to row.optString("zymc")}
    }
    suspend fun managedFiles():List<ManagedDataFile> = withContext(Dispatchers.IO) {
        val folders=mapOf("class_schedule" to "schedule","course_color" to "colors","cached_data" to "cache","cached_data_zf" to "cache","native-query-cache" to "cache")
        val files=folders.flatMap{(folder,kind)->
            File(context.filesDir,folder).walkTopDown().maxDepth(4).filter{it.isFile&&it.extension=="json"}.map{ManagedDataFile(it.canonicalPath,it.name,kind,it.length())}.toList()
        }.toMutableList()
        listOf("native-schedule.json" to "schedule","native-colors.json" to "colors").forEach{(name,kind)->
            val file=File(context.filesDir,name);if(file.isFile)files+=ManagedDataFile(file.canonicalPath,name,kind,file.length())
        }
        files.sortedBy{it.name}
    }
    private fun managedFile(value:ManagedDataFile):File {
        val file=File(value.path).canonicalFile
        val allowed=listOf("class_schedule","course_color","cached_data","cached_data_zf","native-query-cache").any{file.toPath().startsWith(File(context.filesDir,it).canonicalFile.toPath())} ||
            file in listOf(File(context.filesDir,"native-schedule.json").canonicalFile,File(context.filesDir,"native-colors.json").canonicalFile)
        require(allowed){"只能访问课程与查询数据文件"};return file
    }
    suspend fun readManagedFile(value:ManagedDataFile)=withContext(Dispatchers.IO){managedFile(value).readText()}
    suspend fun deleteManagedFile(value:ManagedDataFile)=withContext(Dispatchers.IO){check(managedFile(value).delete()){ "删除文件失败" }}
    suspend fun writeManagedFile(value:ManagedDataFile,body:String)=withContext(Dispatchers.IO){
        when(value.kind){
            "schedule"->if(body.trimStart().startsWith("["))CourseParser.fromLegacy(body)else CourseParser.fromServer(body)
            "colors"->{val json=JSONObject(body);json.keys().forEach{android.graphics.Color.parseColor(json.getString(it))}}
            else->org.json.JSONTokener(body).nextValue().also{require(it is JSONObject||it is JSONArray){"请输入有效的 JSON 数据"}}
        }
        val file=AtomicFile(managedFile(value));val output=file.startWrite()
        try{output.write(body.toByteArray());file.finishWrite(output)}catch(e:Throwable){file.failWrite(output);throw e}
    }
    fun semester():LocalDate=settings().optString("semesterStartDate").take(10).let {
        runCatching{LocalDate.parse(it)}.getOrElse{LocalDate.now().with(java.time.DayOfWeek.MONDAY)}
    }
    suspend fun republish(courses:List<Course>)=withContext(Dispatchers.IO){publish(courses)}
    private fun publish(courses:List<Course>) {
        val data=JSONObject().put("ready",hasSchedule()).put("semester",semester().toString()).put("themeMode",settings().optInt("themeMode",0)).put("liveActivityEnabled",settings().optBoolean("isEnableCourseLiveActivity",true))
        val lessons=JSONArray(); val zone=ZoneId.systemDefault(); val first=LocalDate.now().minusDays(1)
        for(day in 0..60) CourseClock.onDate(courses,semester(),first.plusDays(day.toLong()),zone).forEach {
            lessons.put(JSONObject().put("title",it.course.title).put("place",it.course.place).put("start",it.start.toEpochMilli()).put("end",it.end.toEpochMilli()))
        }
        data.put("lessons",lessons)
        check(context.getSharedPreferences("course_widget",Context.MODE_PRIVATE).edit().putString("data",data.toString()).commit()) { "无法保存课程状态" }
        CourseWidgetProvider.refresh(context); CourseLiveActivity.refresh(context)
    }
}
