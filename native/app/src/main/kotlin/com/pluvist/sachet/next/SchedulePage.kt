package com.pluvist.sachet.next

import androidx.compose.foundation.background
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.pager.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.drawText
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.toSize
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.icons.*
import io.github.neoruaa.glasmio.scaffold.*
import io.github.neoruaa.glasmio.ui.*
import java.time.*
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

@Composable internal fun SchedulePage(courses:List<Course>,semester:LocalDate,appearanceJson:String,courseColors:Map<String,String>,refreshing:Boolean=false,refreshRevision:Int=0,navigationProgress:State<Float>,onModeChange:(Int)->Unit,onRoutineChange:(Course,String)->Unit,onScaleCommit:(Float)->Unit,refresh:()->Unit) {
    val reloadAlpha=rememberCrestoReloadAlpha(refreshing,refreshRevision)
    val appearance=remember(appearanceJson){org.json.JSONObject(appearanceJson)}
    val weekIndex=remember(courses){WeekCourseIndex(courses)}
    val textDefaults=IosTypography.body
    val cardStyle=remember(appearanceJson,courseColors,courses,textDefaults){WeekCardStyle(appearance,courseColors,courses,textDefaults)}
    val courseTextMeasurer=rememberTextMeasurer(cacheSize=256)
    val normalAxis=rememberTimeAxisPaints(false)
    val staggeredAxis=rememberTimeAxisPaints(true)
    val dateHeader=rememberWeekHeaderPaints(courseTextMeasurer)
    var cardHeight by remember(appearanceJson){mutableFloatStateOf(appearance.optDouble("cardHeight",60.0).toFloat())}
    val scale=(cardHeight/45f*1.18f*LocalGlasmioLayoutFontScale.current.coerceIn(1f,1.5f)).coerceIn(.5f,11.85f)
    var mode by rememberSaveable{mutableStateOf(0)}
    LaunchedEffect(mode){onModeChange(mode)}
    val landscape=LocalConfiguration.current.screenWidthDp>LocalConfiguration.current.screenHeightDp
    val currentWeek=CourseClock.week(LocalDate.now(),semester).coerceIn(1,60)
    val weeksPerPage=if(landscape)2 else 1
    val weeks=rememberPagerState(initialPage=(currentWeek-1)/weeksPerPage,pageCount={60/weeksPerPage})
    val monthStart=YearMonth.from(semester)
    val monthPage=rememberPagerState(initialPage=(ChronoUnit.MONTHS.between(monthStart,YearMonth.now()).toInt().coerceIn(0,11))/(if(landscape)1 else 2),pageCount={if(landscape)12 else 6})
    val monthViewport=remember(monthPage){PagerNavigationViewport(monthPage)}
    val overviewState=rememberLazyGridState()
    val overviewColumns=if(landscape)3 else 2
    val overviewViewport=remember(overviewState,overviewColumns){GridNavigationViewport(overviewState,overviewColumns)}
    val navigationBottom=WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    val compactChrome by remember(navigationProgress){derivedStateOf{navigationProgress.value>.5f}}
    val fontScale=LocalGlasmioLayoutFontScale.current.coerceAtLeast(1f)
    val chromePadding=remember(navigationProgress,navigationBottom){object:PaddingValues {
        override fun calculateLeftPadding(layoutDirection:androidx.compose.ui.unit.LayoutDirection)=0.dp
        override fun calculateRightPadding(layoutDirection:androidx.compose.ui.unit.LayoutDirection)=0.dp
        override fun calculateTopPadding()=0.dp
        override fun calculateBottomPadding()=navigationBottom+(126f-56f*navigationProgress.value.coerceIn(0f,1f)).dp
    }}
    val monthsPerPage=if(landscape)1 else 2
    var previousMonthsPerPage by remember{mutableIntStateOf(monthsPerPage)}
    LaunchedEffect(monthsPerPage){if(previousMonthsPerPage!=monthsPerPage){monthPage.scrollToPage((monthPage.currentPage*previousMonthsPerPage/monthsPerPage).coerceIn(0,12/monthsPerPage-1));previousMonthsPerPage=monthsPerPage}}
    var previousWeeksPerPage by remember{mutableIntStateOf(weeksPerPage)}
    LaunchedEffect(weeksPerPage){if(previousWeeksPerPage!=weeksPerPage){weeks.scrollToPage((weeks.currentPage*previousWeeksPerPage/weeksPerPage).coerceIn(0,60/weeksPerPage-1));previousWeeksPerPage=weeksPerPage}}
    GlasmioPinnedPage(if(mode==0)"第${weeks.currentPage*weeksPerPage+1}周" else "课程表",bottomPadding=155.dp,
        topBarBlurProgress=if(mode==0)0f else 1f,
        modifier=Modifier.pointerInput(appearanceJson){awaitEachGesture {
            awaitFirstDown(requireUnconsumed=false)
            var changed=false
            do {
                val event=awaitPointerEvent()
                if(event.changes.count{it.pressed}>=2){
                    val zoom=event.calculateZoom()
                    if(zoom!=1f){cardHeight=(cardHeight*zoom).coerceIn(24f,300f);event.changes.forEach{it.consume()};changed=true}
                }
            }while(event.changes.any{it.pressed})
            if(changed)onScaleCommit(cardHeight)
        }},actions={
        GlasmioButton(onClick={mode=(mode+1)%3}){SfIcon(SfSymbol.Layers,"切换周、月、学期视图")}
        GlasmioButton(onClick=refresh){SfIcon(SfSymbol.ArrowClockwise,"同步课表")}
    }) { padding ->
        BoxWithConstraints(Modifier.fillMaxSize().padding(horizontal=if(mode==0)6.dp else 12.dp)) {
            val semesterRows=(6+overviewColumns-1)/overviewColumns
            val availableHeight=maxHeight-padding.calculateTopPadding()-navigationBottom-(if(compactChrome)70.dp else 126.dp)
            val semesterCellHeight=((availableHeight-10.dp*(semesterRows-1))/semesterRows-58.dp)/6
            when(mode) {
                0->HorizontalPager(weeks,key={"week-$it-$weeksPerPage"},beyondViewportPageCount=1,modifier=Modifier.fillMaxSize().padding(top=padding.calculateTopPadding())) { page ->
                    Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
                        repeat(weeksPerPage){position->
                            val week=page*weeksPerPage+position+1
                            WeekGrid(weekIndex[week],semester,week,cardStyle,courseTextMeasurer,normalAxis,staggeredAxis,dateHeader,scale,page==weeks.currentPage,reloadAlpha,Modifier.weight(1f).graphicsLayer()){}
                        }
                    }
                }
                1->if(landscape) HorizontalPager(monthPage,modifier=Modifier.fillMaxSize()){page->
                    MonthGrid(courses,semester,monthStart.plusMonths(page.toLong()),Modifier.fillMaxSize().padding(top=padding.calculateTopPadding()).padding(chromePadding).reloadFade(reloadAlpha),fitHeight=true,compact=true,onDay={})
                } else VerticalPager(monthPage,modifier=Modifier.fillMaxSize().navigationViewport(monthViewport)){page->
                    Column(Modifier.fillMaxSize().padding(top=padding.calculateTopPadding()).padding(chromePadding)) { repeat(2){MonthGrid(courses,semester,monthStart.plusMonths((page*2+it).toLong()),Modifier.weight(1f).reloadFade(reloadAlpha),fitHeight=true,onDay={})} }
                }
                else->LazyVerticalGrid(columns=GridCells.Fixed(overviewColumns),state=overviewState,modifier=Modifier.fillMaxSize().navigationViewport(overviewViewport),contentPadding=object:PaddingValues by chromePadding{override fun calculateTopPadding()=padding.calculateTopPadding()},verticalArrangement=Arrangement.spacedBy(10.dp),horizontalArrangement=Arrangement.spacedBy(10.dp)) {
                    items(6,key={"semester-$it"}){MonthGrid(courses,semester,monthStart.plusMonths(it.toLong()),modifier=Modifier.reloadFade(reloadAlpha),cellHeight=semesterCellHeight.coerceIn((16f*fontScale).dp,32.dp.coerceAtLeast((16f*fontScale).dp)),compact=true,onDay={})}
                }
            }
            if(refreshing)Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center){androidx.compose.material3.CircularProgressIndicator()}
        }
    }
}

