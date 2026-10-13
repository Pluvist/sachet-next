# HyperCeiler onboarding layout adaptation

Source: https://github.com/ReChronoRain/HyperCeiler
Revision: 5e4686069dd7ab1f3697e256d5fc7d68fb73e317
Copyright (C) 2023-2026 HyperCeiler Contributions. AGPL-3.0.
Adapted by Pluvist on 2026-10-13, in lib/pages/intro_screen/intro_screen.dart.

The original XML sources and license are retained here. The Flutter adaptation
uses the centered 90dp mark, 32sp step title, 14sp description, 35dp inset,
70dp circular forward control and 44dp bottom gap. The flow is welcome/glow, account login, then completion.
HyperCeiler marks and text are replaced with Sachet Next branding. The original glow.glsl noise, color interpolation, stripes, opening circle and
GlowPainter uniform defaults are preserved in the Flutter fragment shader. The
Android runtime shader entry point is adapted to FlutterFragCoord; system-specific
MIUI/fan activity transitions are not included. The mark is redrawn in monochrome. Smaller screens and larger text scroll instead of overlapping.
