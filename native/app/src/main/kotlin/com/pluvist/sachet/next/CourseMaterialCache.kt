package com.pluvist.sachet.next

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.graphics.layer.GraphicsLayer
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.layout.*
import androidx.compose.ui.unit.*
import io.github.neoruaa.glasmio.glass.render.Backdrop
import io.github.neoruaa.glasmio.glass.MultiSampleBlurRenderer
import kotlin.math.ceil
import kotlin.math.sqrt

/** A small GPU-only page thumbnail. Modal content is never part of its source. */
internal class CourseThumbnailBackdrop(val planes:List<GraphicsLayer>):Backdrop {
    companion object { const val Scale=.125f;const val OutputScale=Scale/8f }
    val raw get()=planes.first()
    val pixels get()=planes.last()
    val samplers=List(3){MultiSampleBlurRenderer()}
    override val isCoordinatesDependent=true
    var coordinates:LayoutCoordinates?=null
    var recordedEpoch=-1
    var fallback=Color.Transparent
    private val sourceToConsumer=Matrix()
    override fun DrawScope.drawBackdrop(density:Density,coordinates:LayoutCoordinates?,layerBlock:(GraphicsLayerScope.()->Unit)?) {
        // Cover the padded sampling support outside the captured window too.
        drawContext.canvas.nativeCanvas.drawColor(fallback.toArgb())
        val source=this@CourseThumbnailBackdrop.coordinates
        if(source?.isAttached!=true||coordinates?.isAttached!=true||pixels.size.width<1) {
            drawRect(fallback);return
        }
        try { coordinates.transformFrom(source,sourceToConsumer) } catch(_:IllegalArgumentException) { drawRect(fallback);return }
        if(!sourceToConsumer.values.all{it.isFinite()}){drawRect(fallback);return}
        // The final plane represents the same entire window as the raw capture.
        // Only this single window-to-control transform is applied during replay.
        withTransform({transform(sourceToConsumer);scale(1f/OutputScale,1f/OutputScale,Offset.Zero)}){drawLayer(pixels)}
    }
}

@Composable internal fun rememberCourseThumbnailBackdrop():CourseThumbnailBackdrop {
    val raw=rememberGraphicsLayer()
    val half=rememberGraphicsLayer()
    val quarter=rememberGraphicsLayer()
    val eighth=rememberGraphicsLayer()
    return remember(raw,half,quarter,eighth){CourseThumbnailBackdrop(listOf(raw,half,quarter,eighth))}
}

internal fun coursePanelTarget(width:Float,height:Float,top:Float,bottom:Float,lower:Boolean,empty:Boolean,density:Density):Rect=with(density) {
    val w=minOf(width-32.dp.toPx(),(if(lower)560 else 480).dp.toPx()).coerceAtLeast(1f)
    val h=minOf((if(empty)240 else if(lower)420 else 440).dp.toPx(),height-top-bottom-64.dp.toPx()).coerceAtLeast(100.dp.toPx())
    val x=(width-w)/2f
    val y=if(lower)height-bottom-16.dp.toPx()-h else top+(height-top-bottom-h)/2f
    Rect(x,y,x+w,y+h)
}


/** Capture raw page pixels on the accepted click, with no bitmap readback or async wait. */
@Composable internal fun CourseThumbnailCapture(controller:CourseMorphController,thumbnail:CourseThumbnailBackdrop,scene:Backdrop,fallback:Color) {
    val generation=controller.cacheEpoch
    val epoch=controller.flight?.captureEpoch?:if(controller.desired!=null)generation else null
    SideEffect{thumbnail.fallback=fallback}
    Layout(content={
        Box(Modifier.fillMaxSize().onGloballyPositioned{thumbnail.coordinates=it}.drawWithContent {
            val extent=IntSize(ceil(size.width*CourseThumbnailBackdrop.Scale).toInt().coerceAtLeast(1),ceil(size.height*CourseThumbnailBackdrop.Scale).toInt().coerceAtLeast(1))
            if(epoch!=null&&(thumbnail.recordedEpoch!=epoch||thumbnail.raw.size!=extent)) {
                thumbnail.raw.compositingStrategy=androidx.compose.ui.graphics.layer.CompositingStrategy.Offscreen
                // Draw only into the tiny GPU layer. Never draw a preparation
                // panel on screen and never wait for toImageBitmap().
                thumbnail.raw.record(extent){
                    drawRect(fallback)
                    scale(CourseThumbnailBackdrop.Scale,CourseThumbnailBackdrop.Scale,Offset.Zero){
                        with(scene){drawBackdrop(this@drawWithContent,thumbnail.coordinates)}
                    }
                }
                // Repeated large offsets at quarter resolution produce separated
                // copies (a plaid pattern). Low-pass every 2x reduction instead:
                // each normalized pass now steps only about 1-2 texture pixels.
                val radius=32.dp.toPx()/sqrt(16f*16f+32f*32f+64f*64f)
                for(index in 1..3) {
                    val input=thumbnail.planes[index-1]
                    val output=thumbnail.planes[index]
                    val scale=CourseThumbnailBackdrop.Scale/(1 shl index)
                    val outputSize=IntSize(ceil(size.width*scale).toInt().coerceAtLeast(1),ceil(size.height*scale).toInt().coerceAtLeast(1))
                    output.clip=true
                    output.compositingStrategy=androidx.compose.ui.graphics.layer.CompositingStrategy.Offscreen
                    output.renderEffect=thumbnail.samplers[index-1].effect(radius,width=outputSize.width.toFloat(),height=outputSize.height.toFloat())?.asComposeRenderEffect()
                    output.record(outputSize) {
                        drawRect(fallback)
                        scale(.5f,.5f,Offset.Zero){drawLayer(input)}
                    }
                }
                thumbnail.recordedEpoch=epoch
            }
        })
    },modifier=Modifier.fillMaxSize()){nodes,c->
        val child=nodes.single().measure(c)
        layout(c.maxWidth,c.maxHeight){if(epoch!=null)child.place(0,0)}
    }
}
