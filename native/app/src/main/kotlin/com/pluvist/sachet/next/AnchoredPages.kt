package com.pluvist.sachet.next

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.layout.*
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.*
import io.github.neoruaa.glasmio.core.G2RoundedRectangle

/** Coordinates are plain layout metadata; updating them never recomposes the page. */
internal data class PageOrigin(val bounds:Rect,val radius:Float,val rootSize:Size) {
    fun inViewport(size:Size):Rect {
        val sx=size.width/rootSize.width.coerceAtLeast(1f)
        val sy=size.height/rootSize.height.coerceAtLeast(1f)
        return Rect(bounds.left*sx,bounds.top*sy,bounds.right*sx,bounds.bottom*sy)
    }
}
@Stable internal class PageOrigins {
    private class Source(var coordinates:LayoutCoordinates,var radius:Float,var last:PageOrigin?=null)
    private val sources=mutableMapOf<String,Source>()
    fun register(key:String,coordinates:LayoutCoordinates,radius:Float) {
        val source=sources[key]
        if(source==null)sources[key]=Source(coordinates,radius)
        else {source.coordinates=coordinates;source.radius=radius}
    }
    fun get(key:String):PageOrigin? {
        val source=sources[key]?:return null
        val coordinates=source.coordinates
        if(coordinates.isAttached) {
            val root=coordinates.findRootCoordinates()
            val rect=root.localBoundingBoxOf(coordinates,clipBounds=false)
            val size=root.size.toSize()
            if(rect.width>1f&&rect.height>1f) {
                val previous=source.last
                if(previous==null||previous.bounds!=rect||previous.radius!=source.radius||previous.rootSize!=size)
                    source.last=PageOrigin(rect,source.radius,size)
            }
        }
        return source.last
    }
}
internal val LocalPageOrigins=staticCompositionLocalOf<PageOrigins?>{null}

/** Attach to the complete clickable surface, before its content padding. */
@Composable internal fun Modifier.pageOrigin(key:String,radius:Dp=24.dp):Modifier {
    val registry=LocalPageOrigins.current
    val density=LocalDensity.current
    return if(registry==null)this else onGloballyPositioned { coordinates ->
        // Root-tab scaling reports global placement every frame. Retain coordinates here,
        // and calculate the full transform only for a page that actually flies.
        registry.register(key,coordinates,with(density){radius.toPx()})
    }
}

@Stable private class PageFlight(val route:String,val origin:PageOrigin?) {
    var open by mutableStateOf(true)
    val progress=Animatable(0f)
}

private class FlightViewport { var size=IntSize.Zero }

@Immutable private data class FlightClip(val bounds:Rect,val radiusPx:Float):Shape {
    override fun createOutline(size:Size,layoutDirection:LayoutDirection,density:Density):Outline {
        val outline=G2RoundedRectangle(with(density){radiusPx.toDp()}).createOutline(bounds.size,layoutDirection,density)
        return Outline.Generic(Path().apply {addOutline(outline);translate(bounds.topLeft)})
    }
}

/** Each destination owns a cancellable spring and a replay layer. Closing pages are replayed
 * without placing their content, so they cannot intercept a new click underneath. Multiple
 * flights can therefore finish independently, and reopening reverses the existing spring. */
