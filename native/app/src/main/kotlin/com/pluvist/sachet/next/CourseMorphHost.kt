package com.pluvist.sachet.next

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.semantics.clearAndSetSemantics
import kotlinx.coroutines.delay
import androidx.compose.ui.geometry.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.graphics.layer.GraphicsLayer
import androidx.compose.ui.graphics.layer.drawLayer
import kotlin.math.ceil
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.*
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.*
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.glass.render.backdrops.rememberLayerBackdrop
import io.github.neoruaa.glasmio.icons.*
import io.github.neoruaa.glasmio.ui.*
import java.time.*

private class MorphCornerSize(val progress:State<Float>,val from:Float):androidx.compose.foundation.shape.CornerSize {
    override fun toPx(shapeSize:Size,density:Density):Float=with(density){(from+(NavigationBarSurfaceHeight.value/2f-from)*progress.value.coerceIn(0f,1f)).dp.toPx()}
}
internal fun courseMorphShape(progress:State<Float>,from:Float):Shape {
    val corner=MorphCornerSize(progress,from)
    return G2RoundedRectangle(corner,corner,corner,corner)
}
private data class MorphHeader(val id:String,val text:String,val style:TextStyle,val bounds:Rect,val layout:TextLayoutResult)
private class MorphHeaderLayers(val source:GraphicsLayer,val target:GraphicsLayer) {
    var sourceLayout:TextLayoutResult?=null
    var targetLayout:TextLayoutResult?=null
    var sourceScale=0f
}


