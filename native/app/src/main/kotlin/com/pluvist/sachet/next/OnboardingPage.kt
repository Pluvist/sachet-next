// Layout and pager motion reference: Nevodev/Cresto GuideScreen (Apache-2.0).
package com.pluvist.sachet.next

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.pager.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.glass.render.backdrops.rememberLayerBackdrop
import io.github.neoruaa.glasmio.ui.*
import kotlinx.coroutines.launch

@Composable internal fun OnboardingPage(data:AppData,vm:SachetViewModel,onComplete:()->Unit) {
    val pager=rememberPagerState(pageCount={5})
    val scope=rememberCoroutineScope()
    val context=LocalContext.current
    val colors=LocalGlassColors.current
    val landscape=LocalConfiguration.current.screenWidthDp>LocalConfiguration.current.screenHeightDp
    var agreed by rememberSaveable{mutableStateOf(false)}
    var id by rememberSaveable{mutableStateOf(data.account.studentID)}
    var password by remember{mutableStateOf("")}
    var rememberPassword by rememberSaveable{mutableStateOf(true)}
    var cookieMode by rememberSaveable{mutableStateOf(false)}
    var cookie by remember{mutableStateOf("")}
    var webLogin by rememberSaveable{mutableStateOf(false)}
    var finishing by remember{mutableStateOf(false)}
    val status by rememberBackgroundSetupStatus(pager.currentPage==3&&!webLogin)
    val live=status["live"] as? Map<*,*>
    val requestNotifications=rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()){}
    fun next(page:Int){scope.launch{pager.animateScrollToPage(page,animationSpec=spring(1f,300f))}}
    BackHandler(pager.currentPage>0&&!webLogin){next(pager.currentPage-1)}
    BackHandler(webLogin){webLogin=false}
    val footerBackdrop=rememberLayerBackdrop()
    if(webLogin){
        WebLoginPage(vm,onAuthenticated={webLogin=false;next(3)}){webLogin=false}
        return
    }
    val footerHeight=if(landscape)98.dp else 130.dp
    Box(Modifier.fillMaxSize().background(colors.groupedBackground)) {
    Box(Modifier.fillMaxSize().glassBackdropSource(footerBackdrop).trackBackdropPosition(footerBackdrop)) {
    Column(Modifier.fillMaxSize().background(colors.groupedBackground).safeDrawingPadding().imePadding().padding(bottom=footerHeight),horizontalAlignment=Alignment.CenterHorizontally) {
        Row(Modifier.widthIn(max=640.dp).fillMaxWidth().height(52.dp).padding(horizontal=16.dp),verticalAlignment=Alignment.CenterVertically) {
            Box(Modifier.size(48.dp).clip(com.kyant.shapes.Capsule()).then(if(pager.currentPage>0)Modifier.clickable{next(pager.currentPage-1)}else Modifier),contentAlignment=Alignment.Center) {
                if(pager.currentPage>0)Icon(Icons.AutoMirrored.Filled.ArrowBack,"上一步",tint=colors.content)
            }
            Spacer(Modifier.weight(1f))
            Text("${pager.currentPage+1} / 5",style=IosTypography.footnote,color=colors.secondaryContent,modifier=Modifier.padding(end=16.dp))
        }
        HorizontalPager(pager,userScrollEnabled=false,beyondViewportPageCount=1,modifier=Modifier.weight(1f).fillMaxWidth()) { page ->
            LazyColumn(Modifier.fillMaxSize(),contentPadding=PaddingValues(horizontal=24.dp,vertical=if(landscape)16.dp else 40.dp),
                horizontalAlignment=Alignment.CenterHorizontally,verticalArrangement=if(page==0||page==4)Arrangement.Center else Arrangement.spacedBy(12.dp)) {
                item {
                    Column(Modifier.widthIn(max=540.dp).fillMaxWidth(),horizontalAlignment=Alignment.CenterHorizontally) {
                        if(page==0||page==4){GuideEmblem(page==4,pager.settledPage==page);Spacer(Modifier.height(24.dp))}
                        Text(listOf("欢迎使用 Xachet","先了解一下","登录教务账号","让课程及时出现","一切准备就绪")[page],
                            style=IosTypography.title1.copy(fontSize=24.sp,lineHeight=32.sp,fontWeight=FontWeight.SemiBold),textAlign=TextAlign.Center)
                        Spacer(Modifier.height(12.dp))
                        Text(listOf("课程、校园与每一天。","你的数据，由你掌握。","同步课表与校园教务信息。","开启通知、后台运行与桌面小组件。","从今天的课程开始。")[page],
                            style=IosTypography.subheadline,color=colors.secondaryContent,textAlign=TextAlign.Center)
                        Spacer(Modifier.height(if(page==0||page==4)24.dp else 20.dp))
                    }
                }
                when(page) {
                    0->item{GuideInfo(Icons.Default.CalendarMonth,"一眼看见今天","正在上课、下一节课与空闲教室，随时可见。")}
                    1->{
                        item{GuideInfo(Icons.Default.Lock,"账号仅保存在本机","账号及记住的密码通过本机密钥加密保存，仅用于访问学校教务系统。")}
                        item{GuideInfo(Icons.Default.CloudDone,"缓存与课程显示","课表缓存用于离线显示、桌面小组件与课程实时活动；联网后可同步最新安排。")}
                        item{GuideInfo(Icons.Default.Code,"开放与致谢","基于上游 Sachet 二次修改，感谢所有开源贡献者。",onClick={context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://github.com/Pluvist/Xachet")))})}
                        item{Box(Modifier.widthIn(max=540.dp).fillMaxWidth()){GlasmioListRow("我已阅读并同意以上声明",trailing={GlasmioSwitch(agreed,{agreed=it})},onClick={agreed=!agreed})}}
                    }
                    2->{
                        item{Column(Modifier.widthIn(max=540.dp).fillMaxWidth().clip(G2RoundedRectangle(20.dp)).background(colors.elevatedBackground).padding(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
                            if(cookieMode)GlasmioTextField(cookie,{cookie=it;vm.dismissMessage()},placeholder="教务 Cookie",visualTransformation=PasswordVisualTransformation())
                            else {
                                Text("学号",style=IosTypography.footnote,color=colors.secondaryContent)
                                GlasmioTextField(id,{id=it;vm.dismissMessage()},placeholder="请输入学号",keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Number))
                                Text("密码",style=IosTypography.footnote,color=colors.secondaryContent)
                                GlasmioTextField(password,{password=it;vm.dismissMessage()},placeholder="默认密码为 Xtu@身份证后六位",visualTransformation=PasswordVisualTransformation())
                                GlasmioListRow("记住密码",trailing={GlasmioSwitch(rememberPassword,{rememberPassword=it})})
                            }
                        }}
                        item{Box(Modifier.widthIn(max=540.dp).fillMaxWidth()){GlasmioListRow(if(cookieMode)"使用学号密码登录" else "使用 Cookie 登录",onClick={cookieMode=!cookieMode;vm.dismissMessage()})}}
                        item{Box(Modifier.widthIn(max=540.dp).fillMaxWidth()){GlasmioListRow("通过教务网页登录",onClick={webLogin=true})}}
                        data.message?.let{message->item{Text(message,style=IosTypography.footnote,color=colors.destructive,modifier=Modifier.widthIn(max=540.dp).padding(12.dp))}}
                        item{Text("稍后登录",style=IosTypography.callout,color=colors.secondaryContent,modifier=Modifier.heightIn(min=48.dp).clickable(enabled=!data.loading){next(3)}.padding(12.dp))}
                    }
                    3->{
                        item{GuideInfo(Icons.Default.Notifications,"通知权限",if(status.isEmpty())"正在读取"else if(live?.get("notifications")==true)"已允许"else"点击允许课程通知",onClick={requestNotifications.launch(Manifest.permission.POST_NOTIFICATIONS)})}
                        item{GuideInfo(Icons.Default.Timer,"实时活动",if(status.isEmpty())"正在读取"else if(live?.get("promoted")==true)"已允许"else"点击打开系统通知与实时活动设置",onClick={context.startActivity(Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(android.provider.Settings.EXTRA_APP_PACKAGE,context.packageName))})}
                        item{GuideInfo(Icons.Default.BatteryChargingFull,"后台运行",if(status["batteryUnrestricted"]==true)"已允许无限制运行"else"点击设置后台运行权限",onClick={BackgroundSetupSettings.open(context as Activity,"battery")})}
                        item{GuideInfo(Icons.Default.RestartAlt,"自启动","点击打开系统设置，在系统页面确认",onClick={BackgroundSetupSettings.open(context as Activity,"autostart")})}
                        item{GuideInfo(Icons.Default.Widgets,"桌面小组件","长按桌面添加 Xachet，或稍后在个人页面添加。")}
                    }
                    4->item{GuideInfo(Icons.Default.CheckCircleOutline,"你的校园日程已就位","主页优先显示本地课表，最新课程信息会在后台同步。")}
                }
            }
        }
    }
    }
    CompositionLocalProvider(LocalGlassBackdrop provides footerBackdrop,LocalBlurBackdrop provides footerBackdrop) {
    Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth()
        .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Horizontal+WindowInsetsSides.Bottom))
        .imePadding(),horizontalAlignment=Alignment.CenterHorizontally) {
        Row(Modifier.padding(vertical=12.dp),horizontalArrangement=Arrangement.spacedBy(6.dp)) {
            repeat(5){index->Box(Modifier.size(width=if(index==pager.currentPage)18.dp else 6.dp,height=6.dp).background(if(index==pager.currentPage)colors.accent else colors.separator,com.kyant.shapes.Capsule()))}
        }
        GlasmioButton(onClick={
            when(pager.currentPage){
                2->if(cookieMode)vm.cookieLogin(cookie){next(3)}else vm.login(id,password,rememberPassword){next(3)}
                4->{finishing=true;scope.launch{try{vm.saveSettings(mapOf("hasReadDisclaimer" to true));onComplete()}finally{finishing=false}}}
                else->next(pager.currentPage+1)
            }
        },enabled=!finishing&&!pager.isScrollInProgress&&(pager.currentPage!=1||agreed)&&(pager.currentPage!=2||(!data.loading&&if(cookieMode)cookie.isNotBlank()else id.isNotBlank()&&password.isNotBlank())),
            emphasis=GlassEmphasis.Prominent,modifier=Modifier.padding(horizontal=48.dp).widthIn(max=480.dp).fillMaxWidth().height(52.dp)){
            if(finishing||(pager.currentPage==2&&data.loading))CircularProgressIndicator(Modifier.size(20.dp),strokeWidth=2.dp,color=Color.White)
            else Text(when(pager.currentPage){0->"开始";1->"同意并继续";2->"登录并同步";4->"开始使用";else->"继续"})
        }
        Spacer(Modifier.height(if(landscape)16.dp else 48.dp))
    }
    }
    }
}