@Composable private fun WeekGrid(page:WeekCoursePage,semester:LocalDate,week:Int,style:WeekCardStyle,textMeasurer:TextMeasurer,normalAxis:TimeAxisPaints,staggeredAxis:TimeAxisPaints,dateHeader:WeekHeaderPaints,scale:Float,active:Boolean,reloadAlpha:State<Float>,modifier:Modifier=Modifier,onCourse:(Course)->Unit) {
    val colors=LocalGlassColors.current
    val interactive=LocalMorphInteractive.current
    val scroll=rememberScrollState()
    val viewport=remember(scroll){ScrollNavigationViewport(scroll)}
    val date=semester.plusWeeks((week-1).toLong())
    val fontScale=LocalGlasmioLayoutFontScale.current
    val axisWidth=(34f*fontScale.coerceIn(1f,1.5f)).dp
    val daysScroll=rememberScrollState()
    BoxWithConstraints(modifier) {
    val dayWidth=((maxWidth-axisWidth*2)/7).coerceAtLeast(if(fontScale>=1.2f)(48f*fontScale).dp else 0.dp)
    // Glass consumers replay this viewport many times while their bounds move.
    // Retain the clipped timetable as GPU pixels instead of replaying every
    // course glyph and axis label for every material sample. Scrolling/data/theme
    // invalidation still redraw the viewport normally; no blur is pre-rendered.
    Column(Modifier.fillMaxSize().graphicsLayer{
        compositingStrategy=androidx.compose.ui.graphics.CompositingStrategy.Offscreen
    }) {
        Text("第${week}周"+if(fontScale>=1.2f)" · 左右滑动查看日期"else "",style=IosTypography.footnote,color=colors.secondaryContent)
        Row(Modifier.fillMaxWidth()) {
            Spacer(Modifier.width(axisWidth))
            Row(Modifier.weight(1f).horizontalScroll(daysScroll,enabled=fontScale>=1.2f)) {
                WeekDateHeader(date,dayWidth,dateHeader)
            }
            Spacer(Modifier.width(axisWidth))
        }
        // Switching the active page must not replace the nested-scroll node under
        // a live pointer/fling; only its viewport ownership changes.
        Row(Modifier.fillMaxSize().navigationViewport(viewport,active).verticalScroll(scroll).padding(top=8.dp,bottom=180.dp)) {
            TimeAxis(false,scale,normalAxis)
            Row(Modifier.weight(1f).horizontalScroll(daysScroll,enabled=fontScale>=1.2f)) {
            repeat(7){day->Box(Modifier.width(dayWidth).height((740*scale).dp)) {
                Canvas(Modifier.fillMaxSize()) {
                    (1..11).forEach{section->
                        val y=(axisMinute(LessonTimes.start(section,false))*scale).dp.toPx()
                        drawLine(colors.separator.copy(alpha=.45f),androidx.compose.ui.geometry.Offset(0f,y),androidx.compose.ui.geometry.Offset(size.width,y),.4.dp.toPx())
                    }
                    listOf(2,4,6,8,10).forEach{section->
                        val y=(axisMinute(LessonTimes.end(section,false))*scale).dp.toPx()
                        drawLine(colors.separator,androidx.compose.ui.geometry.Offset(0f,y),androidx.compose.ui.geometry.Offset(size.width,y),.5.dp.toPx())
                    }
                }
                page.days[day].forEach { block -> key(block.course.id) {
                    val course=block.course
                    val top=block.topMinute*scale
                    val height=(block.heightMinutes*scale).coerceAtLeast(25f)
                    val source=rememberCourseMorphSource("week-$week-${course.id}",style.radiusDp,style.colors.getValue(course.title),active&&interactive){CourseMorphContent.Lesson(course)}
                    SideEffect{source?.stroke=if(course.staggered)colors.accent else Color.Transparent}
                    Box(Modifier.padding(horizontal=style.margin).offset(y=top.dp).fillMaxWidth().height(height.dp).morphSource(source).graphicsLayer{alpha=if(source?.controller?.owns(source.key)==true)0f else reloadAlpha.value}
                        .background(style.colors.getValue(course.title),style.shape)
                        .then(if(course.staggered)Modifier.border(1.dp,colors.accent,style.shape) else Modifier)
                        .semantics{contentDescription="${course.title}，${course.place}，${course.teacher}，第${course.first}至${course.last}节"}
                        .clickable{if(source!=null)source.open()else onCourse(course)}.padding(3.dp).drawWithCache {
                            // The same title/location/teacher appears in many weeks. Share shaped
                            // paragraphs across pager pages instead of measuring 3 new Text nodes
                            // per card. Max lines, remaining height and ellipsis stay unchanged.
                            val width=size.width.toInt().coerceAtLeast(0)
                            var remaining=size.height.toInt().coerceAtLeast(0)
                            val layouts=listOf(Triple(course.title,style.title,style.titleLines),Triple(course.place,style.place,style.placeLines),Triple(course.teacher,style.teacher,style.teacherLines))
                                .mapNotNull{(text,textStyle,lines)->
                                    if(remaining<=0||width<=0)null else textMeasurer.measure(AnnotatedString(text),textStyle,
                                        overflow=TextOverflow.Ellipsis,maxLines=lines,constraints=Constraints(maxWidth=width,maxHeight=remaining))
                                        .also{remaining=(remaining-it.size.height).coerceAtLeast(0)}
                                }
                            var sourceY=3.dp.toPx()
                            source?.canvasTexts=layouts.mapIndexed{index,layout->
                                MorphText(listOf("title","place","teacher")[index],layout.layoutInput.text.text,
                                    androidx.compose.ui.geometry.Rect(Offset(3.dp.toPx(),sourceY),layout.size.toSize()),layout.layoutInput.style,layout.layoutInput.maxLines,layout)
                                    .also{sourceY+=layout.size.height}
                            }
                            onDrawBehind {
                                var y=0f
                                for(layout in layouts){drawText(layout,topLeft=Offset(0f,y));y+=layout.size.height}
                            }
                        })
                } }
            }}
            }
            TimeAxis(true,scale,staggeredAxis)
        }
    }
    }
}

