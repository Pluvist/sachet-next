# Course source-to-panel transitions

The course-status accessory opens into a lower floating glass rectangle. Schedule lessons and calendar days open into a centered rectangle. Source title/location/teacher move along curved paths; fixed-size details fade in without stretching. Both panel types retain Kyant G2 corners with a final 31dp radius (`NavigationBarSurfaceHeight / 2`). A slight page dim remains; no page-wide blur is applied.

## GPU thumbnail frost

An accepted click starts the spring immediately. The page-only backdrop is captured into a GPU texture with 1/8 of the window width and height (1/64 of its pixel count). Capture happens in the same draw frame, ahead of the panel. No idle/scroll-settled pre-render runs, and there is no `toImageBitmap()` readback or asynchronous readiness barrier before opening.

The raw thumbnail is progressively low-pass filtered while reducing it by two at each of three levels (1/16, 1/32, 1/64 of window dimensions). Each level uses three normalized nine-sample passes with a small radius in texture pixels; radii are chosen so their window-space variances combine to approximately 32dp. This avoids the separated shifted copies produced by the old large-step local sampling. Filtering is done once over the full window domain. Replay applies exactly one window-to-consumer transform instead of cropping and filtering again in the moving panel's local space. The original glass/refraction material receives this prefiltered backdrop with its additional frost radius set to zero. Text, outlines and controls stay at native resolution. Padded support receives the theme canvas color.

The thumbnail is generated for the current visible flight generation. Same-source reversal reuses it; changing to another source captures a new thumbnail when that flight starts. A window-size change regenerates the texture. The weekly timetable also has a bounded native raster layer so repeated backdrop samples do not replay every course glyph and axis label.

The source graph is acyclic: page-only plane → thumbnail → sampled frost → panel material/export → internal controls. Neither the panel nor the persistent bottom navigation is captured into the thumbnail. The capture node draws nothing onto the visible screen, preventing a final-size preparation panel from flashing before the transition.

## Input and interruption rules

- While a panel is opening or already open, a tap outside its moving rectangle only dismisses it. It never activates another source or an underlying page control.
- The gesture is classified at pointer-down and consumed through release. A single tap cannot become a replacement open merely because dismissal starts before its release. Background dragging is consumed and does not turn into a click.
- During return, a new source may still be opened without waiting for full closure. Same-source reopening reverses the existing flight with its current velocity. A different source accelerates the old return (0.85/950 spring), then opens the latest requested source. Repeated replacement requests overwrite the pending intent.
- Footer chrome wins hit testing over page cards, and covered course cards are excluded. Blank taps during return cancel pending replacement.
- Normal opening uses a 0.68/430 spring; normal closing uses 0.70/520. Inside-panel lesson selection updates the existing panel instead of nesting another panel.
- The close control uses an explicit live material backdrop and the default MeiloX/Glasmio regular sampled material, with a theme-aware icon color. It never falls back to a missing ambient backdrop.

## Validation (2026-10-31)

71 JVM tests pass, including geometry/curve/radius checks, pending-open exclusion, return reversal, latest-intent replacement, cancellation and opening-state outside taps that cannot create another open. Optimized preview compilation passes; Android vital lint is excluded from the local build.

The final thumbnail renderer and pointer-down interceptor have not yet completed a physical-device visual/latency run. The independent emulator could not start because this machine lacks the Android Emulator hardware-acceleration driver; no virtualization configuration was changed. Earlier frame counts belong to superseded renderers and are not used to claim latency or a <=5% missed-deadline rate for this candidate.

Preview upgrades preserve saved account data and do not replace the formal app. Raw screenshots, UI dumps and timing files stay in ignored `native/artifacts`.

Installed preview APK SHA-256: 4619B4C41862A9EBE54022B8E6BD7F37080539ECA0F2932A37048C1C875FF8CB

### Stripe/distortion repair

The reported device screenshot showed plaid/ghost copies across the status panel. The sparse quarter-resolution sampler was replaced by the progressive whole-window pyramid above. Glasmio's existing normalized sampler is exposed for reuse; other consumers retain their existing behavior.

The repaired preview was installed preserving app data. Four real-device smoke checks passed: status remains open, close button returns, outside tap over a course while opening only dismisses, and the same outside tap while open only dismisses. The inspected first screenshot had no plaid. The follow-up visual comparison on populated week 10 was interrupted by an incoming call and user navigation, so that comparison is incomplete; automation stopped without interacting with the call. No timing claim is based on these checks.

