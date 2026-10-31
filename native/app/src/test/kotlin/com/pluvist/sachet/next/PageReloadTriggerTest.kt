package com.pluvist.sachet.next

import org.junit.Assert.*
import org.junit.Test

class PageReloadTriggerTest {
    @Test fun ordinaryRecompositionAndLoadingDoNotContinuouslyRestartTheFade() {
        val trigger=PageReloadTrigger(false,0)
        repeat(10){assertNull(trigger.update(false,0))}
        assertEquals(ReloadFadeAction.Hide,trigger.update(true,0))
        repeat(10){assertNull(trigger.update(true,0))}
        assertEquals(ReloadFadeAction.Reveal,trigger.update(false,0))
        assertNull(trigger.update(false,0))
    }
    @Test fun cacheReloadThatFinishesBetweenFramesStillFadesOnce() {
        val trigger=PageReloadTrigger(false,3)
        assertEquals(ReloadFadeAction.Replay,trigger.update(false,4))
        assertNull(trigger.update(false,4))
        assertEquals(ReloadFadeAction.Replay,trigger.update(false,5))
    }
    @Test fun dependentRequestsCoalesceUntilAllLoadsAreReady() {
        val trigger=PageReloadTrigger(true,0)
        assertNull(trigger.update(true,1))
        assertNull(trigger.update(true,2))
        assertEquals(ReloadFadeAction.Reveal,trigger.update(false,3))
        assertNull(trigger.update(false,3))
    }
    @Test fun aFailureAndFollowingRetryEachFinishWithOneFade() {
        val trigger=PageReloadTrigger(true,0)
        assertEquals(ReloadFadeAction.Reveal,trigger.update(false,1))
        assertEquals(ReloadFadeAction.Hide,trigger.update(true,1))
        assertEquals(ReloadFadeAction.Reveal,trigger.update(false,2))
        assertNull(trigger.update(false,2))
    }
    @Test fun unrelatedRegionsStayStableAndOnlyChangedRegionReplays() {
        val form=PageReloadTrigger(false,listOf("学期","学院"))
        val results=PageReloadTrigger(false,0)
        assertEquals(ReloadFadeAction.Hide,results.update(true,0))
        assertNull(form.update(false,listOf("学期","学院")))
        assertEquals(ReloadFadeAction.Reveal,results.update(false,1))
        assertNull(form.update(false,listOf("学期","学院")))
        assertEquals(ReloadFadeAction.Replay,form.update(false,listOf("学期","学院","校区")))
        assertNull(results.update(false,1))
    }
}