@Immutable private class WeekCardStyle(appearance:org.json.JSONObject,courseColors:Map<String,String>,courses:List<Course>,defaults:androidx.compose.ui.text.TextStyle) {
    val title=defaults.merge(courseTextStyle(appearance,"Title",14f,6))
    val place=defaults.merge(courseTextStyle(appearance,"Place",11f,5))
    val teacher=defaults.merge(courseTextStyle(appearance,"Instructor",11f,4))
    val titleLines=appearance.optInt("TitleMaxLines",3).coerceIn(1,30)
    val placeLines=appearance.optInt("PlaceMaxLines",5).coerceIn(1,30)
    val teacherLines=appearance.optInt("InstructorMaxLines",2).coerceIn(1,30)
    val margin=appearance.optDouble("cardMargin",2.0).toFloat().coerceIn(0f,10f).dp
    val radiusDp=appearance.optDouble("cardBorderRadius",6.0).toFloat().coerceIn(0f,100f)
    val shape=G2RoundedRectangle(radiusDp.dp)
    val colors=courses.associate{course->course.title to runCatching{Color(android.graphics.Color.parseColor(courseColors.getValue(course.title)))}.getOrElse{Color.hsv((course.title.hashCode().toLong().and(0x7fffffff)%360).toFloat(),.38f,.82f)}}
}