@Composable private fun GuideInfo(icon:ImageVector,title:String,description:String,onClick:(()->Unit)?=null){
    val colors=LocalGlassColors.current
    Row(Modifier.widthIn(max=540.dp).fillMaxWidth().clip(G2RoundedRectangle(20.dp)).background(colors.elevatedBackground)
        .then(if(onClick!=null)Modifier.clickable(onClick=onClick)else Modifier).padding(16.dp),
        verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(12.dp)){
        Icon(icon,null,Modifier.size(32.dp),tint=colors.accent)
        Column(Modifier.weight(1f),verticalArrangement=Arrangement.spacedBy(4.dp)){
            Text(title,style=IosTypography.callout.copy(fontWeight=FontWeight.Medium))
            Text(description,style=IosTypography.subheadline,color=colors.secondaryContent)
        }
        if(onClick!=null)Icon(Icons.Default.ChevronRight,null,Modifier.size(18.dp),tint=colors.secondaryContent)
    }
}

@Composable private fun GuideEmblem(completed:Boolean,active:Boolean){
    val phase=if(active)rememberInfiniteTransition(label="Guide light").animateFloat(0f,1f,infiniteRepeatable(tween(4000,easing=LinearEasing),RepeatMode.Reverse),label="Light phase")else null
    val colors=listOf(Color(0xFF3887FA),Color(0xFF9566EF),Color(0xFFE778C7),Color(0xFF5368EE))
    Box(Modifier.size(96.dp).clip(G2RoundedRectangle(24.dp)).background(Brush.linearGradient(colors)),contentAlignment=Alignment.Center){
        Box(Modifier.matchParentSize().graphicsLayer{alpha=.15f+(phase?.value?:0f)*.3f}.background(Brush.radialGradient(listOf(Color.White,Color.Transparent))))
        Icon(if(completed)Icons.Default.CheckCircleOutline else Icons.Default.CalendarMonth,null,Modifier.size(52.dp),tint=Color.White)
    }
}
