package com.pluvist.sachet.next

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.ui.draw.clip
import androidx.compose.material.icons.filled.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.icons.*
import io.github.neoruaa.glasmio.scaffold.*
import io.github.neoruaa.glasmio.ui.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.CancellationException
import java.time.*
import java.time.format.DateTimeFormatter
import org.json.JSONObject

private data class HomeFeature(val key:String,val title:String,val url:String?=null)
private val HomeCardShape=G2RoundedRectangle(24.dp)
private val campusNetworkFeature=HomeFeature("network","校园网认证","http://zz.xtu.edu.cn/portal/portal-main")
private val classroomsFeature=HomeFeature("classrooms","空闲教室")
private val homeFeatures=listOf(
    HomeFeature("cultivation","培养方案"),HomeFeature("textbooks","教材预订"),HomeFeature("exams","考试时间"),
    HomeFeature("grades","成绩查询"),HomeFeature("gpa","绩点排名"),HomeFeature("transcript","成绩单"),
    HomeFeature("library","馆藏检索","https://mfindxtu.libsp.cn/#/home"),
    HomeFeature("physics","大物实验","https://wlsy.xtu.edu.cn"))
private val campusLinks=listOf(
    HomeFeature("calendar","湘大校历","https://www.xtu.edu.cn/xysh/ggfw/xl.htm"),
    HomeFeature("news","湘大新闻","https://www.xtu.edu.cn/"),
    HomeFeature("mail","湘大邮箱","https://mail.smail.xtu.edu.cn/"),
    HomeFeature("devices","校园网自助服务系统","https://zz.xtu.edu.cn"),
    HomeFeature("portal","信息门户","https://portal2020.xtu.edu.cn/cas/login"),
    HomeFeature("website","新教务系统","https://jw.xtu.edu.cn/jwglxt/"),
    HomeFeature("portal","旧教务系统","https://jwxt.xtu.edu.cn/jsxsd/"))

@Composable internal fun HomePage(data:AppData,status:CourseStatus,navigate:(String)->Unit,refresh:()->Unit) {
    val colors=LocalGlassColors.current
    val context=LocalContext.current
    val listState=rememberLazyListState()
    val viewport=remember(listState){ListNavigationViewport(listState)}
    val fontScale=LocalGlasmioLayoutFontScale.current.coerceAtLeast(1f)
    val columns=if(LocalConfiguration.current.screenWidthDp-32>=264f*fontScale+37f)2 else 1
    val featureRows=remember(columns){homeFeatures.chunked(columns)}
    val courseAlpha=rememberCrestoReloadAlpha(data.loading&&data.reloadFromClick,data.reloadRevision)
    val open:(HomeFeature)->Unit={feature->feature.url?.let{context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse(it)))}?:navigate(feature.key)}
    GlasmioPinnedListPage("Xachet",bottomPadding=170.dp,listState=listState,modifier=Modifier.navigationViewport(viewport),subtitle=LocalDate.now().format(DateTimeFormatter.ofPattern("M月d日 EEEE"))) {
        item { HomeCourseCards(data,status,courseAlpha){navigate("classrooms")} }
        item { Text("快捷功能",style=IosTypography.title3.copy(fontWeight=androidx.compose.ui.text.font.FontWeight.SemiBold),modifier=Modifier.padding(top=20.dp,bottom=6.dp)) }
        item { HomeFeatureCard(campusNetworkFeature,Modifier.fillMaxWidth()){open(campusNetworkFeature)} }
        items(featureRows) { row -> Row(horizontalArrangement=Arrangement.spacedBy(13.dp)) {
            row.forEach { feature ->
                HomeFeatureCard(feature,Modifier.weight(1f)){open(feature)}
            }
            if(row.size<columns)Spacer(Modifier.weight(1f))
        } }
        item { Text("校园服务",style=IosTypography.title3.copy(fontWeight=androidx.compose.ui.text.font.FontWeight.SemiBold),modifier=Modifier.padding(top=20.dp,bottom=6.dp)) }
        item { GlasmioGroupedList(Modifier.clip(HomeCardShape)) {
            campusLinks.forEach{feature->GlasmioListRow(feature.title,minimumHeight=68.dp,leading={AppIconBadge(feature.key,compact=true)},onClick={open(feature)})}
        } }
        item { GlasmioButton(onClick=refresh,enabled=!data.loading,modifier=Modifier.fillMaxWidth()){
            if(data.loading) CircularProgressIndicator(Modifier.size(20.dp)) else Text("同步课程表")
        } }
    }
}

@Composable private fun HomeFeatureCard(feature:HomeFeature,modifier:Modifier=Modifier,onClick:()->Unit) {
    val colors=LocalGlassColors.current
    Row(modifier.pageOrigin(feature.key).heightIn(min=76.dp).background(colors.elevatedBackground,HomeCardShape).clip(HomeCardShape).clickable(onClick=onClick).padding(horizontal=12.dp,vertical=16.dp),verticalAlignment=Alignment.CenterVertically) {
        AppIconBadge(feature.key);Spacer(Modifier.width(10.dp))
        Text(feature.title,style=IosTypography.callout,modifier=Modifier.weight(1f))
    }
}

