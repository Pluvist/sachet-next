# NexioSchedule source port

Source: https://github.com/HaoZai000/NexioSchedule
Revision: ab6c7a757fb7e06f48c2da18cd7d7a87c280e830
Port date: 2026-10-13. Changes and Flutter integration by Pluvist.

The original source files are retained alongside this notice. The Kotlin components
are translated to `nexio_bottom_tabs.dart`, `nav_bottom.dart`, and `miuix_popup.dart`.
Their AGPL-3.0 license is preserved; the combined application is distributed under
AGPL-3.0. Original Sachet MIT permissions and copyrights remain in LICENSE-MIT.

`Shaders.kt` carries Copyright 2025 Kyant and Apache-2.0. Its rounded rectangle SDF,
gradient, refraction and seven-sample dispersion are adapted in nexio_lens.frag.
The sampling API changes from AGSL content.eval to Flutter GLSL texture sampling.

Dimensions: 56dp panel, 48dp selector, 4dp inset, 24dp icons, 11sp labels;
two tabs use 42 percent of screen width, three use 63 percent. Menus morph from
42dp circular triggers to 200dp panels with 25dp corner radii and 15.6sp item text.
Original values/gestures are retained; Flutter renderer-specific integration uses
page-only snapshots for refraction and backdrop filters for blur. Snapshot data is
memory-only and refreshed on page/scroll/gesture boundaries, not every idle frame.
Compose layer capture, predictive-back progress and exact nested symbol refraction
are not available in this Flutter integration; the port does not claim pixel equality.
