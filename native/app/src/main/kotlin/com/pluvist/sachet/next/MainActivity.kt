package com.pluvist.sachet.next

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.background
import androidx.compose.foundation.lazy.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionOnScreen
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import org.json.JSONObject
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.icons.*
import io.github.neoruaa.glasmio.scaffold.*
import io.github.neoruaa.glasmio.ui.*
import io.github.neoruaa.glasmio.glass.render.backdrops.rememberLayerBackdrop
import io.github.neoruaa.glasmio.glass.render.backdrops.rememberCanvasBackdrop
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import java.time.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState); enableEdgeToEdge()
        if(BuildConfig.BUILD_TYPE=="preview" && intent.getBooleanExtra("academic_probe",false)) {
            lifecycleScope.launch { AcademicDiagnostics.run(AcademicRepository(this@MainActivity)) }
        }
        setContent {
            val vm:SachetViewModel=viewModel()
            val benchmarkFixture=BuildConfig.APPLICATION_ID.endsWith(".benchmark")&&intent.getBooleanExtra("load_fixture",false)
            val benchmarkGuide=BuildConfig.APPLICATION_ID.endsWith(".benchmark")&&intent.getBooleanExtra("show_onboarding",false)
            LaunchedEffect(benchmarkFixture){if(benchmarkFixture)vm.loadBenchmarkFixture()}
            val data by vm.state.collectAsStateWithLifecycle()
            val settings=remember(data.settingsSnapshot){JSONObject(data.settingsSnapshot)}
            val dark=when(settings.optInt("themeMode")){1->false;2->true;else->isSystemInDarkTheme()}
            val configuredAccent=runCatching{Color(android.graphics.Color.parseColor(settings.optString("themeColor","#0088FF")))}.getOrDefault(Color(0xFF0088FF))
            // Resolve the existing default into a deeper light appearance without
            // changing saved custom colors or the established dark appearance.
            val accent=if(!dark&&configuredAccent==Color(0xFF0088FF))Color(0xFF0066CC)else configuredAccent
            SideEffect{androidx.core.view.WindowCompat.getInsetsController(window,window.decorView).apply {
                isAppearanceLightStatusBars=!dark;isAppearanceLightNavigationBars=!dark
            }}
            SachetTextEnvironment {
            GlasmioTheme(isDark=dark,colorScheme=glasmioColorScheme(dark,accent),typography=SachetTypography,letterSpacing=0.sp,
                appearance=GlassAppearance(blurRadiusMultiplier=3f,refractionAmountMultiplier=1.25f)) { GlasmioIconProvider(resolver=GlasmioIconResolver { name ->
            MaterialGlasmioIconResolver.resolve(if(name==SfSymbol.Layers.systemName) "calendar" else name)
        }) {
            // Isolated test entry only; replay the guide without clearing any saved app data.
            var onboarding by rememberSaveable{mutableStateOf<Boolean?>(if(benchmarkGuide)true else if(benchmarkFixture)false else null)}
            LaunchedEffect(data.loading){if(onboarding==null&&!data.loading)onboarding=!settings.optBoolean("hasReadDisclaimer")}
            Box(Modifier.fillMaxSize().background(LocalGlassColors.current.groupedBackground)) {
            if(onboarding!=null) CrestoPageLayer(onboarding==false){SachetApp(vm)}
            AnimatedVisibility(onboarding==true,enter=crestoEnter(),exit=crestoExit()) {
            GlasmioBackdropHost(Modifier.fillMaxSize(),sampledContent={
                Box(Modifier.fillMaxSize().background(LocalGlassColors.current.groupedBackground))
            },overlayContent={OnboardingPage(data,vm){onboarding=false}})
            }
            }
        } } } }
    }
}

