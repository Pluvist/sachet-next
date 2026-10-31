package com.pluvist.sachet.next
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.ui.*
import io.github.neoruaa.glasmio.scaffold.*
import kotlinx.coroutines.*

@Composable internal fun FileManagerPage(vm:SachetViewModel,back:()->Unit) {
    var files by remember{mutableStateOf<List<ManagedDataFile>>(emptyList())}
    var selected by remember{mutableStateOf<ManagedDataFile?>(null)}
    var body by remember{mutableStateOf("")}
    var error by remember{mutableStateOf<String?>(null)}
    var confirmDelete by remember{mutableStateOf(false)}
    var completedReloads by remember{mutableIntStateOf(0)}
    var loadingFiles by remember{mutableStateOf(true)}
    var loadingBody by remember{mutableStateOf(false)}
    var bodyReloads by remember{mutableIntStateOf(0)}
    val context=LocalContext.current;val scope=rememberCoroutineScope();val colors=LocalGlassColors.current
    LaunchedEffect(Unit){try{files=vm.repository.managedFiles()}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loadingFiles=false;completedReloads++}}
    BackHandler(selected!=null){selected=null}
    val export=rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/json")){uri->uri?.let{scope.launch{
        try{withContext(Dispatchers.IO){val output=context.contentResolver.openOutputStream(uri)?:error("无法导出文件");output.bufferedWriter().use{it.write(body)}}}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}
    }}}
    val filesAlpha=rememberCrestoReloadAlpha(loadingFiles,completedReloads)
    val bodyAlpha=rememberCrestoReloadAlpha(loadingBody,bodyReloads)
    GlasmioPinnedListPage(selected?.name?:"数据文件",bottomPadding=180.dp,onNavigateBack={if(selected!=null)selected=null else back()}) {
        if(selected==null) {
            if(files.isEmpty())item{Text("还没有课程或查询数据文件",modifier=Modifier.reloadFade(filesAlpha),style=IosTypography.body)}
            items(files.size){index->val file=files[index];GlasmioGroupedList(Modifier.reloadFade(filesAlpha)){
                GlasmioListRow(file.name,subtitle="${when(file.kind){"schedule"->"课表";"colors"->"配色";else->"查询缓存"}} · ${file.bytes/1024} KB",onClick={scope.launch{
                    loadingBody=true
                    try{body=vm.repository.readManagedFile(file);selected=file;confirmDelete=false;error=null}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loadingBody=false;bodyReloads++}
                }})
            }}
        } else {
            item{BasicTextField(body,{body=it},Modifier.fillMaxWidth().height(420.dp).verticalScroll(rememberScrollState()).padding(12.dp).reloadFade(bodyAlpha),textStyle=TextStyle(color=colors.content,fontFamily=MiSansFamily,fontSize=13.sp),cursorBrush=SolidColor(colors.accent))}
            item{GlasmioGroupedList{
                GlasmioListRow("保存修改",onClick={scope.launch{loadingFiles=true;try{vm.repository.writeManagedFile(selected!!,body);files=vm.repository.managedFiles();vm.reloadLocal();selected=null}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loadingFiles=false;completedReloads++}}})
                if(selected?.kind in setOf("schedule","colors"))GlasmioListRow("启用此文件",onClick={if(selected?.kind=="schedule")vm.importSchedule(body)else vm.importColors(body);selected=null})
                GlasmioListRow("导出文件",onClick={export.launch(selected!!.name)})
                GlasmioListRow(if(confirmDelete)"确认删除此文件" else "删除文件",titleColor=colors.destructive,onClick={if(!confirmDelete)confirmDelete=true else scope.launch{
                    loadingFiles=true
                    try{vm.repository.deleteManagedFile(selected!!);files=vm.repository.managedFiles();vm.reloadLocal();selected=null}catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}finally{loadingFiles=false;completedReloads++}
                }})
            }}
        }
        error?.let{item{Text(it,color=colors.destructive)}}
    }
}
