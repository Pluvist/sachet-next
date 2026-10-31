package com.pluvist.sachet.next

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.SoftwareKeyboardController
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.offset
import io.github.neoruaa.glasmio.core.*
import io.github.neoruaa.glasmio.glass.*
import io.github.neoruaa.glasmio.icons.*
import io.github.neoruaa.glasmio.ui.*
import kotlinx.coroutines.flow.first
import java.text.Normalizer
import java.util.Locale
import kotlin.math.roundToInt

internal class AcademicSearchSession(val route:String,val placeholder:String) {
    var query by mutableStateOf(TextFieldValue())
    var expanded by mutableStateOf(false)
    var inputCoordinates:LayoutCoordinates?=null
    fun close(){expanded=false;query=TextFieldValue()}
}

internal class AcademicSearchController {
    var session by mutableStateOf<AcademicSearchSession?>(null)
        private set
    var rootCoordinates:LayoutCoordinates?=null
    fun forRoute(route:String?)=session?.takeIf{it.route==route}
    fun attach(value:AcademicSearchSession){session=value}
    fun detach(value:AcademicSearchSession){if(session===value)session=null}
}
internal val LocalAcademicSearch=staticCompositionLocalOf<AcademicSearchController?>{null}

private val SearchMotion=spring<Float>(dampingRatio=.77f,stiffness=390f,visibilityThreshold=.001f)

/**
 * Search owns its return to the bottom rather than following the IME's final
 * inset removal. The same spring drives width and keyboard lift, so closing
 * starts both motions together and reopening preserves their current velocity.
 * Other editors continue to use the system's animated IME inset directly.
 */
@Composable internal fun Modifier.academicAccessoryImeLift(controller:AcademicSearchController,route:String?):Modifier {
    val session=controller.forRoute(route)
    val density=LocalDensity.current
    val keyboardInsets=WindowInsets.ime.exclude(WindowInsets.navigationBars)
    // Normalize to dp so the vertical and horizontal springs share their timing
    // and settling threshold across display densities.
    val lift=animateFloatAsState(
        targetValue=if(session?.expanded==true)keyboardInsets.getBottom(density)/density.density else 0f,
        animationSpec=SearchMotion,label="Academic search keyboard lift",
    )
    return offset {
        val pixels=if(session!=null)lift.value*density.density else keyboardInsets.getBottom(density).toFloat()
        IntOffset(0,-pixels.coerceAtLeast(0f).roundToInt())
    }
}

private fun AcademicSearchSession.dismiss(focus:FocusManager,keyboard:SoftwareKeyboardController?) {
    close();focus.clearFocus(force=true);keyboard?.hide()
}

/** Dim only the page plane; the search surface is drawn above this scrim. */
@Composable internal fun AcademicSearchScrim(controller:AcademicSearchController,route:String?) {
    val session=controller.forRoute(route)?:return
    val focus=LocalFocusManager.current
    val keyboard=LocalSoftwareKeyboardController.current
    val opacity=if(LocalGlassColors.current.isDark).26f else .18f
    key(session) {
        val progress=animateFloatAsState(if(session.expanded)1f else 0f,
            spring(dampingRatio=.85f,stiffness=450f,visibilityThreshold=.001f),label="Academic search dim")
        if(session.expanded||progress.value>.001f)Box(Modifier.fillMaxSize()
            .drawBehind{drawRect(Color.Black.copy(alpha=opacity*progress.value.coerceIn(0f,1f)))}
            .semantics{contentDescription="退出搜索"}
            .clickable(interactionSource=remember{MutableInteractionSource()},indication=null){session.dismiss(focus,keyboard)})
    }
}