### MeiloX opacity restoration

MeiloX 537c05f0158c2a489a06b9152dad08e3e8e97242 uses Glasmio 864e958676e38c5416d573c6affeaf4b0279be98 with ordinary GlassAppearance transparency defaults. The app removes the 0.85/0.95 forced blur-opacity floors, the bottom white 0.14 coating, the modal black/white 0.08/0.12 coatings and the bottom group's static 0.86/0.92 alpha. The original regular face recipe and default sampled close-button material are restored. Page-edge gradients, modal dimming and visibility/text animation fades remain separate from glass material opacity.

The additional upstream material test task could not resolve its separate runtime classpath in offline mode. The normal app build/test tasks are verified separately; source parity of the restored renderer is checked directly against the pinned clean upstream checkout.

Opacity candidate verification: optimized preview build and 71 application tests passed; the restored NavigationMaterialRenderer source matches the clean pinned upstream checkout after newline normalization. Preview replacement installation succeeded. The resting bottom controls were visually inspected. The automated open/close smoke assertion did not complete successfully in this run (the expected open panel was absent at inspection); no fresh crash was recorded, and this is not counted as a passed panel check.

Opacity-restored preview SHA-256: E6510BC0DDD7276484331E203FA2D782024801F24B245D752BD3CD3870508859

Follow-up visual inspection: the light-theme resting footer and dark-theme open status panel/close control were captured and inspected after the update. The default sampled close control rendered as a normal gray glass circle with a white icon in dark appearance. No black-source artifact was observed in that capture. On the final inspection the panel was already closed, so no extra click was sent. These are visual observations, not a completed timing benchmark.

### Clearer material and stronger refraction

The latest visual tuning supersedes the exact-default opacity restoration: regular light white fill is reduced from 20% to 12%, with the light black/lift coefficient reduced from 0.40 to 0.30. Dark roll-off is reduced by 25%, consistently for both explicitly selected materials and automatic size classes. Refraction increases by 25% in the app, bottom-control and course-panel scopes. The GPU blur pyramid and all animation/input rules are retained. Existing library size-class test expectations reflect the new dark endpoints; the separate upstream test task still requires uncached runtime dependencies, so application checks are reported separately.

Clarity candidate: optimized preview build and 71 application tests passed. Installed APK SHA-256: `A8F214BF617AC9099627C9EFB315A2C8A8E43D4230087D29B3C4E4BECFE0CFAF`. The captured final phone frame showed the dark weekly schedule's resting footer; an open detail panel was not present in that capture, so no panel visual/performance pass is claimed from it.

### Subtle course-detail rebound

Individual course-card detail flights now use damping ratio 0.88 for both normal opening and closing, retaining stiffness 430/520 and interruption velocity. Sampled zero-velocity curves keep overshoot below 1% and settle within one second. The course-status/day panels and accelerated replacement returns keep their previous motion. Geometry, corner curvature, GPU thumbnail glass and outside-tap/retarget rules are unchanged.

### Simultaneous status and companion flights

The accepted status request drives both panel expansion and an independent companion spring on the same frame; neither waits for the other. Main navigation leaves to the left, the personal control and contextual search circle leave to the right, using the existing backdrop-aware navigation placement and fade guards. The departure/return spring uses damping 0.9 and stiffness 500. Closing immediately retargets it home; reopening during return reverses its current position/velocity. Detail pages with already-hidden navigation retain that route visibility, and the search owner/width reservation stays intact. Individual course detail requests do not trigger this departure.

The panel/source geometry, status capsule width and glass material remain unchanged. Pending cancellation cannot leave companions latched offscreen. Unit tests cover cancellation, return reversal and excluding non-status details. The final implementation intentionally has no pre-expansion wait, superseding the initially considered sequential flight.

Controlled device verification completed: status expansion and companion departure overlap in the recorded opening frames; rapid dismissal/reopening during return keeps the panel working; main navigation restores after closure. On the textbook page, the contextual search circle disappears for the status panel and returns afterward. The subsequent GPA-filter disclosure fix leaves this motion implementation unchanged. No frame-rate percentage is inferred from the screen recordings.
