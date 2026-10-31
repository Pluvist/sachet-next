package com.pluvist.sachet.next
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.ui.*
import io.github.neoruaa.glasmio.scaffold.*
import kotlinx.coroutines.*

@Composable internal fun AboutPage(back:()->Unit) {
    val context=LocalContext.current
    var document by remember{mutableStateOf<String?>(null)}
    var text by remember{mutableStateOf("")}
    LaunchedEffect(document){document?.let{file->text=withContext(Dispatchers.IO){context.assets.open("legal/$file").bufferedReader().use{it.readText()}}}}
    GlasmioPinnedListPage(document?:"关于",bottomPadding=180.dp,onNavigateBack={if(document!=null)document=null else back()}) {
        if(document!=null)item{Text(text,style=IosTypography.footnote)}else {
            item{GlasmioGroupedList{
                GlasmioListRow("Xachet",detail=BuildConfig.VERSION_NAME,showTopSeparator=false)
                GlasmioListRow("作者",detail="Pluvist")
                GlasmioListRow("上游 Sachet",subtitle="基于 Sachet 二次修改，感谢 wyvern1723 及其贡献者",onClick={context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://github.com/wyvern1723/sachet")))})
                GlasmioListRow("MeiloX",subtitle="界面与交互参考",onClick={context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://github.com/NEORUAA/MeiloX")))})
                GlasmioListRow("Glasmio",subtitle="原生组件与液态玻璃渲染",onClick={context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://github.com/NEORUAA/Glasmio")))})
                GlasmioListRow("Cresto",subtitle="页面转场与引导页设计参考 · Apache-2.0",onClick={context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://github.com/Nevodev/Cresto")))})
                GlasmioListRow("MiSans 可变字体",subtitle="本应用使用小米 MiSans 字体，字体版权归小米所有",onClick={context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://hyperos.mi.com/font/")))})
            }}
            item{GlasmioGroupedList{
                GlasmioListRow("AGPL-3.0 许可",onClick={document="LICENSE"})
                GlasmioListRow("Sachet 上游 MIT 许可",onClick={document="LICENSE-MIT"})
                GlasmioListRow("第三方声明",onClick={document="THIRD_PARTY_NOTICES.md"})
                GlasmioListRow("Cresto Apache-2.0 许可",onClick={document="Cresto-LICENSE"})
            }}
        }
    }
}