/** Consume outside taps before underlying page/footer controls receive them. */
@Composable internal fun Modifier.academicSearchDismissGesture(controller:AcademicSearchController,route:String?):Modifier {
    val session=controller.forRoute(route)
    val focus=LocalFocusManager.current
    val keyboard=LocalSoftwareKeyboardController.current
    val tracked=this.onGloballyPositioned{controller.rootCoordinates=it}
    if(session?.expanded!=true)return tracked
    return tracked.pointerInput(session) {
        awaitEachGesture {
            val down=awaitFirstDown(requireUnconsumed=false,pass=PointerEventPass.Initial)
            val root=controller.rootCoordinates
            val input=session.inputCoordinates
            val bounds=if(root?.isAttached==true&&input?.isAttached==true)
                root.localBoundingBoxOf(input,clipBounds=false)else Rect.Zero
            val outside=!bounds.contains(down.position)
            if(outside)down.consume()
            var moved=false
            do {
                val event=awaitPointerEvent(PointerEventPass.Initial)
                if(event.changes.any{(it.position-down.position).getDistance()>viewConfiguration.touchSlop})moved=true
                if(outside)event.changes.forEach{it.consume()}
            }while(event.changes.any{it.pressed})
            if(outside&&!moved)session.dismiss(focus,keyboard)
        }
    }
}

object AcademicKeywordSearch {
    private fun normalize(value:String)=Normalizer.normalize(value,Normalizer.Form.NFKC).lowercase(Locale.ROOT)
    fun matches(record:AcademicRecord,query:String):Boolean {
        val words=normalize(query).trim().split(Regex("\\s+")).filter{it.isNotEmpty()}
        if(words.isEmpty())return true
        val text=normalize((listOf(record.title)+record.fields.map{it.second}).joinToString("\n"))
        return words.all{text.contains(it)}
    }
}

/** One owner for the accessory and search geometry; interrupted springs keep their velocity. */
@Composable internal fun AcademicAccessoryRow(
    progress:State<Float>,docking:State<Float>,controller:AcademicSearchController,route:String?,
    departure:State<Float>,searchEnabled:Boolean=true,
    content:@Composable ()->Unit,
) {
    val current=controller.forRoute(route)
    var retained by remember{mutableStateOf<AcademicSearchSession?>(null)}
    SideEffect{if(current!=null)retained=current}
    val session=current?:retained
    val presence=animateFloatAsState(if(current!=null)1f else 0f,
        spring(dampingRatio=.73f,stiffness=410f,visibilityThreshold=.001f),label="Academic search entrance")
    val expansion=animateFloatAsState(if(current?.expanded==true)1f else 0f,
        SearchMotion,label="Academic search expansion")
    val courseAlpha=remember{derivedStateOf{1f-expansion.value.coerceIn(0f,1f)}}
    val searchAlpha=remember(presence,departure){derivedStateOf{
        (presence.value*(1f-departure.value.coerceIn(0f,1f))).coerceIn(0f,1f)
    }}
    Layout(content={
        GlassFlightGuard(courseAlpha,content=content)
        GlassFlightGuard(searchAlpha,modifier=if(current!=null&&searchEnabled)Modifier else Modifier.clearAndSetSemantics{}) {
            if(session!=null)key(session){AcademicSearchInput(session,current!=null&&searchEnabled,expansion)}else Box(Modifier.fillMaxSize())
        }
    },modifier=Modifier.fillMaxSize()) { measurables,constraints->
        val width=constraints.maxWidth
        val height=48.dp.roundToPx() // 24dp radius, identical to the course capsule.
        val hostHeight=118.dp.roundToPx()
        val inset=(69.dp.toPx()*progress.value.coerceIn(0f,1f)).roundToInt().coerceAtMost((width-1)/2)
        val available=(width-inset*2).coerceAtLeast(1)
        val reserved=(60.dp.toPx()*presence.value.coerceIn(0f,1.04f)).roundToInt()
        val courseWidth=(available-reserved).coerceAtLeast(1)
        val searchWidth=(height+(width-height)*expansion.value.coerceIn(0f,1.035f)).roundToInt().coerceAtLeast(height)
        val course=measurables[0].measure(Constraints.fixed(courseWidth,height))
        val search=measurables[1].measure(Constraints.fixed(searchWidth,height))
        layout(width,hostHeight){
            val d=docking.value.coerceIn(0f,1f)
            val y=(63.dp.toPx()*progress.value.coerceIn(0f,1f)*(1f-d)+(hostHeight-height)*d).roundToInt()
            val courseX=inset-((width+68.dp.toPx())*expansion.value.coerceIn(0f,1.04f)).roundToInt()
            if(courseAlpha.value>.001f)course.placeRelative(courseX,y)
            if(current!=null || presence.value>.001f){
                val enterX=68.dp.toPx()*(1f-presence.value)
                val exitX=(searchWidth+68.dp.toPx())*departure.value.coerceIn(0f,1f)
                search.placeRelative((width-searchWidth+enterX+exitX).roundToInt(),hostHeight-height)
            }
        }
    }
}

