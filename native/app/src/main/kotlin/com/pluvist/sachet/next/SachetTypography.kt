package com.pluvist.sachet.next

import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.sp
import io.github.neoruaa.glasmio.core.glasmioTypography

internal const val SachetTextScale = .95f
// Use the full requested variable weight instead of the former 80% treatment.
// Shared by Compose text and the timetable's cached native text paints.
internal fun miSansWeight(weight:Int)=weight.coerceIn(150,800)

// Register the continuous axis, not static font copies or synthesized bold. Entries share one
// resource; Compose loads and caches only the weights actually requested (including animated ones).
@OptIn(ExperimentalTextApi::class)
internal val MiSansFamily = FontFamily((1..1000).map { weight ->
    Font(R.font.misans_vf, weight=FontWeight(weight),
        variationSettings=FontVariation.Settings(FontVariation.weight(miSansWeight(weight))))
})

/** Text-only scale: dp sizes and touch targets retain their original dimensions. */
@Composable internal fun SachetTextEnvironment(content:@Composable ()->Unit) {
    val system=LocalDensity.current
    val scaled=remember(system){Density(system.density,system.fontScale*SachetTextScale)}
    CompositionLocalProvider(LocalDensity provides scaled,
        io.github.neoruaa.glasmio.core.LocalGlasmioLayoutFontScale provides system.fontScale,content=content)
}

internal val SachetTypography=glasmioTypography(MiSansFamily).let { base ->
    val leading=LineHeightStyle(LineHeightStyle.Alignment.Proportional,LineHeightStyle.Trim.None)
    base.copy(
        headlineLarge=base.headlineLarge.copy(fontWeight=FontWeight.SemiBold,lineHeight=42.sp,lineHeightStyle=leading),
        headlineMedium=base.headlineMedium.copy(fontWeight=FontWeight.SemiBold),
        headlineSmall=base.headlineSmall.copy(fontWeight=FontWeight.SemiBold),
        titleLarge=base.titleLarge.copy(fontWeight=FontWeight.Medium),
        bodyLarge=base.bodyLarge.copy(lineHeight=24.sp,lineHeightStyle=leading),
        bodyMedium=base.bodyMedium.copy(lineHeight=22.sp,lineHeightStyle=leading),
        bodySmall=base.bodySmall.copy(lineHeight=19.sp,lineHeightStyle=leading),
    )
}
