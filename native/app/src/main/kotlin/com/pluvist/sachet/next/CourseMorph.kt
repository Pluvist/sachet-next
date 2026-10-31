package com.pluvist.sachet.next

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.*
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.toSize
import java.time.LocalDate
import kotlin.math.*

internal sealed interface CourseMorphContent {
    data object Status:CourseMorphContent
    data class Lesson(val course:Course):CourseMorphContent
    data class Day(val date:LocalDate,val lessons:List<DatedCourse>):CourseMorphContent
}
internal object CourseMorphMotion {
    fun open(content:CourseMorphContent)=spring<Float>(
        dampingRatio=if(content is CourseMorphContent.Lesson).88f else .68f,
        stiffness=430f,visibilityThreshold=.0005f,
    )
    fun close(content:CourseMorphContent,replacing:Boolean)=spring<Float>(
        dampingRatio=if(replacing).85f else if(content is CourseMorphContent.Lesson).88f else .7f,
        stiffness=if(replacing)950f else 520f,visibilityThreshold=.0005f,
    )
}
internal data class MorphText(val id:String,val value:String,val bounds:Rect,val style:TextStyle,val lines:Int,val layout:TextLayoutResult?=null)
internal data class MorphSnapshot(val key:String,val bounds:Rect,val radiusDp:Float,val fill:Color,val texts:List<MorphText>,val stroke:Color=Color.Transparent)
internal data class MorphRequest(val snapshot:MorphSnapshot,val content:CourseMorphContent)

/** One visible panel; a returning panel accepts the latest replacement intent. */
internal class MorphIntentQueue {
    var desiredKey:String?=null;private set
    fun request(key:String,busy:Boolean=false,returning:Boolean=false):Boolean {
        if(!returning&&(busy||desiredKey!=null))return false
        desiredKey=key;return true
    }
    fun dismiss(){desiredKey=null}
}
internal class CourseMorphFlight(val request:MorphRequest) {
    var source by mutableStateOf(request.snapshot)
    val progress=Animatable(0f)
    var resumeVelocity=0f
    var returning by mutableStateOf(false)
    var updatedCourse by mutableStateOf((request.content as? CourseMorphContent.Lesson)?.course)
    var captureEpoch=0
}
internal class CourseMorphController {
    val intents=MorphIntentQueue()
    var cacheEpoch by mutableIntStateOf(0)
    var retargeting by mutableStateOf(false)
    var revision by mutableIntStateOf(0);private set
    var flight by mutableStateOf<CourseMorphFlight?>(null)
    var desired: MorphRequest?=null;private set
    var rootScreenOrigin=Offset.Zero
    var beforeOpen:()->Unit={}
    // Reading the revision makes pending requests observable before a panel exists.
    val statusChromeRequested:Boolean get()=revision.let{desired?.content==CourseMorphContent.Status}
    private val sources=linkedMapOf<String,CourseMorphSource>()
    fun register(source:CourseMorphSource){sources[source.key]=source}
    fun unregister(source:CourseMorphSource){if(sources[source.key]===source)sources.remove(source.key)}
    fun owns(key:String)=flight?.source?.key==key
    val isBusy:Boolean get()=flight!=null||desired!=null
    fun request(value:MorphRequest) {
        val current=flight
        val returning=current?.returning==true||retargeting
        if(!intents.request(value.snapshot.key,current!=null,returning))return
        current?.let{it.resumeVelocity=it.progress.velocity}
        val reversing=current?.source?.key==value.snapshot.key
        if(BuildConfig.BUILD_TYPE=="preview")android.util.Log.d("CourseMorph","accepted type=${value.content.javaClass.simpleName}, reversing=$reversing, p=${current?.progress?.value}")
        desired=value
        retargeting=returning&&!reversing
        if(!reversing)cacheEpoch++
        beforeOpen();revision++
    }
    fun dismiss(){
        if(desired==null && (flight==null || flight?.returning==true))return
        flight?.let{it.resumeVelocity=it.progress.velocity;it.returning=true}
        intents.dismiss();desired=null;retargeting=false;revision++
    }
    fun refreshedSource(key:String)=sources[key]?.snapshot()
    fun outsideTap(){dismiss()}
    fun animationTap(position:Offset) {
        val current=flight
        if(current?.returning!=true&&!retargeting){dismiss();return}
        // Footer chrome is drawn above page cards, regardless of registration
        // order. Never select a card hidden behind that chrome during return.
        val footer=sources["course-status"]?.snapshot()?.bounds
        val candidates=listOfNotNull(sources["course-status"])+sources.values.toList().asReversed().filter{it.key!="course-status"}
        val source=candidates.firstOrNull{candidate->
            (candidate.key=="course-status"||footer==null||position.y<footer.top)&&
            candidate.eligible&&candidate.coordinates?.let{it.isAttached&&it.boundsInRoot().contains(position)}==true&&
                candidate.snapshot()?.bounds?.contains(position)==true
        }
        if(BuildConfig.BUILD_TYPE=="preview")android.util.Log.d("CourseMorph","return tap hit=${source!=null}, progress=${flight?.progress?.value}")
        if(source==null)dismiss()
        else if(current?.returning==true||retargeting)source.open()

    }
}
internal class CourseMorphSource(val controller:CourseMorphController,val key:String) {
    var coordinates:LayoutCoordinates?=null
    var eligible=true
    var radiusDp=24f
    var fill=Color.Transparent
    var stroke=Color.Transparent
    var content:()->CourseMorphContent={CourseMorphContent.Status}
    class TextField {
        var coordinates:LayoutCoordinates?=null
        var text:()->String={""};var style=TextStyle.Default;var lines=1
    }
    val fields=linkedMapOf<String,TextField>()
    var canvasTexts:List<MorphText> = emptyList()
    private fun LayoutCoordinates.rect():Rect {
        val origin=positionOnScreen()-controller.rootScreenOrigin
        return Rect(origin,size.toSize())
    }
    fun snapshot():MorphSnapshot? {
        val coords=coordinates?.takeIf{it.isAttached}?:return null
        val rect=coords.rect();if(rect.width<1f||rect.height<1f)return null
        val texts=fields.mapNotNull{(id,field)->field.coordinates?.takeIf{it.isAttached}?.let{MorphText(id,field.text(),it.rect(),field.style,field.lines)}}+
            canvasTexts.map{it.copy(bounds=it.bounds.translate(rect.topLeft))}
        return MorphSnapshot(key,rect,radiusDp,fill,texts.filter{it.value.isNotBlank()},stroke)
    }
    fun open(){snapshot()?.let{controller.request(MorphRequest(it,content()))}}
}
internal val LocalCourseMorph=staticCompositionLocalOf<CourseMorphController?>{null}
internal val LocalMorphInteractive=staticCompositionLocalOf{true}