private fun appearanceColor(appearance:org.json.JSONObject,key:String)=runCatching{Color(android.graphics.Color.parseColor(appearance.optString(key,"#FFFFFFFF")))}.getOrDefault(Color.White)
private fun courseTextStyle(appearance:org.json.JSONObject,prefix:String,defaultSize:Float,defaultWeight:Int):androidx.compose.ui.text.TextStyle {
    val size=appearance.optDouble("${prefix}FontSize",defaultSize.toDouble()).toFloat()
    return androidx.compose.ui.text.TextStyle(fontSize=size.sp,lineHeight=(size*1.35f).sp,letterSpacing=0.sp,color=appearanceColor(appearance,"${prefix}TextColor"),fontWeight=androidx.compose.ui.text.font.FontWeight(appearance.optInt("${prefix}FontWeight",defaultWeight).coerceIn(1,9)*100))
}

private val WeekdayNames=listOf("一","二","三","四","五","六","日")
private class WeekHeaderPaints(val weekday:android.graphics.Paint,val date:android.graphics.Paint,
    val weekdayBaseline:Float,val dateBaseline:Float,val height:Int)

@Composable private fun rememberWeekHeaderPaints(measurer:TextMeasurer):WeekHeaderPaints {
    val colors=LocalGlassColors.current
    val density=LocalDensity.current
    val context=androidx.compose.ui.platform.LocalContext.current
    val weekdayStyle=IosTypography.footnote
    val dateStyle=androidx.compose.material3.LocalTextStyle.current.copy(fontSize=11.sp)
    val face=remember(context){androidx.core.content.res.ResourcesCompat.getFont(context,R.font.misans_vf)}
    return remember(colors,density,weekdayStyle,dateStyle,face,measurer) {
        fun paint(style:androidx.compose.ui.text.TextStyle)=android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            color=colors.content.toArgb();textSize=with(density){style.fontSize.toPx()};typeface=face
            fontVariationSettings="'wght' ${miSansWeight(style.fontWeight?.weight?:400)}"
            textAlign=android.graphics.Paint.Align.CENTER;isSubpixelText=true
            letterSpacing=style.letterSpacing.value.takeIf{it.isFinite()}?.div(style.fontSize.value)?:0f
            fontFeatureSettings=style.fontFeatureSettings
        }
        // Measure the shared line metrics once. New weeks only draw numeric dates,
        // avoiding seven paragraph measurements in each pager prefetch job.
        val weekday=measurer.measure(AnnotatedString("一"),weekdayStyle,maxLines=1)
        val date=measurer.measure(AnnotatedString("1/1"),dateStyle,maxLines=1)
        WeekHeaderPaints(paint(weekdayStyle),paint(dateStyle),weekday.firstBaseline,
            weekday.size.height+date.firstBaseline,weekday.size.height+date.size.height)
    }
}