/** Fade the completed glass with filter support outside the control's touch rectangle. */
@Composable private fun GlassFlightGuard(alpha:State<Float>,modifier:Modifier=Modifier,content:@Composable ()->Unit) {
    Layout(content={
        Layout(content=content,modifier=Modifier.graphicsLayer{this.alpha=alpha.value.coerceIn(0f,1f);clip=false}) { nodes,c->
            val x=24.dp.roundToPx();val y=48.dp.roundToPx()
            val node=nodes.single().measure(c.offset(-2*x,-2*y))
            layout(node.width+2*x,node.height+2*y){node.placeRelative(x,y)}
        }
    },modifier=modifier){nodes,c->
        val x=24.dp.roundToPx();val y=48.dp.roundToPx()
        val node=nodes.single().measure(c.offset(2*x,2*y))
        layout(node.width-2*x,node.height-2*y){node.placeRelative(-x,-y)}
    }
}

@Composable private fun AcademicSearchInput(session:AcademicSearchSession,visible:Boolean,expansion:State<Float>) {
    val colors=LocalGlassColors.current
    val requester=remember{FocusRequester()}
    val focus=LocalFocusManager.current
    val keyboard=LocalSoftwareKeyboardController.current
    fun close(){session.dismiss(focus,keyboard)}
    LaunchedEffect(session.expanded,visible){
        if(session.expanded&&visible){snapshotFlow{expansion.value}.first{it>=.96f};requester.requestFocus()}
        else {
            focus.clearFocus(force=true);keyboard?.hide()
            // Let the removed editor finish its input-session teardown before
            // repeating hide. Reopening cancels this effect, so a late hide can
            // never dismiss the next search's keyboard.
            if(visible){withFrameNanos{};if(!session.expanded)keyboard?.hide()}
        }
    }
    BackHandler(visible&&session.expanded){close()}
    GlassSurface(Modifier.fillMaxSize().onGloballyPositioned{session.inputCoordinates=it},shape=com.kyant.shapes.Capsule(),style=GlassSurfaceStyle.Navigation,
        onClick=if(visible&&!session.expanded){{session.expanded=true}}else null) {
        Row(Modifier.fillMaxSize().clip(com.kyant.shapes.Capsule()).padding(horizontal=13.dp),verticalAlignment=Alignment.CenterVertically) {
            SfIcon("magnifyingglass",if(session.expanded)null else session.placeholder,size=22.dp,tint=colors.content,modifier=Modifier.size(22.dp))
            if(session.expanded)Row(Modifier.weight(1f).graphicsLayer{alpha=expansion.value.coerceIn(0f,1f)}
                .then(if(session.expanded&&visible)Modifier else Modifier.clearAndSetSemantics{}),verticalAlignment=Alignment.CenterVertically) {
                Spacer(Modifier.width(8.dp))
                BasicTextField(session.query,{session.query=it},enabled=visible&&session.expanded,
                    modifier=Modifier.weight(1f).focusRequester(requester),singleLine=true,
                    textStyle=IosTypography.body.copy(color=colors.content),cursorBrush=SolidColor(colors.accent),
                    keyboardOptions=KeyboardOptions(imeAction=ImeAction.Search),keyboardActions=KeyboardActions(onSearch={keyboard?.hide()}),
                    decorationBox={inner->Box(contentAlignment=Alignment.CenterStart){if(session.query.text.isEmpty())Text(session.placeholder,style=IosTypography.body,color=colors.tertiaryContent);inner()}})
                Box(Modifier.size(32.dp).clickable(enabled=visible&&session.expanded,onClick={close()}),contentAlignment=Alignment.Center){
                    SfIcon("xmark","收起搜索",size=18.dp,tint=colors.content)
                }
            }
        }
    }
}
