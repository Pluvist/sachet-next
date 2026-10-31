package com.pluvist.sachet.next

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.nestedscroll.*

internal class ListNavigationViewport(private val state:LazyListState):BottomNavigationViewport {
    private val average get()=state.layoutInfo.visibleItemsInfo.let{items->if(items.isEmpty())0f else items.sumOf{it.size}.toFloat()/items.size}
    override val rangePx get()=(average*state.layoutInfo.totalItemsCount-(state.layoutInfo.viewportEndOffset-state.layoutInfo.viewportStartOffset)).coerceAtLeast(0f)
    override val distanceToStartPx get()=average*state.firstVisibleItemIndex+state.firstVisibleItemScrollOffset
    override val atStart get()=!state.canScrollBackward
    override val atEnd get()=!state.canScrollForward
    override val isScrolling get()=state.isScrollInProgress
}
internal class ScrollNavigationViewport(private val state:ScrollState):BottomNavigationViewport {
    override val rangePx get()=state.maxValue.toFloat()
    override val distanceToStartPx get()=state.value.toFloat()
    override val atStart get()=!state.canScrollBackward
    override val atEnd get()=!state.canScrollForward
    override val isScrolling get()=state.isScrollInProgress
}
internal class PagerNavigationViewport(private val state:PagerState):BottomNavigationViewport {
    override val rangePx get()=((state.pageCount-1)*state.layoutInfo.pageSize).toFloat()
    override val distanceToStartPx get()=(state.currentPage+state.currentPageOffsetFraction)*state.layoutInfo.pageSize
    override val atStart get()=!state.canScrollBackward
    override val atEnd get()=!state.canScrollForward
    override val isScrolling get()=state.isScrollInProgress
}
internal class GridNavigationViewport(private val state:LazyGridState,private val columns:Int):BottomNavigationViewport {
    private val rowHeight get()=state.layoutInfo.visibleItemsInfo.firstOrNull()?.size?.height?.toFloat()?:0f
    override val rangePx get()=(rowHeight*((state.layoutInfo.totalItemsCount+columns-1)/columns)-(state.layoutInfo.viewportEndOffset-state.layoutInfo.viewportStartOffset)).coerceAtLeast(0f)
    override val distanceToStartPx get()=rowHeight*(state.firstVisibleItemIndex/columns)+state.firstVisibleItemScrollOffset
    override val atStart get()=!state.canScrollBackward
    override val atEnd get()=!state.canScrollForward
    override val isScrolling get()=state.isScrollInProgress
}

internal val LocalNavigationViewportBinding=staticCompositionLocalOf<(BottomNavigationViewport)->Unit>{{}}

/** Bind the actual scrolling child before the outer observer handles consumed distance. */
@Composable internal fun Modifier.navigationViewport(viewport:BottomNavigationViewport,enabled:Boolean=true):Modifier {
    val bind by rememberUpdatedState(LocalNavigationViewportBinding.current)
    val active by rememberUpdatedState(enabled)
    SideEffect{if(enabled)bind(viewport)}
    return nestedScroll(remember(viewport){object:NestedScrollConnection {
        override fun onPreScroll(available:Offset,source:NestedScrollSource):Offset { if(active)bind(viewport);return Offset.Zero }
    }})
}