@Composable
private fun SachetApp(vm:SachetViewModel=viewModel()) {
    val data by vm.state.collectAsStateWithLifecycle()
    var selected by rememberSaveable { mutableStateOf("home") }
    var detail by rememberSaveable { mutableStateOf<String?>(null) }
    val pageOrigins=remember{PageOrigins()}
    val academicSearch=remember{AcademicSearchController()}
    val focus=LocalFocusManager.current
    val keyboard=LocalSoftwareKeyboardController.current
    LaunchedEffect(detail){focus.clearFocus(force=true);keyboard?.hide()}
    val courseMorph=remember{CourseMorphController()}
    SideEffect{courseMorph.beforeOpen={focus.clearFocus(force=true);keyboard?.hide()}}
    var viewport by remember { mutableStateOf<BottomNavigationViewport?>(null) }
    val navigationScroll=rememberCourseNavigationScrollState(viewport,enabled=detail==null)
    // A single spring retargets from its current position/velocity when navigation is
    // interrupted. Detail-to-detail navigation keeps the accessory docked throughout.
    val accessoryDocking=animateFloatAsState(if(detail!=null)1f else 0f,
        spring(dampingRatio=.9f,stiffness=350f,visibilityThreshold=.001f),label="Course accessory docking")
    val statusChromeRequested=courseMorph.statusChromeRequested
    val statusDeparture=animateFloatAsState(if(statusChromeRequested)1f else 0f,
        spring(dampingRatio=.9f,stiffness=500f,visibilityThreshold=.001f),label="Status companion flight")
    val chromeDeparture=remember(accessoryDocking,statusDeparture){derivedStateOf{
        maxOf(accessoryDocking.value,statusDeparture.value).coerceIn(0f,1f)
    }}
    var scheduleMode by rememberSaveable{mutableIntStateOf(0)}
    val configuration=LocalConfiguration.current
    val landscape=configuration.screenWidthDp>configuration.screenHeightDp
    LaunchedEffect(selected,detail,scheduleMode,landscape){
        if(selected=="schedule"&&scheduleMode>0&&landscape&&detail==null)navigationScroll.compact()else navigationScroll.expand()
    }
    val tabs = remember { listOf(
        GlasmioTabItem("home", "主页", SfSymbol.House),
        GlasmioTabItem("schedule", "课程表", SfSymbol.Layers),
    ) }
    val semester=remember(data.courses,data.settingsSnapshot){vm.repository.semester()}
    val initialStatus=remember(data.courses,semester){CourseClock.status(data.courses,semester,Instant.now())}
    val status by produceState(initialStatus,data.courses,semester) {
        while(true) {
            value=CourseClock.status(data.courses,semester,Instant.now())
            val boundary=listOfNotNull(value.current?.end,value.next?.start).minOrNull()
            delay(boundary?.let{Duration.between(Instant.now(),it).toMillis().coerceIn(100,30_000)}?:30_000)
        }
    }
    BackHandler(detail!=null){detail=null}
    val navigate:(String)->Unit={if(!courseMorph.isBusy){if(it in setOf("home","schedule","profile")){selected=it;detail=null}else detail=it}}
    // Inner page controls sample an independent static plane. The bottom bar alone
    // samples the page plane; sampling that plane from its own children creates a
    // RenderNode cycle and a native stack overflow on Android's render thread.
    val canvasColor=LocalGlassColors.current.groupedBackground
    val staticBackdrop=rememberCanvasBackdrop{
        // Include the filter's padded sampling support, not just the control face.
        drawContext.canvas.nativeCanvas.drawColor(canvasColor.toArgb())
    }
    val edgeBackdrop=rememberLayerBackdrop()
    val morphThumbnail=rememberCourseThumbnailBackdrop()
    CompositionLocalProvider(LocalCourseMorph provides courseMorph) {
    Box(Modifier.fillMaxSize().onGloballyPositioned{courseMorph.rootScreenOrigin=it.positionOnScreen()}
        .academicSearchDismissGesture(academicSearch,detail)) {
    Box(Modifier.fillMaxSize()) {
    Box(Modifier.fillMaxSize().nestedScroll(navigationScroll.nestedScrollConnection)) {
    // A uniform canvas has no screen-space transform or image-filter dependency.
    // Inner page buttons retain the same opaque color during every window flight.
    GlasmioBackdropHost(Modifier.fillMaxSize(),sampledContent={
        // The glass must capture the same opaque canvas that is visible behind pages.
        // Retained page transitions expose transparent gaps before they settle; keep
        // those gaps out of the sampled scene as well as the visible canvas.
        Box(Modifier.fillMaxSize().graphicsLayer().glassBackdropSource(edgeBackdrop)
            .background(LocalGlassColors.current.groupedBackground)) {
        CompositionLocalProvider(LocalGlassBackdrop provides staticBackdrop,LocalBlurBackdrop provides staticBackdrop,LocalPageOrigins provides pageOrigins,LocalAcademicSearch provides academicSearch) {
        Box(Modifier.fillMaxSize()) {
        RetainedTabs(selected,detail==null) { destination ->
            CompositionLocalProvider(LocalMorphInteractive provides (destination==selected&&detail==null),LocalNavigationViewportBinding provides { if(destination==selected&&detail==null)viewport=it }) {
            when(destination) {
                "home" -> HomePage(data,status,navigate){vm.refresh(fromClick=true)}
                "schedule" -> SchedulePage(data.courses,semester,data.appearanceSnapshot,data.colors,
                    refreshing=data.loading&&data.reloadFromClick,refreshRevision=data.reloadRevision,
                    navigationProgress=navigationScroll.compactProgress,onModeChange={scheduleMode=it},
                    onRoutineChange={course,routine->vm.setRoutine(course,routine)},onScaleCommit={vm.setCardHeight(it)}){vm.refresh(fromClick=true)}
                "profile" -> ProfilePage(data,vm,navigate)
            }
            }
        }
        AnchoredPages(detail,pageOrigins) { destination ->
            when(destination) {
                "login" -> LoginPage(data,vm,onWebLogin={navigate("webLogin")}){detail=null}
                "webLogin" -> WebLoginPage(vm){detail=null}
                "permissions" -> PermissionPage{detail=null}
                "settings" -> SettingsPage(vm){detail=null}
                "appearance" -> AppearancePage(vm){detail=null}
                "files" -> DataPage(data,vm){detail=null}
                "fileManager" -> FileManagerPage(vm){detail=null}
                "about" -> AboutPage{detail=null}
                "transcript" -> TranscriptPage(vm.repository){detail=null}
                else -> QueryFeature.all.firstOrNull{it.key==destination}?.let { QueryPage(it,vm.repository){detail=null} }
            }
        }
        }
        }
        }
    },overlayContent={
        AcademicSearchScrim(academicSearch,detail)
        CompositionLocalProvider(LocalGlassAppearance provides LocalGlassAppearance.current.copy(blurRadiusMultiplier=4.5f,chromaticStrength=1f,refractionAmountMultiplier=2f)) {
        Box(Modifier.align(Alignment.BottomStart).fillMaxWidth().academicAccessoryImeLift(academicSearch,detail).navigationBarsPadding().padding(horizontal=20.dp).padding(bottom=8.dp).height(118.dp)
            .graphicsLayer()) {
            Box(Modifier.align(Alignment.BottomStart).widthIn(max=560.dp).fillMaxWidth().fillMaxHeight()) {
            AcademicAccessoryRow(navigationScroll.compactProgress,accessoryDocking,academicSearch,detail,statusDeparture,searchEnabled=!courseMorph.isBusy) {
            val title=status.current?.course?.title?:status.next?.course?.title?:if(status.completed)"课程已完成" else "今日无课喵~"
            val subtitle=status.current?.course?.place?:status.next?.let{"${it.startTime()} · ${it.course.place}"}.orEmpty()
            val titleStyle=IosTypography.headline.copy(lineHeight=20.sp,color=LocalGlassColors.current.content)
            val subtitleStyle=IosTypography.caption2.copy(lineHeight=14.sp,color=LocalGlassColors.current.content)
            val source=rememberCourseMorphSource("course-status",24f,eligible=academicSearch.session?.expanded!=true){CourseMorphContent.Status}
            GlassSurface(Modifier.fillMaxSize().morphSource(source).graphicsLayer{alpha=if(courseMorph.owns("course-status"))0f else 1f},shape=com.kyant.shapes.Capsule(),onClick={source?.open()}) {
                Row(Modifier.fillMaxWidth().padding(horizontal=16.dp),verticalAlignment=Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(title,Modifier.morphText(source,"title",title,titleStyle),style=titleStyle,maxLines=1,overflow=TextOverflow.Ellipsis)
                        if(subtitle.isNotBlank())Text(subtitle,Modifier.morphText(source,"subtitle",subtitle,subtitleStyle),style=subtitleStyle,maxLines=1,overflow=TextOverflow.Ellipsis)
                    }
                    Spacer(Modifier.width(8.dp))
                    status.current?.let { dated->Countdown(dated.end,Modifier.morphText(source,"countdown","",IosTypography.headline.copy(color=LocalGlassColors.current.content,fontWeight=androidx.compose.ui.text.font.FontWeight.SemiBold),provider={CourseTimeline.countdown(Duration.between(Instant.now(),dated.end).toMillis().coerceAtLeast(0))})) }
                }
            }
            }
            }
            NavigationChromeSlot(detail==null&&!statusChromeRequested,chromeDeparture,Modifier.align(Alignment.BottomStart)) {
            GlasmioNavigationBarWithTrailingItem(tabs,GlasmioTabItem("profile","我",SfSymbol.PersonFilled),
                selectedKey=selected,onSelected={if(detail==null&&!courseMorph.isBusy){selected=it;navigationScroll.expand()}},onExpand=navigationScroll::expand,compactProgress=navigationScroll.compactProgress,
                mainMaxWidth=200.dp,visibilityProgress=chromeDeparture,modifier=Modifier.fillMaxWidth())
            }
        }
        }
        data.message?.let { message -> GlassSurface(Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(12.dp),onClick=vm::dismissMessage) {
            Text(message,Modifier.padding(16.dp),color=LocalGlassColors.current.destructive,style=IosTypography.body)
        } }
    })
    }
    }
    CourseThumbnailCapture(courseMorph,morphThumbnail,edgeBackdrop,canvasColor)
    CourseMorphHost(courseMorph,morphThumbnail,status){course,routine->vm.setRoutine(course,routine)}
    }
    }
}

