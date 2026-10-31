package com.pluvist.sachet.next

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.time.LocalDate

/** Explicit opt-in on the local preview only. Never records account values or response contents. */
internal object AcademicDiagnostics {
    @Volatile private var active=false
    private fun log(message:String) { Log.i("AcademicProbe",message) }
    fun observe(path:String,status:Int,body:String) {
        if(!active || BuildConfig.BUILD_TYPE!="preview")return
        val json=runCatching{JSONObject(body)}.getOrNull()
        val permission=runCatching{AcademicProtocol.checkAvailability(body)}.exceptionOrNull() as? AcademicFailure
        log("response endpoint=${path.substringBefore('?')} status=$status json=${json!=null} items=${json?.optJSONArray("items")?.length() ?: -1} login=${AcademicProtocol.isLoginPage(body)} failure=${permission?.reason.orEmpty()}")
    }

    suspend fun run(repository:AcademicRepository)=withContext(Dispatchers.IO) {
        if(BuildConfig.BUILD_TYPE!="preview" || active)return@withContext
        active=true
        try {
            val account=repository.accounts.read()
            log("start cookie=${account.cookie.isNotBlank()} password=${account.password.isNotBlank()}")
            for(feature in QueryFeature.all) {
                try {
                    val choices=repository.choices(feature)
                    log("${feature.key} choices=${choices.joinToString(","){it.key+":"+it.values.size}}")
                    val values=choices.associate{it.key to it.selected}.toMutableMap()
                    if(feature.key=="classrooms")values.putAll(mapOf("weeks" to CourseClock.week(LocalDate.now(),repository.semester()).coerceIn(1,60).toString(),"weekdays" to LocalDate.now().dayOfWeek.value.toString(),"sessions" to "1-2"))
                    val rows=repository.query(feature,values)
                    log("${feature.key} ok rows=${rows.size}")
                    if(feature.key in listOf("grades","exams") && rows.isEmpty()) {
                        val all=values.toMutableMap();choices.filter{it.key.contains("xnm")||it.key.contains("xqm")}.forEach{all[it.key]=""}
                        log("${feature.key} all-semesters rows=${repository.query(feature,all).size}")
                    }
                    if(feature.key=="classrooms") {
                        log("buildings ok count=${repository.teachingBuildings(values["dm_cx"].orEmpty()).size}")
                        log("classrooms day rows=${repository.query(feature,values+("view" to "day")).size}")
                    }
                    if(feature.key=="cultivation" && rows.isNotEmpty()) {
                        val id=rows.first().optString("jxzxjhxx_id")
                        if(id.isNotBlank())log("curriculum ok rows=${repository.curriculum(id).size}")
                    }
                }catch(e:Exception){log("${feature.key} failed reason=${(e as? AcademicFailure)?.reason ?: if(e is SessionExpired)"session" else e.javaClass.simpleName}")}
            }
            try {
                val types=repository.transcriptTypes();log("transcript types=${types.size}")
                if(types.isNotEmpty())log("transcript ok pdf=${repository.transcript(types.first().first).length()>5}")
            }catch(e:Exception){log("transcript failed reason=${(e as? AcademicFailure)?.reason ?: if(e is SessionExpired)"session" else e.javaClass.simpleName}")}
            log("done")
        }finally{active=false}
    }
}
