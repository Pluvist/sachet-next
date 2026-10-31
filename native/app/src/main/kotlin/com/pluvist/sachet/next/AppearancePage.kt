package com.pluvist.sachet.next
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.ui.*
import io.github.neoruaa.glasmio.scaffold.*
import kotlinx.coroutines.*
import org.json.JSONObject

@Composable internal fun AppearancePage(vm:SachetViewModel,back:()->Unit) {
    val original=remember{vm.repository.appearance()}
    val fields=remember{linkedMapOf("cardHeight" to ("卡片高度" to 60),"cardBorderRadius" to ("卡片圆角" to 6),"cardMargin" to ("卡片边距" to 2),"TitleFontSize" to ("课程名字号" to 14),"PlaceFontSize" to ("地点字号" to 11),"InstructorFontSize" to ("教师字号" to 11),"TitleFontWeight" to ("课程名字重" to 6),"PlaceFontWeight" to ("地点字重" to 5),"InstructorFontWeight" to ("教师字重" to 4),"TitleMaxLines" to ("课程名最大行数" to 3),"PlaceMaxLines" to ("地点最大行数" to 5),"InstructorMaxLines" to ("教师最大行数" to 2))}
    val colorFields=remember{mapOf("TitleTextColor" to "课程名颜色","PlaceTextColor" to "地点颜色","InstructorTextColor" to "教师颜色")}
    val values=remember{mutableStateMapOf<String,String>().apply{fields.forEach{(key,pair)->put(key,original.optDouble(key,pair.second.toDouble()).toString())}}}
    val colors=remember{mutableStateMapOf<String,String>().apply{colorFields.forEach{(key,_)->put(key,original.optString(key,"#FFFFFFFF"))}}}
    val scope=rememberCoroutineScope();var error by remember{mutableStateOf<String?>(null)}
    GlasmioPinnedListPage("课表外观",bottomPadding=180.dp,onNavigateBack=back) {
        items(fields.size){index->val entry=fields.entries.elementAt(index)
            GlasmioGroupedList {
                GlasmioListRow(entry.value.first,showTopSeparator=false)
                GlasmioTextField(values[entry.key].orEmpty(),{values[entry.key]=it},placeholder=entry.value.first)
            }
        }
        items(colorFields.size){index->val entry=colorFields.entries.elementAt(index)
            GlasmioGroupedList{GlasmioListRow(entry.value,showTopSeparator=false);GlasmioTextField(colors[entry.key].orEmpty(),{colors[entry.key]=it},placeholder="#FFFFFFFF")}
        }
        item{GlasmioButton(onClick={scope.launch{
            try{
                val result=JSONObject(original.toString())
                values.forEach{(key,text)->val value=text.toDoubleOrNull()?:error("请输入有效数值");require(value.isFinite()&&value>=0&&value<=300){"数值应在 0 到 300 之间"};result.put(key,value)}
                require(result.optDouble("cardHeight")>=24){"卡片高度至少为 24"}
                colors.forEach{(key,value)->android.graphics.Color.parseColor(value);result.put(key,value)}
                vm.saveAppearance(result);back()
            }catch(e:CancellationException){throw e}catch(e:Exception){error=e.message}
        }},modifier=Modifier.fillMaxWidth()){Text("保存")}}
        error?.let{item{Text(it,color=LocalGlassColors.current.destructive)}}
    }
}