/** Retain source layers and reserve fade-layer support beyond the complete flight path. */
@Composable private fun NavigationChromeSlot(visible:Boolean,progress:State<Float>,modifier:Modifier=Modifier,content:@Composable ()->Unit) {
    Layout(content={
        Layout(content=content,modifier=Modifier.graphicsLayer {
            alpha=1f-progress.value.coerceIn(0f,1f)
            // Fade the completed glass as a group. Per-command modulation changes
            // backdrop-relative blending and exposes the material capture boundary.
            clip=false
        }) { measurables,constraints ->
            val x=24.dp.roundToPx();val y=48.dp.roundToPx()
            val child=measurables.single().measure(constraints.offset(-2*x,-2*y))
            layout(child.width+2*x,child.height+2*y){child.placeRelative(x,y)}
        }
    },modifier=modifier.then(if(visible)Modifier else Modifier.clearAndSetSemantics {})) { measurables,constraints ->
        // The host has 20dp horizontal screen margins. A 24dp guard keeps the
        // fade raster beyond the physical screen, without allocating hundreds of
        // invisible pixels for the portions of a capsule that have already exited.
        val x=24.dp.roundToPx();val y=48.dp.roundToPx()
        val child=measurables.single().measure(constraints.offset(2*x,2*y))
        layout(child.width-2*x,child.height-2*y) {
            // Keep composition/optics alive, but remove hidden controls from hit testing.
            if(visible||progress.value<.999f)child.placeRelative(-x,-y)
        }
    }
}

@Composable private fun RetainedTabs(selected:String,visible:Boolean,content:@Composable (String)->Unit) {
    val mounted=remember{mutableStateListOf(selected)}
    LaunchedEffect(Unit){
        for(key in listOf("home","schedule","profile")) {
            delay(250)
            if(key !in mounted)mounted.add(key)
        }
    }
    SideEffect{if(selected !in mounted)mounted.add(selected)}
    for(destination in (mounted.toList()+selected).distinct()) key(destination) {
        CrestoPageLayer(visible&&destination==selected) { content(destination) }
    }
}

@Composable internal fun Countdown(end:Instant,modifier:Modifier=Modifier,prominent:Boolean=false) {
    val remaining by produceState(Duration.between(Instant.now(),end).toMillis().coerceAtLeast(0),end) {
        while(true){value=Duration.between(Instant.now(),end).toMillis().coerceAtLeast(0);delay(1000)}
    }
    Text(CourseTimeline.countdown(remaining),modifier,style=(if(prominent)IosTypography.title1 else IosTypography.headline).copy(fontFeatureSettings="tnum",fontWeight=androidx.compose.ui.text.font.FontWeight.SemiBold))
}
