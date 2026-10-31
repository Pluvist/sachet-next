# Kyant0/Shapes

Upstream: https://github.com/Kyant0/Shapes
Dependency: `io.github.kyant0:shapes:1.2.1` (Apache-2.0).

The native application and Glasmio core depend on this published version explicitly.
`G2RoundedRectangle` adapts Material's CornerBasedShape contract to Shapes'
UnevenRoundedRectangle outlines, retaining logical/RTL corners and density-scaled sizes.
Cards, menus, dialogs, modal windows, course bars, icon badges and default glass controls
use this shared outline adapter; capsules and icon-button surfaces use Shapes' Capsule.
Window-edge transitions use Shapes' UnevenRoundedRectangle with the system corner insets.

The original Capsule dependency remains for the library's analytic contact/adhesion path
segments and as a compatibility branch in optimized clipping; these are not substituted
for the new regular window outlines. The G2 corner-only clip optimization is retained.

No Shapes source is copied into the project. The published dependency retains its own
license and copyright notices. The application's own adapter is a Xachet modification.
