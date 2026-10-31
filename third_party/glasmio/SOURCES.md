# Glasmio provenance

Upstream: https://github.com/NEORUAA/Glasmio
Revision: 864e958676e38c5416d573c6affeaf4b0279be98
License: Apache-2.0; upstream LICENSE, licenses/ and THIRD_PARTY_NOTICES.md are retained.
The six library modules are included. The sample application and its font assets are not copied.

MeiloX reference: https://github.com/NEORUAA/MeiloX. Sachet uses the same GlasmioNavigationBarWithTrailingItem and GlassSurface APIs, regular 62 dp navigation allocation and 48 dp accessory geometry. The navigation material, lens and drag physics are the upstream implementation. Music data/content is replaced with lesson state.

Integration changes: settings include only the library modules, support an optional local Maven cache, and permit Windows non-ASCII source paths. Library builds still use upstream NDK 27.1 and CMake 3.22.1. On Windows CMake is built from an ASCII staging directory.

Performance patches: isolated backdrop source display lists with graphicsLayer boundaries in GlassBackdrop and GlasmioPageBody. DrawBackdropModifier's coordinate notification compares the window matrix and size before writing a neverEqualPolicy state, avoiding notifications for identical positioning callbacks while retaining moving-source updates. Shader formulas, tab geometry and animation springs are retained; subsequent user-requested material changes are listed below.

Baseline material-opacity restoration (2026-10-31; superseded by the clarity tuning below): `NavigationMaterialRenderer.kt` is restored byte-for-byte after newline normalization to the pinned upstream source (864e958676e38c5416d573c6affeaf4b0279be98), also pinned by MeiloX. This supersedes the earlier lighter-face adjustment. Regular light material again uses its original 0.20 white face fill and 0.40 black parameter; dark roll-off is 0.40/0.65, and the reference saturation/white transforms are restored. The host removes additional white/black frost coatings, forced minimum blur opacity and constant bottom-group opacity. Close controls use the default sampled regular material with an explicit backdrop. Transition fades remain independent; current blur/refraction tuning and the GPU thumbnail pyramid are retained.

Requested Shapes migration: default continuous rectangles in core/UI/glass now use a CornerBasedShape adapter backed by Kyant0/Shapes 1.2.1. Glass icon buttons use Shapes Capsule and window-edge transitions use UnevenRoundedRectangle. Corner-only clipping recognizes the adapter, retaining the disjoint mask optimization. Internal analytic contact path segments remain upstream Capsule code; see `third_party/shapes/SOURCES.md`.

Requested typography polish: large list-page headings use semibold with a 6dp subtitle gap. IosLists rows use 52/68dp minimums, expand with content/font scale, allow wrapped labels, and stack long details at larger text settings. The host supplies an Android/CJK typography override and neutral tracking; the upstream Dynamic Type metric tables and font assets are not changed.

MiSans host integration: LocalGlasmioLayoutFontScale retains the original accessibility factor when the host applies a text-only 0.8 scale via LocalDensity. List-row responsiveness uses that layout factor; rendering caches continue to key off the actual text density. Default library typography/families remain unchanged for other hosts.

Bottom navigation geometry: GlasmioNavigationBarWithTrailingItem accepts an optional mainMaxWidth while leaving its detached trailing control pinned to the host's trailing edge. The app supplies 200dp in a full-width host. Existing default geometry and selection/morph springs are unchanged for other callers.

Scoped optics: GlassAppearance adds default-1 blurRadiusMultiplier and chromaticStrength. The native host overrides both to 1.8 only around bottom controls. Background/lens-source Gaussian radii, morph capture support and spectral vectors honor those values; stronger regular bottom glass uses explicit chromatic Gaussian optics. All other hosts retain original defaults. The former constant bottom ModulateAlpha attenuation is removed by the opacity restoration above; only interaction/visibility fades remain.

Latest optical revision: bottom chromaticStrength returns to 1.0, blur stays 1.8 and the new default-1 refractionAmountMultiplier is overridden to 1.35. Native geometry scales inner/outer ray amounts independently, while explicit chromatic vectors divide by that multiplier to retain their original spectral separation. Other callers keep default reference optics.

Current user-requested clarity tuning: regular light face fill is 0.12 (from 0.20) and the light black/lift parameter is 0.30 (from 0.40). Regular dark luminance roll-off is reduced by 25% to 0.30/0.4875; automatic measured-size resolution uses the same endpoints. The clear material remains unchanged. The native host increases refraction by 25% in all three scopes: ordinary controls 1.0→1.25, bottom controls 1.6→2.0, and course panels 1.2→1.5. Blur strengths, spectral separation, animation fades and geometry remain as previously implemented. No extra frost coating or constant group-alpha attenuation is reintroduced.
