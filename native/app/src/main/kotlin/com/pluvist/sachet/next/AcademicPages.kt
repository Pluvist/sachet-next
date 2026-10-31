package com.pluvist.sachet.next

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.material3.Text
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.scaffold.*
import io.github.neoruaa.glasmio.ui.*
import kotlinx.coroutines.*
import org.json.JSONObject
import java.time.LocalDate

@Composable internal fun QueryPage(feature:QueryFeature,repository:AcademicRepository,back:()->Unit) {
    var form by remember(feature){mutableStateOf<AcademicForm?>(null)}
    val values=remember(feature){mutableStateMapOf<String,String>()}
    var rows by remember(feature){mutableStateOf<List<JSONObject>?>(null)}
    var curriculum by remember(feature){mutableStateOf<List<JSONObject>?>(null)}
    var curriculumTitle by remember(feature){mutableStateOf("")}
    var loading by remember(feature){mutableStateOf(true)}
    var loadingForm by remember(feature){mutableStateOf(true)}
    var formReloads by remember(feature){mutableIntStateOf(0)}
    var loadingChoices by remember(feature){mutableStateOf(false)}
    var error by remember(feature){mutableStateOf<String?>(null)}
    var cachedAt by remember(feature){mutableStateOf<Long?>(null)}
    var picker by remember(feature){mutableStateOf<String?>(null)}
    var reload by remember(feature){mutableIntStateOf(0)}
    var completedReloads by remember(feature){mutableIntStateOf(0)}
    var dependencyError by remember(feature){mutableStateOf(false)}
    var dateText by remember(feature){mutableStateOf(LocalDate.now().toString())}
    val scope=rememberCoroutineScope()
    val context=LocalContext.current
    val close:()->Unit={if(curriculum!=null){curriculum=null;error=null}else back()}
    BackHandler(curriculum!=null){close()}
    val exporter=androidx.activity.compose.rememberLauncherForActivityResult(androidx.activity.result.contract.ActivityResultContracts.CreateDocument("text/calendar")){uri->uri?.let{scope.launch{
        try{withContext(Dispatchers.IO){
            context.contentResolver.openOutputStream(uri)?.bufferedWriter()?.use{it.write(CalendarExport.exams(rows.orEmpty()))}?:error("无法写入日历文件")
        }}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}
    }}}
    fun query() { scope.launch {
        if(loading || loadingChoices)return@launch
        loading=true;error=null;curriculum=null
        try {
            if(feature.key=="classrooms" && values["view"]=="day") {
                val date=runCatching{LocalDate.parse(dateText)}.getOrElse{throw IllegalArgumentException("请输入有效日期，格式为 YYYY-MM-DD")}
                require(values["dm_cx"]==form?.choices?.firstOrNull{it.key=="dm_cx"}?.selected){ "其他学期请使用按节次筛选，并指定周次与星期" }
                val week=CourseClock.week(date,repository.semester())
                require(week in 1..60){ "所选日期不在当前课表学期内，请选择相应学期并使用按节次筛选" }
                values["weeks"]=week.toString();values["weekdays"]=date.dayOfWeek.value.toString()
            }
            rows=repository.query(feature,values.toMap());cachedAt=null
        }catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loading=false;completedReloads++}
    } }
    LaunchedEffect(feature,reload) {
        loading=true;loadingForm=true;error=null
        try {
            if(reload==0)repository.cachedQuery(feature)?.let{cached->rows=cached.rows;values.putAll(cached.parameters);cachedAt=cached.savedAt}
            form=repository.form(feature)
            form!!.choices.forEach{choice->if(choice.values.none{it.first==values[choice.key]})values[choice.key]=choice.selected}
            if(feature.key=="classrooms") {
                values.putIfAbsent("weeks",CourseClock.week(LocalDate.now(),repository.semester()).coerceIn(1,60).toString())
                values.putIfAbsent("weekdays",LocalDate.now().dayOfWeek.value.toString())
                values.putIfAbsent("sessions","1-2");values.putIfAbsent("view","day")
            }
            if(feature.key in listOf("grades","exams","textbooks","cultivation")) {
                rows=repository.query(feature,values.toMap());cachedAt=null
            }
        }catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loading=false;loadingForm=false;completedReloads++;formReloads++}
    }
    LaunchedEffect(reload,form?.choices?.isNotEmpty(),values["jg_id"],values["dm_cx"],values["xqh_id"]) {
        if(form==null)return@LaunchedEffect
        val key=when(feature.key){"cultivation"->"zyh_id_cx";"classrooms"->"lh";else->return@LaunchedEffect}
        loadingChoices=true;dependencyError=false
        val previous=values[key].orEmpty()
        values[key]=""
        form=form?.copy(choices=form!!.choices.map{if(it.key==key)it.copy(values=listOf("" to "全部"))else it})
        try {
            val options=if(feature.key=="cultivation") {
                val school=values["jg_id"].orEmpty()
                if(school.isBlank())listOf("" to "全部") else listOf("" to "全部")+repository.schoolMajors(school)
            }else repository.teachingBuildings(values["dm_cx"].orEmpty(),values["xqh_id"]?:"02")
            form=form?.copy(choices=form!!.choices.map{if(it.key==key)it.copy(values=options)else it})
            values[key]=previous.takeIf{old->options.any{it.first==old}}.orEmpty()
        }catch(e:CancellationException){throw e}catch(e:Exception){dependencyError=true;error=e.message}finally{loadingChoices=false}
    }
    val visibleRows=curriculum?:rows
    val recordType=if(curriculum!=null)"curriculum" else feature.key
    val records by produceState<List<Pair<JSONObject,AcademicRecord>>>(emptyList(),visibleRows,recordType) {
        value=withContext(Dispatchers.Default){visibleRows.orEmpty().map{it to AcademicRecords.record(recordType,it)}}
    }
    val search=LocalAcademicSearch.current
    val searchSession=remember(feature){AcademicSearchSession(feature.key,if(feature.key=="textbooks")"搜索教材" else "搜索课程")}
    val searchable=feature.key=="textbooks" || curriculum!=null
    DisposableEffect(search,searchable,searchSession){
        if(searchable)search?.attach(searchSession)
        onDispose{search?.detach(searchSession);searchSession.close()}
    }
    val keyword=if(searchable)searchSession.query.text else ""
    val filteredRecords by produceState(records,records,keyword) {
        if(keyword.isNotBlank())delay(70)
        value=withContext(Dispatchers.Default){records.filter{AcademicKeywordSearch.matches(it.second,keyword)}}
    }
    val resultsAlpha=rememberCrestoReloadAlpha(loading,completedReloads)
    val formAlpha=rememberCrestoReloadAlpha(loadingForm,formReloads)
    val errorAlpha=rememberCrestoReloadAlpha(loading||loadingChoices,error to completedReloads)
    var idleError by remember(feature){mutableStateOf<String?>(null)}
    SideEffect{if(!loading&&!loadingChoices)idleError=error}
    val shownError=error?:idleError.takeIf{loading||loadingChoices}
    Box(Modifier.fillMaxSize()) {
    GlasmioPinnedListPage(if(curriculum!=null)curriculumTitle else feature.title,bottomPadding=180.dp,onNavigateBack=close) {
        if(curriculum==null) {
            item { GlasmioGroupedList { form?.choices?.forEach { choice -> key(choice.key) {
                val dependent=choice.key=="zyh_id_cx"||choice.key=="lh"
                val choiceAlpha=rememberCrestoReloadAlpha(loadingForm||(loadingChoices&&dependent),formReloads to choice.values)
                GlasmioListRow(choice.label,modifier=Modifier.reloadFade(choiceAlpha),detail=choice.values.firstOrNull{it.first==values[choice.key]}?.second,
                    showDisclosure=true,
                    onClick=if(!loading && !loadingChoices){{picker=choice.key}}else null)
            } } } }
            form?.notices?.forEach{notice->item{Text(notice,modifier=Modifier.reloadFade(formAlpha),style=IosTypography.footnote,color=LocalGlassColors.current.secondaryContent)}}
            if(feature.key=="classrooms") {
                item{GlasmioGroupedList {
                    listOf("cdmc" to "教室名称或编号（可选）","qszws" to "最小座位数（可选）","jszws" to "最大座位数（可选）").forEach{(key,label)->
                        GlasmioTextField(values[key].orEmpty(),{values[key]=it},placeholder=label)
                    }
                    GlasmioListRow("查询方式",detail=if(values["view"]=="day")"当日分时段总览"else "按节次筛选",onClick={picker="view"})
                    if(values["view"]=="day") {
                        Text("查询日期",style=IosTypography.footnote,modifier=Modifier.padding(horizontal=16.dp,vertical=8.dp))
                        GlasmioTextField(dateText,{dateText=it},placeholder="YYYY-MM-DD")
                        Row(Modifier.padding(12.dp),horizontalArrangement=Arrangement.spacedBy(12.dp)){
                            GlasmioButton(onClick={dateText=LocalDate.now().toString()}){Text("今天")}
                            GlasmioButton(onClick={dateText=LocalDate.now().plusDays(1).toString()}){Text("明天")}
                        }
                    }else listOf("weeks" to "周次（如 1-4,6）","weekdays" to "星期（1 为周一，7 为周日）","sessions" to "节次（如 1-2,5-6）").forEach{(key,label)->
                        Text(label,style=IosTypography.footnote,modifier=Modifier.padding(horizontal=16.dp,vertical=8.dp))
                        GlasmioTextField(values[key].orEmpty(),{values[key]=it},placeholder=label)
                    }
                }}
            }
            if(form!=null)item{GlasmioButton(onClick={query()},enabled=!loading&&!loadingChoices,modifier=Modifier.fillMaxWidth(),emphasis=GlassEmphasis.Prominent){Text("查询")}}
        }
        shownError?.let{message->item{GlasmioGroupedList(Modifier.reloadFade(errorAlpha)){
            Text(message,color=LocalGlassColors.current.destructive,modifier=Modifier.padding(16.dp))
            GlasmioListRow("重试",onClick=if(loading||loadingChoices)null else {{if(form==null || dependencyError)reload++ else query()}})
        }}}
        cachedAt?.takeIf{curriculum==null}?.let{saved->item{Text("上次查询："+java.text.DateFormat.getDateTimeInstance().format(java.util.Date(saved)),modifier=Modifier.reloadFade(resultsAlpha),style=IosTypography.caption1)}}
        if(error==null && visibleRows?.isEmpty()==true)item{Text(when(recordType){"exams"->"所选学期暂无考试安排";"grades"->"所选学期暂无成绩，请尝试其他学期";"textbooks"->"所选学期暂无教材记录";else->"暂无符合条件的记录"},style=IosTypography.body,modifier=Modifier.padding(vertical=20.dp).reloadFade(resultsAlpha))}
        if(feature.key=="exams"&&!rows.isNullOrEmpty())item{GlasmioButton(onClick={exporter.launch("Xachet-Exams.ics")},modifier=Modifier.fillMaxWidth().reloadFade(resultsAlpha)){Text("导出考试日历")}}
        if(feature.key=="classrooms" && visibleRows?.firstOrNull()?.has("_freeSessions")==true) {
            item{Text("空：该时段可用；满：该时段不满足空闲条件",modifier=Modifier.reloadFade(resultsAlpha),style=IosTypography.footnote)}
            item{ClassroomMatrixRow("教室",AcademicRecords.daySessions,header=true,modifier=Modifier.reloadFade(resultsAlpha))}
            items(visibleRows!!.size){index->val row=visibleRows!![index]
                ClassroomMatrixRow(row.optString("cdmc"),(0..4).map{if(row.optString("_freeSessions").contains(it.toString()))"空"else "满"},modifier=Modifier.reloadFade(resultsAlpha))
            }
        }else {
            if(keyword.isNotBlank() && visibleRows!=null)item{Text("找到 ${filteredRecords.size} 条结果",modifier=Modifier.reloadFade(resultsAlpha),style=IosTypography.footnote)}
            if(keyword.isNotBlank() && filteredRecords.isEmpty() && !visibleRows.isNullOrEmpty())item{Text("没有匹配的课程或教材",style=IosTypography.body,modifier=Modifier.padding(vertical=20.dp).reloadFade(resultsAlpha))}
            items(filteredRecords.size){index->val (row,record)=filteredRecords[index]
            GlasmioGroupedList(Modifier.reloadFade(resultsAlpha)) {
                GlasmioListRow(record.title,showTopSeparator=false,onClick=if(recordType=="cultivation"&&row.optString("jxzxjhxx_id").isNotBlank()&&!loading){{scope.launch{
                    loading=true;error=null
                    try{curriculum=repository.curriculum(row.getString("jxzxjhxx_id"));curriculumTitle=record.title}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loading=false;completedReloads++}
                }}}else null)
                record.fields.forEach{(label,value)->GlasmioListRow(label,detail=value)}
            }
        }
    }
    }
    if(loading||loadingChoices)Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center){CircularProgressIndicator()}
    }
    val selectedChoice=if(picker=="view")QueryChoice("view","查询方式",listOf("day" to "当日分时段总览","filter" to "按节次筛选"),values["view"].orEmpty())else form?.choices?.firstOrNull{it.key==picker}
    GlasmioBottomSheet(onDismissRequest={picker=null},visible=selectedChoice!=null,title=selectedChoice?.label.orEmpty()) {
        LazyColumn{selectedChoice?.let{choice->items(choice.values){(key,label)->
            GlasmioListRow(label,detail=if(values[choice.key]==key)"已选"else null,onClick={values[choice.key]=key;picker=null})
        }}}
    }
}

@Composable private fun ClassroomMatrixRow(name:String,columns:List<String>,header:Boolean=false,modifier:Modifier=Modifier) {
    val colors=LocalGlassColors.current
    GlasmioGroupedList(modifier) { Row(Modifier.fillMaxWidth().padding(horizontal=10.dp,vertical=12.dp),verticalAlignment=Alignment.CenterVertically) {
        Text(name,Modifier.weight(2.5f),style=IosTypography.footnote)
        columns.forEach{value->Box(Modifier.weight(1f),contentAlignment=Alignment.Center){Text(value,style=IosTypography.caption1,
            color=if(header)colors.secondaryContent else if(value=="空")colors.accent else colors.secondaryContent)}}
    } }
}