@Composable private fun HomeCourseCards(data:AppData,status:CourseStatus,courseAlpha:State<Float>,classrooms:()->Unit) {
    val colors=LocalGlassColors.current
    val fontScale=LocalGlasmioLayoutFontScale.current.coerceAtLeast(1f)
    Row(Modifier.fillMaxWidth().height((210f*fontScale).dp),horizontalArrangement=Arrangement.spacedBy(13.dp)) {
        Box(Modifier.weight(1f).fillMaxHeight().reloadFade(courseAlpha).background(colors.elevatedBackground,HomeCardShape).clip(HomeCardShape)) {
            androidx.compose.material3.Icon(
                if(status.current!=null||status.next!=null)androidx.compose.material.icons.Icons.Default.DirectionsRun else androidx.compose.material.icons.Icons.Default.CheckCircleOutline,
                null,Modifier.align(Alignment.BottomEnd).offset(20.dp,20.dp).size(126.dp),
                tint=appIconColor(if(status.current!=null||status.next!=null)"course_running" else "course_done").copy(alpha=.14f))
            Column(Modifier.padding(14.dp),verticalArrangement=Arrangement.spacedBy(4.dp)) {
                Text(if(status.current!=null)"正在上课" else "今日课程",style=IosTypography.footnote,color=colors.secondaryContent)
                Text(status.current?.course?.title?:if(!data.hasSchedule)"导入你的课表" else if(status.completed)"课程已完成" else if(status.next!=null)"课前准备" else "今日无课喵~",style=IosTypography.title2,maxLines=2,overflow=androidx.compose.ui.text.style.TextOverflow.Ellipsis)
                status.current?.let{lesson->
                    Text(lesson.course.place,style=IosTypography.subheadline,maxLines=2,overflow=androidx.compose.ui.text.style.TextOverflow.Ellipsis)
                    Text("${lesson.startTime()}–${lesson.endTime()}",style=IosTypography.footnote,color=colors.secondaryContent)
                    Countdown(lesson.end,prominent=true)
                }
            }
        }
        Column(Modifier.weight(1f).fillMaxHeight(),verticalArrangement=Arrangement.spacedBy(9.75.dp)) {
            Column(Modifier.weight(1.15f).fillMaxWidth().reloadFade(courseAlpha).background(colors.elevatedBackground,HomeCardShape).padding(start=12.dp,end=12.dp,top=14.dp,bottom=4.dp),verticalArrangement=Arrangement.spacedBy(2.dp)) {
                Text("下一节课",style=IosTypography.footnote,color=colors.secondaryContent)
                Text(status.next?.course?.title?:"暂无下一节课",style=IosTypography.headline,maxLines=2,overflow=androidx.compose.ui.text.style.TextOverflow.Ellipsis)
                status.next?.let{Text("${it.startTime()}–${it.endTime()}",style=IosTypography.footnote,color=colors.secondaryContent);Text(it.course.place,style=IosTypography.footnote,maxLines=1,overflow=androidx.compose.ui.text.style.TextOverflow.Ellipsis)}
            }
            HomeFeatureCard(classroomsFeature,Modifier.weight(.72f).fillMaxWidth(),classrooms)
        }
    }
}
@Composable internal fun ProfilePage(data:AppData,vm:SachetViewModel,navigate:(String)->Unit) {
    val context=LocalContext.current
    val listState=rememberLazyListState()
    val viewport=remember(listState){ListNavigationViewport(listState)}
    val accountAlpha=rememberCrestoReloadAlpha(revision=data.account.name to data.account.studentID)
    GlasmioPinnedListPage("我",bottomPadding=170.dp,listState=listState,modifier=Modifier.navigationViewport(viewport)) {
        item { GlasmioGroupedList {
            GlasmioListRow(data.account.name.ifBlank{"登录教务账号"},modifier=Modifier.pageOrigin("login",16.dp).reloadFade(accountAlpha),subtitle=data.account.studentID.ifBlank{"同步课程与教务信息"},leading={AppIconBadge("login")},onClick={navigate("login")})
            GlasmioListRow("后台运行与通知权限",modifier=Modifier.pageOrigin("permissions",16.dp),leading={AppIconBadge("permissions")},onClick={navigate("permissions")})
            GlasmioListRow("设置",modifier=Modifier.pageOrigin("settings",16.dp),leading={AppIconBadge("settings")},onClick={navigate("settings")})
            GlasmioListRow("课表外观",modifier=Modifier.pageOrigin("appearance",16.dp),leading={AppIconBadge("appearance")},onClick={navigate("appearance")})
            GlasmioListRow("导入与导出课表",modifier=Modifier.pageOrigin("files",16.dp),leading={AppIconBadge("files")},onClick={navigate("files")})
            GlasmioListRow("数据文件",modifier=Modifier.pageOrigin("fileManager",16.dp),leading={AppIconBadge("fileManager")},onClick={navigate("fileManager")})
            listOf(false to "添加桌面小组件",true to "添加横向小组件").forEach{(wide,title)->GlasmioListRow(title,leading={AppIconBadge("widget")},onClick={
                val manager=AppWidgetManager.getInstance(context)
                if(manager.isRequestPinAppWidgetSupported) manager.requestPinAppWidget(ComponentName(context,if(wide)CourseWidgetWideProvider::class.java else CourseWidgetProvider::class.java),null,null)
            })}
            if(data.account.cookie.isNotBlank()) GlasmioListRow("退出登录",leading={AppIconBadge("logout")},onClick={vm.logout()},titleColor=LocalGlassColors.current.destructive)
        } }
        item { GlasmioGroupedList {
            GlasmioListRow("Xachet",modifier=Modifier.pageOrigin("about",16.dp),subtitle="作者 Pluvist · 基于 Sachet 二次修改",leading={AppIconBadge("about")},onClick={navigate("about")})
            GlasmioListRow("开源致谢",subtitle="Sachet / MeiloX / Glasmio",leading={AppIconBadge("source")},onClick={context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://github.com/Pluvist/Xachet")))})
        } }
    }
}

@Composable internal fun LoginPage(data:AppData,vm:SachetViewModel,onWebLogin:(()->Unit)?=null,onDone:()->Unit) {
    var id by rememberSaveable{mutableStateOf(data.account.studentID)}
    var password by remember{mutableStateOf("")}
    var remember by rememberSaveable{mutableStateOf(true)}
    var cookieMode by rememberSaveable{mutableStateOf(false)}
    var cookie by remember{mutableStateOf("")}
    GlasmioPinnedListPage("登录教务账号",bottomPadding=180.dp,onNavigateBack=onDone) {
        item{Text("账号数据使用本机密钥加密保存，仅用于访问学校教务系统。",style=IosTypography.body,modifier=Modifier.padding(vertical=16.dp))}
        item{GlasmioGroupedList{
            if(cookieMode) GlasmioTextField(cookie,{cookie=it},placeholder="教务 Cookie",visualTransformation=PasswordVisualTransformation()) else {
            GlasmioTextField(id,{id=it},placeholder="学号",keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Number))
            GlasmioTextField(password,{password=it},placeholder="默认密码为 Xtu@身份证后六位",visualTransformation=PasswordVisualTransformation())
            GlasmioListRow("记住密码",trailing={GlasmioSwitch(checked=remember,onCheckedChange={remember=it})})
            }
            GlasmioListRow(if(cookieMode)"使用学号密码登录" else "使用 Cookie 登录",onClick={cookieMode=!cookieMode})
            onWebLogin?.let{GlasmioListRow("通过教务网页登录",modifier=Modifier.pageOrigin("webLogin",16.dp),onClick=it)}
        }}
        item{GlasmioButton(onClick={if(cookieMode)vm.cookieLogin(cookie,onDone) else vm.login(id,password,remember,onDone)},enabled=(if(cookieMode)cookie.isNotBlank() else id.isNotBlank()&&password.isNotBlank())&&!data.loading,modifier=Modifier.fillMaxWidth(),emphasis=GlassEmphasis.Prominent){
            if(data.loading) CircularProgressIndicator(Modifier.size(20.dp)) else Text("登录并同步")
        }}
    }
}

@Composable internal fun PermissionPage(back:()->Unit) {
    val context=LocalContext.current
    val status by rememberBackgroundSetupStatus()
    val live=status["live"] as? Map<*,*>
    val permission=androidx.activity.compose.rememberLauncherForActivityResult(androidx.activity.result.contract.ActivityResultContracts.RequestPermission()){}
    GlasmioPinnedListPage("后台与通知",bottomPadding=170.dp,onNavigateBack=back) {
        item{GlasmioGroupedList{
            listOf("notifications" to "通知权限","live" to "实时活动","battery" to "后台运行","autostart" to "自启动").forEach{(key,label)->
                val detail=if(status.isEmpty())"正在读取"else when(key){"notifications"->if(live?.get("notifications")==true)"已允许" else "未允许";"battery"->if(status["batteryUnrestricted"]==true)"无限制" else "受系统管理";"autostart"->"在系统页面确认";else->if(live?.get("promoted")==true)"已允许" else "在系统页面确认"}
                GlasmioListRow(label,detail=detail,onClick={
                    if(key=="notifications")permission.launch(android.Manifest.permission.POST_NOTIFICATIONS)
                    else if(key=="live")context.startActivity(Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(android.provider.Settings.EXTRA_APP_PACKAGE,context.packageName))
                    else BackgroundSetupSettings.open(context as android.app.Activity,key)
                })
            }
        }}
    }
}
