package com.pluvist.sachet.next
import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

data class AppData(val courses:List<Course> = emptyList(),val account:Account=Account(),val loading:Boolean=true,val message:String?=null,val settingsSnapshot:String="{}",val appearanceSnapshot:String="{}",val hasSchedule:Boolean=false,val colors:Map<String,String> = emptyMap(),val reloadRevision:Int=0,val reloadFromClick:Boolean=false)
class SachetViewModel(app:Application):AndroidViewModel(app) {
    val repository=AcademicRepository(app)
    private val mutable=MutableStateFlow(AppData())
    val state=mutable.asStateFlow()
    init { launch {
        val cached=repository.cached()
        val account=withContext(Dispatchers.IO){repository.accounts.read()}
        mutable.value=AppData(cached,account,false,settingsSnapshot=repository.settings().toString(),appearanceSnapshot=repository.appearance().toString(),hasSchedule=repository.hasSchedule(),colors=repository.colors())
        if(account.cookie.isNotBlank() || account.password.isNotBlank()) refresh()
    } }
    private fun launch(block:suspend ()->Unit) = viewModelScope.launch {
        try{block()}catch(error:CancellationException){throw error}catch(error:Exception){mutable.update{it.copy(loading=false,message=error.message?:"操作失败")}}
    }
    fun dismissMessage(){mutable.update{it.copy(message=null)}}
    fun refresh(fromClick:Boolean=false) = launch {
        if(mutable.value.loading) return@launch
        mutable.update{it.copy(loading=true,message=null,reloadFromClick=fromClick)}
        try {
            val courses=repository.refresh()
            val account=withContext(Dispatchers.IO){repository.accounts.read()}
            mutable.update{it.copy(courses=courses,account=account,hasSchedule=true,settingsSnapshot=repository.settings().toString())}
        }finally{mutable.update{it.copy(loading=false,reloadRevision=it.reloadRevision+1,reloadFromClick=false)}}
    }
    fun login(id:String,password:String,remember:Boolean,onDone:()->Unit) = launch {
        mutable.update{it.copy(loading=true,message=null)}
        val account=repository.login(id,password,remember)
        mutable.update{it.copy(account=account,loading=false)}
        onDone(); refresh()
    }
    fun logout()=launch {
        repository.logout()
        mutable.update{it.copy(account=Account())}
    }
    fun cookieLogin(cookie:String,onDone:()->Unit)=launch {
        mutable.update{it.copy(loading=true,message=null)}
        val account=repository.cookieLogin(cookie)
        mutable.update{it.copy(account=account,loading=false)};onDone();refresh()
    }
    fun importSchedule(body:String)=launch {
        val courses=repository.importSchedule(body)
        mutable.update{it.copy(courses=courses,hasSchedule=true,reloadRevision=it.reloadRevision+1)}
    }
    suspend fun saveSettings(values:Map<String,Any>) {
        values.forEach{(key,value)->repository.setSetting(key,value)}
        repository.republish(mutable.value.courses)
        mutable.update{it.copy(settingsSnapshot=repository.settings().toString())}
    }
    suspend fun saveAppearance(json:org.json.JSONObject) {
        withContext(Dispatchers.IO){repository.saveAppearance(json)}
        mutable.update{it.copy(appearanceSnapshot=json.toString())}
    }
    fun setRoutine(course:Course,routine:String)=launch {
        val courses=repository.setRoutine(course,routine)
        mutable.update{it.copy(courses=courses,settingsSnapshot=repository.settings().toString())}
    }
    fun setCardHeight(height:Float)=launch { saveAppearance(repository.appearance().put("cardHeight",height.toDouble())) }
    fun importColors(body:String)=launch { val colors=repository.importColors(body);mutable.update{it.copy(colors=colors,reloadRevision=it.reloadRevision+1)} }
    fun reloadLocal()=launch {
        val courses=repository.cached();val colors=repository.colors()
        repository.republish(courses)
        mutable.update{it.copy(courses=courses,colors=colors,hasSchedule=repository.hasSchedule(),reloadRevision=it.reloadRevision+1)}
    }
    fun loadBenchmarkFixture()=launch {
        if(!BuildConfig.APPLICATION_ID.endsWith(".benchmark"))return@launch
        state.first{!it.loading}
        withContext(Dispatchers.IO){repository.installUiBenchmark()}
        repository.setSetting("semesterStartDate",java.time.LocalDate.now().with(java.time.DayOfWeek.MONDAY).toString())
        repository.setSetting("hasReadDisclaimer",true)
        repository.setSetting("isEnableCourseLiveActivity",false)
        val body=withContext(Dispatchers.IO){getApplication<Application>().assets.open("benchmark-schedule.json").bufferedReader().use{it.readText()}}
        val courses=repository.importSchedule(body)
        mutable.update{it.copy(courses=courses,hasSchedule=true,settingsSnapshot=repository.settings().toString())}
    }
}