@Composable internal fun AnchoredPages(destination:String?,origins:PageOrigins,content:@Composable (String)->Unit) {
    val flights=remember{mutableStateListOf<PageFlight>()}
    LaunchedEffect(destination) {
        flights.forEach{it.open=it.route==destination}
        if(destination!=null) {
            val existing=flights.firstOrNull{it.route==destination}
            if(existing==null)flights.add(PageFlight(destination,origins.get(destination)))
            else {flights.remove(existing);flights.add(existing)}
        }
    }
    for(flight in flights.toList()) key(flight) {
        LaunchedEffect(flight.open) {
            flight.progress.animateTo(if(flight.open)1f else 0f,
                spring(dampingRatio=.9f,stiffness=360f,visibilityThreshold=.0005f))
            if(!flight.open)flights.remove(flight)
        }
        val snapshot=rememberGraphicsLayer()
        val density=LocalDensity.current
        fun frame(size:Size):Rect {
            val origin=(if(flight.open)flight.origin else origins.get(flight.route)?:flight.origin)
            val source=origin?.inViewport(size)?:Rect(size.width*.4f,size.height*.45f,size.width*.6f,size.height*.55f)
            return androidx.compose.ui.geometry.lerp(source,Rect(Offset.Zero,size),flight.progress.value.coerceIn(0f,1f))
        }
        val outside=remember{Path()}
        val viewport=remember{FlightViewport()}
        Layout(content={
            Box(Modifier.then(if(flight.open)Modifier else Modifier.clearAndSetSemantics{}).graphicsLayer {
                compositingStrategy=CompositingStrategy.Offscreen
                // Native rectangular clipping bounds the effect texture to the actual
                // window, rather than allocating a screen-sized raster for a tiny card.
                clip=true;shape=RectangleShape
            }.drawWithContent {
                val p=flight.progress.value.coerceIn(0f,1f)
                val radius=((flight.origin?.radius?:with(density){24.dp.toPx()})*(1f-p)+with(density){28.dp.toPx()}*p)
                    .coerceAtMost(size.minDimension/2f)
                val outline=FlightClip(Rect(Offset.Zero,size),radius).createOutline(size,layoutDirection,this)
                drawContent()
                outside.rewind();outside.fillType=PathFillType.EvenOdd
                outside.addRect(Rect(Offset.Zero,size));outside.addOutline(outline)
                drawPath(outside,Color.Black,blendMode=BlendMode.DstOut)
            }) {
                Layout(content={
                    Box(Modifier.fillMaxSize().graphicsLayer {
                        val full=viewport.size.toSize()
                        val rect=frame(full)
                        transformOrigin=TransformOrigin(0f,0f)
                        val uniform=maxOf(rect.width/full.width.coerceAtLeast(1f),rect.height/full.height.coerceAtLeast(1f))
                        scaleX=uniform;scaleY=uniform
                        alpha=(flight.progress.value*6f).coerceIn(0f,1f)
                    }.drawWithContent {
                        if(flight.open||snapshot.size==IntSize.Zero)drawContent()else drawLayer(snapshot)
                    }) {
                        Box(Modifier.fillMaxSize().layout { measurable,constraints ->
                            val child=measurable.measure(constraints)
                            layout(child.width,child.height){if(flight.open||snapshot.size==IntSize.Zero)child.place(0,0)}
                        }.drawWithContent {
                            snapshot.record{this@drawWithContent.drawContent()}
                            drawLayer(snapshot)
                        }) { content(flight.route) }
                    }
                }) { measurables,windowConstraints ->
                    // The screen's layout constraints never follow the animated window.
                    // Forms, text and hit regions keep their full-size layout and uniform
                    // scale; only this cheap outer container changes its raster bounds.
                    val full=viewport.size
                    val page=measurables.single().measure(Constraints.fixed(full.width,full.height))
                    layout(windowConstraints.maxWidth,windowConstraints.maxHeight){page.place(0,0)}
                }
            }
        },modifier=Modifier.fillMaxSize()) { measurables,constraints ->
            viewport.size=IntSize(constraints.maxWidth,constraints.maxHeight)
            val rect=frame(viewport.size.toSize())
            val window=measurables.single().measure(Constraints.fixed(
                kotlin.math.ceil(rect.width).toInt().coerceAtLeast(1),
                kotlin.math.ceil(rect.height).toInt().coerceAtLeast(1)))
            layout(viewport.size.width,viewport.size.height){window.place(rect.left.toInt(),rect.top.toInt())}
        }
    }
}
