// Motion adapted from Nevodev/Cresto, Apache-2.0. See third_party/cresto/SOURCES.md.
package com.pluvist.sachet.next

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.layout
import androidx.compose.ui.semantics.clearAndSetSemantics
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

internal val crestoExitEasing=CubicBezierEasing(.2f,.2f,0f,1f)
private const val CrestoFadeMillis=200
private const val CrestoFadeInDelayMillis=100
private fun crestoFade()=tween<Float>(CrestoFadeMillis)
internal fun crestoEnter()=fadeIn(tween(CrestoFadeMillis,CrestoFadeInDelayMillis))+scaleIn(tween(400,100,EaseOutExpo),initialScale=.95f)
internal fun crestoExit()=fadeOut(tween(CrestoFadeMillis))+scaleOut(tween(600,easing=crestoExitEasing),targetScale=.95f)

/** A completion counter also catches cache/local reloads that finish within one frame.
 * Busy phases coalesce related requests; typing, countdowns and recomposition do not reload. */
internal enum class ReloadFadeAction { Hide,Reveal,Replay }
internal class PageReloadTrigger(private var busy:Boolean,private var revision:Any?) {
    fun update(nextBusy:Boolean,nextRevision:Any?):ReloadFadeAction? {
        val action=when {
            nextBusy&&!busy->ReloadFadeAction.Hide
            !nextBusy&&busy->ReloadFadeAction.Reveal
            !nextBusy&&revision!=nextRevision->ReloadFadeAction.Replay
            else->null
        }
        busy=nextBusy;revision=nextRevision
        return action
    }
}

/** One cheap opacity animation per refreshed region. Start fading on the request,
 * reveal as soon as it settles, and never reset scroll/input or wait before fading.
 * Unobservably fast cache reloads still get a fade pair through their revision. */
@Composable internal fun rememberCrestoReloadAlpha(busy:Boolean=false,revision:Any?=Unit):State<Float> {
    val trigger=remember{PageReloadTrigger(busy,revision)}
    val alpha=remember{Animatable(if(busy)0f else 1f)}
    LaunchedEffect(busy,revision) {
        val action=trigger.update(busy,revision)
        when {
            busy->alpha.animateTo(0f,crestoFade())
            action==ReloadFadeAction.Reveal->alpha.animateTo(1f,crestoFade())
            action==ReloadFadeAction.Replay->{alpha.animateTo(0f,crestoFade());alpha.animateTo(1f,crestoFade())}
        }
    }
    return alpha.asState()
}

internal fun Modifier.reloadFade(alpha:State<Float>)=graphicsLayer{this.alpha=alpha.value}

/** Keep page state/preloaded layouts alive. Only render-layer properties change each frame.
 * LaunchedEffect cancels the previous motion so a rapid reversal continues from its current value. */
@Composable internal fun CrestoPageLayer(active:Boolean,content:@Composable ()->Unit) {
    val alpha=remember{Animatable(if(active)1f else 0f)}
    val scale=remember{Animatable(if(active)1f else .95f)}
    val placed by remember(active){derivedStateOf{active||alpha.value>.001f}}
    LaunchedEffect(active) {
        launch { if(active)delay(CrestoFadeInDelayMillis.toLong());alpha.animateTo(if(active)1f else 0f,crestoFade()) }
        launch {
            if(active)delay(100)
            scale.animateTo(if(active)1f else .95f,
                if(active)tween(400,easing=EaseOutExpo) else tween(600,easing=crestoExitEasing))
        }
    }
    Box(Modifier.fillMaxSize().graphicsLayer {
        this.alpha=alpha.value;scaleX=scale.value;scaleY=scale.value
    }.then(if(active)Modifier else Modifier.clearAndSetSemantics{}.pointerInput(Unit){
        awaitPointerEventScope{while(true)awaitPointerEvent(androidx.compose.ui.input.pointer.PointerEventPass.Initial).changes.forEach{it.consume()}}
    }).layout{measurable,constraints->
        val child=measurable.measure(constraints)
        layout(child.width,child.height){if(placed)child.place(0,0)}
    }){content()}
}
