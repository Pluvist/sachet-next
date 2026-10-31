/*
 * Copyright 2025 Kyant
 * Copyright 2026 Glasmio contributors
 * SPDX-License-Identifier: Apache-2.0
 *
 * Adapted from AndroidLiquidGlass 2.0.1 generic capture/effect infrastructure.
 * Modified for Glasmio's owned namespace and Android material renderer.
 */

package io.github.neoruaa.glasmio.glass.render.effects

import androidx.annotation.FloatRange
import androidx.compose.ui.graphics.asComposeRenderEffect
import androidx.compose.ui.graphics.TileMode
import io.github.neoruaa.glasmio.glass.MultiSampleBlurRenderer
import io.github.neoruaa.glasmio.glass.render.BackdropEffectScope
import io.github.neoruaa.glasmio.glass.render.isRuntimeShaderSupported
import io.github.neoruaa.glasmio.glass.render.cachedResource

fun BackdropEffectScope.blur(
    @FloatRange(from = 0.0) radius: Float,
    edgeTreatment: TileMode = TileMode.Clamp
) {
    if (!isRuntimeShaderSupported()) return
    if (!radius.isFinite() || radius <= 0f) return

    padding=maxOf(padding,radius*2.5f)
    val sampler=cachedResource("Glasmio.MultiSampleBlur"){MultiSampleBlurRenderer()}
    renderEffect=sampler.effect(radius,renderEffect?.asAndroidRenderEffect(),
        size.width+padding*2f,size.height+padding*2f,edgeTreatment==TileMode.Clamp)?.asComposeRenderEffect()
}