@Composable private fun WeekDateHeader(date:LocalDate,dayWidth:androidx.compose.ui.unit.Dp,style:WeekHeaderPaints) {
    val density=LocalDensity.current
    val column=with(density){dayWidth.roundToPx()}
    val headerWidth=with(density){(column*7).toDp()}
    val headerHeight=with(density){style.height.toDp()}
    val dates=remember(date){List(7){date.plusDays(it.toLong()).let{"${it.monthValue}/${it.dayOfMonth}"}}}
    Row(Modifier.width(headerWidth).height(headerHeight).drawWithCache {
        onDrawBehind { drawContext.canvas.nativeCanvas.apply {
            repeat(7){day->
                val center=column*(day+.5f)
                drawText(WeekdayNames[day],center,style.weekdayBaseline.toFloat(),style.weekday)
                drawText(dates[day],center,style.dateBaseline.toFloat(),style.date)
            }
        } }
    }) {
        repeat(7){day->Box(Modifier.width(dayWidth).fillMaxHeight().semantics{
            contentDescription="周${WeekdayNames[day]} ${dates[day]}"
        })}
    }
}

private class TimeAxisPaints(val number:android.graphics.Paint,val time:android.graphics.Paint)

/** Reuse the variable-font instances across weeks, including their GPU glyph atlas. */
@Composable private fun rememberTimeAxisPaints(staggered:Boolean):TimeAxisPaints {
    val colors=LocalGlassColors.current
    val density=LocalDensity.current
    val context=androidx.compose.ui.platform.LocalContext.current
    val miSansTypeface=remember(context){androidx.core.content.res.ResourcesCompat.getFont(context,R.font.misans_vf)}
    val number=remember(colors,density,staggered){android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply{
        color=(if(staggered)colors.accent else colors.content).toArgb();textSize=with(density){12.sp.toPx()};typeface=miSansTypeface;fontVariationSettings="'wght' ${miSansWeight(700)}"
    }}
    val timePaint=remember(colors,density,staggered){android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply{
        color=(if(staggered)colors.accent else colors.secondaryContent).toArgb();textSize=with(density){11.sp.toPx()};typeface=miSansTypeface;fontVariationSettings="'wght' ${miSansWeight(400)}";fontFeatureSettings="tnum"
    }}
    return remember(number,timePaint){TimeAxisPaints(number,timePaint)}
}