@Composable internal fun rememberCourseMorphSource(key:String,radiusDp:Float=24f,fill:Color=Color.Transparent,eligible:Boolean=LocalMorphInteractive.current,content:()->CourseMorphContent):CourseMorphSource? {
    val controller=LocalCourseMorph.current?:return null
    val source=remember(controller,key){CourseMorphSource(controller,key)}
    SideEffect{source.radiusDp=radiusDp;source.fill=fill;source.eligible=eligible;source.content=content}
    DisposableEffect(source){controller.register(source);onDispose{controller.unregister(source)}}
    return source
}
internal fun Modifier.morphSource(source:CourseMorphSource?)=if(source==null)this else onGloballyPositioned{source.coordinates=it}
@Composable internal fun Modifier.morphText(source:CourseMorphSource?,id:String,value:String,style:TextStyle,lines:Int=1,provider:(()->String)?=null):Modifier {
    if(source==null)return this
    val field=remember(source,id){source.fields.getOrPut(id){CourseMorphSource.TextField()}}
    SideEffect{field.text=provider?:{value};field.style=style;field.lines=lines}
    return onGloballyPositioned{field.coordinates=it}
}

internal object CourseMorphGeometry {
    fun smooth(value:Float):Float {val p=value.coerceIn(0f,1f);return p*p*(3f-2f*p)}
    fun curve(from:Offset,to:Offset,p:Float,arc:Float):Offset {
        val t=p.coerceIn(-.02f,1.055f);val q=1f-t
        val a=from+Offset((to.x-from.x)*.12f,-arc)
        val b=to+Offset((from.x-to.x)*.16f,arc*.35f)
        return from*(q*q*q)+a*(3f*q*q*t)+b*(3f*q*t*t)+to*(t*t*t)
    }
    fun frame(from:Rect,to:Rect,p:Float,arc:Float):Rect {
        val t=p.coerceIn(-.02f,1.055f)
        val center=curve(from.center,to.center,t,arc)
        val size=Size((from.width+(to.width-from.width)*t).coerceAtLeast(if(t<0)from.width*.8f else 1f),(from.height+(to.height-from.height)*t).coerceAtLeast(if(t<0)from.height*.8f else 1f))
        return Rect(center-Offset(size.width/2,size.height/2),size)
    }
}
