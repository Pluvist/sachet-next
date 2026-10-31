package com.pluvist.sachet.next

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.unit.dp
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.ui.*
import io.github.neoruaa.glasmio.scaffold.*
import kotlinx.coroutines.*
import java.io.File
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor

@Composable internal fun SettingsPage(vm:SachetViewModel,back:()->Unit) {
    val settings=remember{vm.repository.settings()}
    var semester by remember{mutableStateOf(settings.optString("semesterStartDate").take(10))}
    var live by remember{mutableStateOf(settings.optBoolean("isEnableCourseLiveActivity",true))}
    var theme by remember{mutableIntStateOf(settings.optInt("themeMode"))}
    var accent by remember{mutableStateOf(settings.optString("themeColor","#0088FF"))}
    var error by remember{mutableStateOf<String?>(null)}
    val scope=rememberCoroutineScope()
    GlasmioPinnedListPage("设置",bottomPadding=180.dp,onNavigateBack=back) {
        item{Text("学期开始日期（周一）",style=IosTypography.footnote)}
        item{GlasmioGroupedList{
            GlasmioTextField(semester,{semester=it},placeholder="YYYY-MM-DD")
            GlasmioListRow("课程实时活动",trailing={GlasmioSwitch(live,{live=it})})
            GlasmioListRow("主题",detail=listOf("跟随系统","浅色","深色")[theme.coerceIn(0,2)],onClick={theme=(theme+1)%3})
            GlasmioTextField(accent,{accent=it},placeholder="主题色，例如 #0088FF")
        }}
        item{GlasmioButton(onClick={scope.launch{
            try{android.graphics.Color.parseColor(accent);vm.saveSettings(mapOf("semesterStartDate" to semester,"isEnableCourseLiveActivity" to live,"themeMode" to theme,"themeColor" to accent));back()}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}
        }},modifier=Modifier.fillMaxWidth()){Text("保存")}}
        error?.let{item{Text(it,color=LocalGlassColors.current.destructive)}}
    }
}

@Composable internal fun DataPage(data:AppData,vm:SachetViewModel,back:()->Unit) {
    val context=LocalContext.current;val scope=rememberCoroutineScope()
    var importKind by remember{mutableStateOf("schedule")}
    var error by remember{mutableStateOf<String?>(null)}
    val importer=rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()){uri->uri?.let{scope.launch{
        try{val body=withContext(Dispatchers.IO){context.contentResolver.openInputStream(uri)?.bufferedReader()?.use{it.readText()}?:error("无法打开文件")};if(importKind=="colors")vm.importColors(body)else vm.importSchedule(body)}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}
    }}}
    val exporter=rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("text/calendar")){uri->uri?.let{scope.launch{
        try{withContext(Dispatchers.IO){val output=context.contentResolver.openOutputStream(uri)?:error("无法写入文件");output.bufferedWriter().use{it.write(CalendarExport.ics(data.courses,vm.repository.semester()))}}}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}
    }}}
    GlasmioPinnedListPage("导入与导出",bottomPadding=180.dp,onNavigateBack=back) {
        item{GlasmioGroupedList{
            GlasmioListRow("导入课表 JSON",subtitle="支持原 Sachet 课表与教务原始数据",onClick={importKind="schedule";importer.launch(arrayOf("application/json","text/plain","application/octet-stream"))})
            GlasmioListRow("导入课程配色",subtitle="兼容原 Sachet 配色 JSON",onClick={importKind="colors";importer.launch(arrayOf("application/json","text/plain","application/octet-stream"))})
            GlasmioListRow("导出到日历",subtitle="按教学楼真实作息生成 ICS",onClick={exporter.launch("Xachet.ics")})
        }}
        error?.let{item{Text(it,color=LocalGlassColors.current.destructive)}}
    }
}