@Composable private fun TimeAxis(staggered:Boolean,scale:Float,paints:TimeAxisPaints) {
    val layoutScale=LocalGlasmioLayoutFontScale.current
    val number=paints.number
    val timePaint=paints.time
    val labels=remember(staggered){(1..11).map{section->Triple(section,LessonTimes.start(section,staggered),LessonTimes.end(section,staggered))}}
    val description=remember(labels){labels.joinToString("；"){"第${it.first}节 ${it.second}至${it.third}"}}
    Canvas(Modifier.width((34f*layoutScale.coerceIn(1f,1.5f)).dp).height((740*scale).dp).semantics{contentDescription=description}) {
        labels.forEach{(section,start,end)->
            val y=(axisMinute(start)*scale).dp.toPx()
            drawContext.canvas.nativeCanvas.apply {
                drawText(section.toString(),0f,y+number.textSize,number)
                drawText(start.toString(),0f,y+number.textSize+timePaint.textSize+5.dp.toPx(),timePaint)
                drawText(end.toString(),0f,y+number.textSize+timePaint.textSize*2+8.dp.toPx(),timePaint)
            }
        }
    }
}

@Composable private fun MonthGrid(courses:List<Course>,semester:LocalDate,month:YearMonth,modifier:Modifier=Modifier,cellHeight:androidx.compose.ui.unit.Dp=52.dp,fitHeight:Boolean=false,compact:Boolean=false,onDay:(LocalDate)->Unit={}) {
    val colors=LocalGlassColors.current
    val first=month.atDay(1)
    val cells=first.dayOfWeek.value-1+month.lengthOfMonth()
    val counts=remember(courses,semester,month){CalendarMonthData.counts(courses,semester,month)}
    Column(modifier.fillMaxWidth().padding(vertical=4.dp).background(colors.elevatedBackground,GlasmioTheme.shapes.medium).padding(if(compact)8.dp else 12.dp)) {
        Text("${month.year}年${month.monthValue}月",style=if(compact)IosTypography.footnote else if(fitHeight)IosTypography.headline else IosTypography.title2,maxLines=1,modifier=Modifier.padding(bottom=if(compact)4.dp else 8.dp))
        Row { listOf("一","二","三","四","五","六","日").forEach{Text(it,Modifier.weight(1f),style=if(compact)IosTypography.caption2 else IosTypography.caption1)} }
        repeat(if(compact)6 else (cells+6)/7){row->Row(if(fitHeight)Modifier.weight(1f)else Modifier.height(cellHeight)) {repeat(7){column->
            val day=row*7+column-(first.dayOfWeek.value-1)+1
            val date=if(day in 1..month.lengthOfMonth())month.atDay(day)else null
            val source=if(date!=null)rememberCourseMorphSource("day-$date",12f){CourseMorphContent.Day(date,CourseClock.onDate(courses,semester,date,ZoneId.systemDefault()))}else null
            Column(Modifier.weight(1f).morphSource(source).graphicsLayer{alpha=if(source?.controller?.owns(source.key)==true)0f else 1f}
                .then(if(date!=null)Modifier.clickable{if(source!=null)source.open()else onDay(date)}else Modifier).padding(top=2.dp)) {
                if(day in 1..month.lengthOfMonth()) {
                    val date=month.atDay(day)
                    val count=counts[day]?:0
                    Text(day.toString(),modifier=Modifier.morphText(source,"title",day.toString(),(if(compact)IosTypography.caption2 else if(fitHeight)IosTypography.footnote else IosTypography.body).copy(color=if(date==LocalDate.now()||count>0)colors.accent else colors.content)).semantics{contentDescription="$date，${count}节课程"},style=if(compact)IosTypography.caption2 else if(fitHeight)IosTypography.footnote else IosTypography.body,color=if(date==LocalDate.now()||count>0)colors.accent else colors.content)
                    if(!compact&&!fitHeight&&count>0&&cellHeight>=32.dp)Text("${count}节",fontSize=9.sp,color=colors.accent)
                }
            }
        }} }
    }
}