@Composable internal fun CourseMorphHost(controller:CourseMorphController,thumbnail:CourseThumbnailBackdrop,status:CourseStatus,onRoutineChange:(Course,String)->Unit) {
    LaunchedEffect(controller.revision) {
        val existing=controller.flight
        if(existing!=null && controller.intents.desiredKey!=existing.source.key) {
            existing.returning=true
            controller.refreshedSource(existing.source.key)?.let{existing.source=it}
            val replacing=controller.desired!=null
            existing.progress.animateTo(0f,CourseMorphMotion.close(existing.request.content,replacing),initialVelocity=existing.resumeVelocity)
            if(controller.flight===existing)controller.flight=null
        }
        controller.desired?.let{request->
            // Status expansion and companion departure observe the same accepted
            // request and start together; neither animation waits for the other.
            // The GPU thumbnail is recorded in the same draw frame; animation
            // starts immediately without a bitmap readback/preparation barrier.
            val prepared=if(request.content==CourseMorphContent.Status)
                request.copy(snapshot=controller.refreshedSource(request.snapshot.key)?:request.snapshot)else request
            val flight=controller.flight?:CourseMorphFlight(prepared).also{
                it.captureEpoch=controller.cacheEpoch
                controller.flight=it
            }
            controller.retargeting=false
            flight.returning=false
            flight.progress.animateTo(1f,CourseMorphMotion.open(flight.request.content),initialVelocity=flight.resumeVelocity)
        }
    }
    val active=controller.flight
    if(active==null&&controller.desired!=null) {
        val source=controller.desired!!.snapshot.bounds
        BackHandler{controller.dismiss()}
        Box(Modifier.fillMaxSize().pointerInput(controller,source){detectTapGestures{position->
            if(controller.retargeting)controller.animationTap(position)else if(!source.contains(position))controller.dismiss()
        }})
    }
    var retained by remember{mutableStateOf<CourseMorphFlight?>(null)}
    SideEffect{if(active!=null)retained=active}
    val flight=active?:retained?:return
    val visible=active!=null
    BackHandler(visible){controller.dismiss()}
    val colors=LocalGlassColors.current
    val density=LocalDensity.current
    val measurer=rememberTextMeasurer(cacheSize=48)
    val clock by produceState(Instant.now(),status.current?.end,visible){if(visible&&status.current!=null)while(true){value=Instant.now();delay(1000)}}
    val progress=remember(flight){derivedStateOf{flight.progress.value}}
    BoxWithConstraints(Modifier.fillMaxSize().layout{node,c->
        val child=node.measure(c)
        layout(child.width,child.height){if(visible)child.place(0,0)}
    }) {
        val rootWidth=constraints.maxWidth.toFloat();val rootHeight=constraints.maxHeight.toFloat()
        val top=WindowInsets.statusBars.getTop(density).toFloat()
        val bottom=WindowInsets.navigationBars.getBottom(density).toFloat()
        val lower=flight.request.content==CourseMorphContent.Status
        val emptyPanel=if(lower)status.today.isEmpty() else (flight.request.content as? CourseMorphContent.Day)?.lessons?.isEmpty()==true
        val target=remember(rootWidth,rootHeight,top,bottom,lower,emptyPanel,density){coursePanelTarget(rootWidth,rootHeight,top,bottom,lower,emptyPanel,density)}
        val livePanelBackdrop=rememberLayerBackdrop()
        val panelBackdrop=livePanelBackdrop
        val content=flight.updatedCourse?.let{CourseMorphContent.Lesson(it)}?:flight.request.content
        val targetValues=when(content) {
            CourseMorphContent.Status->listOf(
                "title" to (status.current?.course?.title?:status.next?.course?.title?:if(status.completed)"课程已完成"else"今日无课喵~"),
                "subtitle" to (status.current?.course?.place?:status.next?.let{"${it.startTime()} · ${it.course.place}"}.orEmpty()),
                "countdown" to status.current?.let{CourseTimeline.countdown(Duration.between(clock,it.end).toMillis().coerceAtLeast(0))}.orEmpty())
            is CourseMorphContent.Lesson->listOf("title" to content.course.title,"place" to content.course.place,"teacher" to content.course.teacher)
            is CourseMorphContent.Day->listOf("title" to "${content.date.monthValue}月${content.date.dayOfMonth}日课程")
        }.filter{it.second.isNotBlank()}
        val titleStyle=IosTypography.title1
        val teacherStyle=IosTypography.footnote
        val countdownStyle=IosTypography.title2.copy(fontFeatureSettings="tnum")
        val subtitleStyle=IosTypography.body
        val headers=remember(targetValues,target,colors.content,density,titleStyle,teacherStyle,subtitleStyle,countdownStyle){with(density){
            var y=target.top+26.dp.toPx()
            targetValues.map{(id,text)->
                val style=(if(id=="title")titleStyle else if(id=="teacher")teacherStyle else if(id=="countdown")countdownStyle else subtitleStyle).copy(color=colors.content)
                val width=(target.width-48.dp.toPx()-if(id=="title")32.dp.toPx()else 0f).toInt().coerceAtLeast(1)
                val layout=measurer.measure(text,style,overflow=TextOverflow.Ellipsis,maxLines=if(id=="title")3 else 2,constraints=Constraints(maxWidth=width))
                MorphHeader(id,text,style,Rect(Offset(target.left+24.dp.toPx(),y),layout.size.toSize()),layout).also{y+=layout.size.height+8.dp.toPx()}
            }
        }}
        val headerBottom=(headers.lastOrNull()?.bounds?.bottom?:target.top)-target.top+with(density){12.dp.toPx()}
        val detailsInteractive by remember(flight){derivedStateOf{progress.value>.82f&&!flight.returning}}
        val shape=remember(flight.source.radiusDp,progress){
            courseMorphShape(progress,flight.source.radiusDp)
        }
        fun rect()=CourseMorphGeometry.frame(flight.source.bounds,target,progress.value,with(density){36.dp.toPx()})
        Box(Modifier.fillMaxSize().pointerInput(controller,flight,target){
            awaitEachGesture {
                val down=awaitFirstDown(requireUnconsumed=false,pass=PointerEventPass.Initial)
                // Decide once at DOWN. An opening/open panel cannot turn this
                // same tap into another open after its dismissal starts.
                val allowRetarget=flight.returning
                val intercept=allowRetarget||!rect().contains(down.position)
                if(intercept)down.consume()
                var moved=false
                do {
                    val event=awaitPointerEvent(PointerEventPass.Initial)
                    if(event.changes.any{(it.position-down.position).getDistance()>viewConfiguration.touchSlop})moved=true
                    if(intercept)event.changes.forEach{it.consume()}
                }while(event.changes.any{it.pressed})
                if(intercept&&!moved) {
                    if(allowRetarget)controller.animationTap(down.position)else controller.outsideTap()
                }
            }
        }) {
        Box(Modifier.fillMaxSize().drawBehind{drawRect(Color.Black.copy(alpha=(if(colors.isDark).22f else .17f)*CourseMorphGeometry.smooth(progress.value)))})
        val panelContent:@Composable BoxScope.()->Unit = {
                CompositionLocalProvider(LocalGlassBackdrop provides panelBackdrop,LocalBlurBackdrop provides panelBackdrop,LocalCourseMorph provides controller,LocalMorphInteractive provides detailsInteractive) {
                    Layout(modifier=Modifier.graphicsLayer{clip=true;this.shape=RectangleShape}.then(if(detailsInteractive)Modifier else Modifier.clearAndSetSemantics{}),content={
                        Column(Modifier.fillMaxSize().graphicsLayer{alpha=CourseMorphGeometry.smooth((progress.value-.58f)/.42f)}
                            .padding(top=with(density){headerBottom.toDp()}).verticalScroll(rememberScrollState(),enabled=detailsInteractive).padding(start=24.dp,end=24.dp,bottom=24.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
                            when(content) {
                                CourseMorphContent.Status->{
                                    status.current?.let{dated->
                                        Text("正在上课 · ${dated.startTime()}–${dated.endTime()}",style=IosTypography.body)
                                        Text("下课倒计时",style=IosTypography.footnote)
                                    }
                                    status.next?.let{Text("下一节：${it.course.title}\n${it.startTime()}–${it.endTime()} · ${it.course.place}",style=IosTypography.body)}
                                    if(status.today.isEmpty())Text("今天没有课程，休息一下喵~",style=IosTypography.body)
                                    if(status.completed)Text("今天的课程已经全部完成",style=IosTypography.body)
                                    status.today.forEach{dated->MorphLessonRow(dated){flight.updatedCourse=it}}
                                }
                                is CourseMorphContent.Lesson->{
                                    val course=content.course
                                    Text("${course.interval().first}–${course.interval().second} · 第${course.first}–${course.last}节",style=IosTypography.body)
                                    Text("星期"+listOf("一","二","三","四","五","六","日")[course.weekday-1],style=IosTypography.body)
                                    Text("周次：${course.weeks.sorted().joinToString("、")}",style=IosTypography.footnote)
                                    Text(if(course.staggered)"错峰作息"else"普通作息",style=IosTypography.body,color=colors.accent)
                                    GlasmioListRow("作息安排",detail=when(course.routine){"normal"->"普通";"staggered"->"错峰";else->"按教学楼自动识别"},onClick=if(detailsInteractive){{
                                        val routine=when(course.routine){"auto"->"normal";"normal"->"staggered";else->"auto"}
                                        flight.updatedCourse=course.copy(routine=routine);onRoutineChange(course,routine)
                                    }}else null)
                                }
                                is CourseMorphContent.Day->{
                                    if(content.lessons.isEmpty())Text("当日无课喵~",style=IosTypography.body)
                                    content.lessons.forEach{MorphLessonRow(it){course->flight.updatedCourse=course}}
                                }
                            }
                        }
                    }){nodes,_->
                        val child=nodes.single().measure(Constraints.fixed(target.width.toInt(),target.height.toInt()))
                        val frame=rect()
                        layout(frame.width.toInt().coerceAtLeast(1),frame.height.toInt().coerceAtLeast(1)){
                            child.place((target.left-frame.left).toInt(),(target.top-frame.top).toInt())
                        }
                    }
                }
        }
        val appearance=LocalGlassAppearance.current.copy(blurRadiusMultiplier=2f,refractionAmountMultiplier=1.5f)
        Layout(content={
            CompositionLocalProvider(LocalGlassAppearance provides appearance) {
                // Frost is prefiltered over the entire window thumbnail once.
                // Do not crop/reblur it in the moving control's local coordinates.
                GlassSurface(Modifier.fillMaxSize().clickable(interactionSource=remember{MutableInteractionSource()},indication=null){},
                    backdrop=thumbnail,shape=shape,frostRadius=0.dp,
                    exportedBackdrop=livePanelBackdrop,style=GlassSurfaceStyle.Navigation) {
                    Box(Modifier.fillMaxSize().drawWithContent {
                        drawRect(flight.source.fill.copy(alpha=flight.source.fill.alpha*(1f-CourseMorphGeometry.smooth(progress.value*1.5f))))
                        drawContent()
                        val stroke=flight.source.stroke
                        if(stroke.alpha>0f)drawOutline(shape.createOutline(size,layoutDirection,this),
                            stroke.copy(alpha=stroke.alpha*(1f-CourseMorphGeometry.smooth(progress.value))),style=Stroke(1.dp.toPx()))
                    },content=panelContent)
                }
            }
        },modifier=Modifier.fillMaxSize()) {nodes,_->
            val frame=rect()
            val child=nodes.single().measure(Constraints.fixed(frame.width.toInt().coerceAtLeast(1),frame.height.toInt().coerceAtLeast(1)))
            layout(rootWidth.toInt(),rootHeight.toInt()){child.place(frame.left.toInt(),frame.top.toInt())}
        }
        val sourceLayouts=remember(flight.source,headers){flight.source.texts.associate{source->source.id to (measurer.measure(source.value,source.style,
            overflow=TextOverflow.Ellipsis,maxLines=source.lines,constraints=Constraints(maxWidth=source.bounds.width.toInt().coerceAtLeast(1),maxHeight=source.bounds.height.toInt().coerceAtLeast(1))))}}
        val textLayers=headers.associate{header->header.id to key(header.id){
            val sourceLayer=rememberGraphicsLayer()
            val targetLayer=rememberGraphicsLayer()
            remember(sourceLayer,targetLayer){MorphHeaderLayers(sourceLayer,targetLayer)}
        }}
        Canvas(Modifier.fillMaxSize()) {
            val p=progress.value.coerceIn(-.02f,1.055f);val frame=rect()
            clipRect(frame.left,frame.top,frame.right,frame.bottom){
                headers.forEach{header->
                    val source=flight.source.texts.firstOrNull{it.id==header.id}
                    if(source==null){drawText(header.layout,alpha=CourseMorphGeometry.smooth((p-.55f)/.45f),topLeft=header.bounds.topLeft)}
                    else {
                        val position=CourseMorphGeometry.curve(source.bounds.topLeft,header.bounds.topLeft,p,36.dp.toPx())
                        val fromSize=source.style.fontSize.value.takeIf{it.isFinite()&&it>0}?:14f
                        val ratio=header.style.fontSize.value/fromSize
                        val factor=1f+(ratio-1f)*p
                        val cross=CourseMorphGeometry.smooth((p-.48f)/.45f)
                        val color=androidx.compose.ui.graphics.lerp(source.style.color.takeOrElse{colors.content},colors.content,p.coerceIn(0f,1f))
                        val layers=textLayers.getValue(header.id)
                        val sourceLayout=sourceLayouts.getValue(header.id)
                        val maximumScale=maxOf(1f,ratio)
                        if(layers.sourceLayout!==sourceLayout || layers.sourceScale!=maximumScale) {
                            layers.source.compositingStrategy=androidx.compose.ui.graphics.layer.CompositingStrategy.Offscreen
                            layers.source.record(this,layoutDirection,IntSize(ceil(sourceLayout.size.width*maximumScale).toInt().coerceAtLeast(1),ceil(sourceLayout.size.height*maximumScale).toInt().coerceAtLeast(1))){
                                scale(maximumScale,maximumScale,Offset.Zero){drawText(sourceLayout,color=Color.White)}
                            }
                            layers.sourceLayout=sourceLayout;layers.sourceScale=maximumScale
                        }
                        if(layers.targetLayout!==header.layout) {
                            layers.target.compositingStrategy=androidx.compose.ui.graphics.layer.CompositingStrategy.Offscreen
                            layers.target.record(this,layoutDirection,header.layout.size){drawText(header.layout,color=Color.White)}
                            layers.targetLayout=header.layout
                        }
                        val tint=ColorFilter.tint(color,BlendMode.SrcIn)
                        if(cross<1f) {
                            layers.source.alpha=1f-cross;layers.source.colorFilter=tint
                            withTransform({translate(position.x,position.y);scale(factor/maximumScale,factor/maximumScale,Offset.Zero)}){drawLayer(layers.source)}
                        }
                        if(cross>0f) {
                            layers.target.alpha=cross;layers.target.colorFilter=tint
                            withTransform({translate(position.x,position.y);scale(factor/ratio,factor/ratio,Offset.Zero)}){drawLayer(layers.target)}
                        }
                    }
                }
            }
        }
        val reveal by remember(flight){derivedStateOf{progress.value>.78f}}
        if(reveal)Box(Modifier.offset{IntOffset(target.left.toInt(),target.top.toInt())}.width(with(density){target.width.toDp()})
            .height(with(density){headerBottom.toDp()}).semantics{contentDescription=headers.joinToString("，"){it.text}})
        if(reveal)Box(Modifier.offset{IntOffset((target.right-52.dp.toPx()).toInt(),(target.top+16.dp.toPx()).toInt())}.size(36.dp)
            .graphicsLayer{alpha=CourseMorphGeometry.smooth((progress.value-.7f)/.3f)}) {
            // Match MeiloX's regular sampled toolbar material. This explicit
            // backdrop remains necessary because the modal is outside the page host.
            GlasmioIconButton(onClick=controller::dismiss,backdrop=panelBackdrop,
                modifier=Modifier.fillMaxSize()) {SfIcon("xmark","关闭课程面板",tint=colors.content,size=18.dp)}
        }
        }

    }
}

@Composable private fun MorphLessonRow(dated:DatedCourse,onSelect:(Course)->Unit) {
    val colors=LocalGlassColors.current
    val style=IosTypography.headline.copy(color=colors.content)
    Column(Modifier.fillMaxWidth().clickable(enabled=LocalMorphInteractive.current){onSelect(dated.course)}.padding(vertical=10.dp),verticalArrangement=Arrangement.spacedBy(4.dp)) {
        Text(dated.course.title,style=style)
        Text("${dated.startTime()}–${dated.endTime()} · ${dated.course.place}",style=IosTypography.footnote)
    }
}