@Composable internal fun TranscriptPage(repository:AcademicRepository,back:()->Unit) {
    var types by remember{mutableStateOf<List<Pair<String,String>>>(emptyList())}
    var selected by remember{mutableStateOf("")}
    var picker by remember{mutableStateOf(false)}
    var loadingTypes by remember{mutableStateOf(true)}
    var downloading by remember{mutableStateOf(false)}
    var error by remember{mutableStateOf<String?>(null)}
    var file by remember{mutableStateOf<File?>(null)}
    var page by remember{mutableIntStateOf(0)}
    var pageCount by remember{mutableIntStateOf(0)}
    val scope=rememberCoroutineScope()
    var reload by remember{mutableIntStateOf(0)}
    var typeReloads by remember{mutableIntStateOf(0)}
    var pdfReloads by remember{mutableIntStateOf(0)}
    var rendering by remember{mutableStateOf(false)}
    var renderRequest by remember{mutableIntStateOf(0)}
    val loading=loadingTypes||downloading
    LaunchedEffect(reload){loadingTypes=true;error=null;try{types=repository.transcriptTypes();if(types.none{it.first==selected})selected=types.firstOrNull()?.first.orEmpty()}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loadingTypes=false;typeReloads++}}
    val bitmap by produceState<Bitmap?>(null,file,page,renderRequest) {
        if(file==null)value=null
        file?.let{pdf->rendering=true;try{value=withContext(Dispatchers.IO){
            ParcelFileDescriptor.open(pdf,ParcelFileDescriptor.MODE_READ_ONLY).use{descriptor->PdfRenderer(descriptor).use{renderer->
                val count=renderer.pageCount
                renderer.openPage(page.coerceIn(0,(count-1).coerceAtLeast(0))).use{source->
                    Bitmap.createBitmap(1080,(1080f*source.height/source.width).toInt(),Bitmap.Config.ARGB_8888).also{source.render(it,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)}
                }
            }}
        };pageCount=withContext(Dispatchers.IO){ParcelFileDescriptor.open(pdf,ParcelFileDescriptor.MODE_READ_ONLY).use{PdfRenderer(it).use{it.pageCount}}}}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{rendering=false;pdfReloads++}}
    }
    val typesAlpha=rememberCrestoReloadAlpha(loadingTypes,typeReloads)
    val pdfAlpha=rememberCrestoReloadAlpha(downloading||rendering,pdfReloads)
    val errorAlpha=rememberCrestoReloadAlpha(loading||rendering,error to (typeReloads+pdfReloads))
    var idleError by remember{mutableStateOf<String?>(null)}
    SideEffect{if(!loading&&!rendering)idleError=error}
    val shownError=error?:idleError.takeIf{loading||rendering}
    Box(Modifier.fillMaxSize()) {
    GlasmioPinnedListPage("成绩单",bottomPadding=180.dp,onNavigateBack=back) {
        item{GlasmioGroupedList(Modifier.reloadFade(typesAlpha)){GlasmioListRow("格式",detail=types.firstOrNull{it.first==selected}?.second,onClick={picker=true})}}
        item{GlasmioButton(onClick={scope.launch{downloading=true;error=null;try{val downloaded=repository.transcript(selected);rendering=true;file=downloaded;page=0;renderRequest++}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{downloading=false}}},enabled=!loading&&selected.isNotBlank(),modifier=Modifier.fillMaxWidth()){Text("下载并查看")}}
        shownError?.let{item{GlasmioGroupedList(Modifier.reloadFade(errorAlpha)){Text(it,color=LocalGlassColors.current.destructive,modifier=Modifier.padding(16.dp));GlasmioListRow("重新加载成绩单格式",onClick={reload++})}}}
        bitmap?.let{image->item{Image(image.asImageBitmap(),"成绩单第${page+1}页",Modifier.fillMaxWidth().height(600.dp).reloadFade(pdfAlpha))}}
        if(pageCount>1)item{Row(Modifier.reloadFade(pdfAlpha),horizontalArrangement=Arrangement.spacedBy(12.dp)){
            GlasmioButton(onClick={page--},enabled=page>0){Text("上一页")};Text("${page+1}/$pageCount")
            GlasmioButton(onClick={page++},enabled=page+1<pageCount){Text("下一页")}
        }}
    }
    if(loading||rendering)Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center){CircularProgressIndicator()}
    }
    GlasmioBottomSheet(onDismissRequest={picker=false},visible=picker,title="成绩单格式",fitContent=true){types.forEach{(key,label)->GlasmioListRow(label,onClick={selected=key;picker=false})}}
}
