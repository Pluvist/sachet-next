# MeiloX Compose migration

Baseline: Xachet v0.19.77, commit 41027b2. Work branch: feat/meilox-compose.

## 0.19.78 production cutover

The user requested publication of the current native implementation on 2026-10-31. Version 0.19.78 uses `native/` for production, retaining the formal package and signing identity. The sections below are a chronological work log; early open-gate lists describe their point in time. Current academic results are in [the repair report](native-academic-repair-2026-10-31.md), and compatibility limits are in [the release notes](releases/0.19.78.md). Preview verification does not establish a real-account production signed-upgrade test. System live-activity promotion and launcher behavior remain device-dependent.

## Build gates

1. Inventory and provenance: preserve password/cookie login, remembered credentials, session recovery, automatic schedule refresh, offline course/color files, building-dependent time axes, portrait/landscape week/month/semester views, grades, exams, GPA, textbooks, cultivation, free classrooms, PDF transcripts, settings, onboarding, ICS export, both widget sizes and live activities. Record source revisions and licenses.
2. Native shell: independent `native/` Gradle build with Kotlin and Compose; use the unmodified Glasmio navigation/material components used by MeiloX. Build the APK before moving domain functionality. MeiloX and Glasmio currently require API 33+, SDK 37 and JDK 21+. No Apple font assets are copied.
3. Domain data: Kotlin repositories, secure credentials, deterministic time calculations, atomic caches, single-flight session recovery and cancellation. Test parsing and time boundaries. Compare query parameters with the original Dart services before marking each query complete.
4. Screens: native home, course accessory/details, timetable modes, query forms/results, profile, settings, onboarding and permissions. The music mini-player becomes the current/upcoming lesson accessory; its detail sheet becomes the course timeline. Use the same upstream glass renderer, navigation geometry and drag physics.
5. Validation: build and unit tests, device smoke/interaction tests, read-only real-account queries with user authorization, widget/activity checks, orientation/paging checks and frame timing. Record measured results, failures and unverified functions; a successful build alone is not feature parity.

## Cutover policy

The existing Flutter production build remains runnable until native feature parity passes. `native/` is an independent build, not a Flutter page wrapper. Main-entry replacement and release publishing happen after the gates, rather than making incomplete native screens the production entry.

## Performance constraints

Use lifecycle-aware state, lazy lists and stable item identities. Keep network/parsing/files on IO; use one application session and one schedule snapshot. Do not record glass controls into their own background source. Countdown updates must not recompose the entire timetable. Reuse upstream interruptible motion instead of adding competing animation controllers.

## Sources

- MeiloX: https://github.com/NEORUAA/MeiloX (GPL-3.0; reference layouts and accessory behavior).
- Glasmio: https://github.com/NEORUAA/Glasmio, revision 864e958676e38c5416d573c6affeaf4b0279be98 (Apache-2.0; vendored source and third-party notices retained).

## Validation log

OnePlus PLZ110 is connected and authorized for read-only account testing.

### Implemented, awaiting live-account regression

The independent native app includes password/Cookie/WebView login, legacy encrypted storage compatibility, single-flight relogin, schedule refresh and atomic cache, ordinary/staggered lesson times, week/month/semester views, settings/appearance, managed JSON files, six academic query forms and caches, PDF transcript viewing, course/exam ICS export, onboarding/permissions, both widget providers and course live activities. This inventory describes implemented code, not successful live-campus verification.

The actual Glasmio navigation and glass renderer are used. The music accessory/detail sheet contains current/upcoming courses and the daily lesson timeline. Static inner-page backdrop planes and separate display-list boundaries prevent self-sampling crashes. The original Flutter production entry is still available while the native version is evaluated.

### Observed checks, 2026-10-31

- Debug APK and optimized benchmark APK build successfully. The performance-only benchmark build excludes vital lint; production lint is not marked passed.
- 32 JVM tests pass, with zero failures/errors: 9 course/time/parser tests, 11 original live timeline tests, 3 academic request tests, 4 calendar export tests, 3 scroll-away navigation tests and 2 month-count parity tests.
- Installed and launched the native preview and isolated benchmark on OnePlus PLZ110. Walked through onboarding and root tab switching; tested course details, horizontal week paging, landscape double-week display and portrait double-month paging. A cropped sixth calendar row and an undersized landscape timetable viewport were found and fixed. Final device recheck confirmed the sixth row (including November 30) is fully visible.
- A no-touch four-second observation produced no additional rendered frames in the debug preview. This is a short observation, not a battery-life measurement.
- Optimized, warmed synthetic fixture (35 course blocks/week, 60 weeks): 16 root-tab taps at 300 ms intervals followed by 3 horizontal week swipes. Android gfxinfo reported 587 frames, 4 missed frame deadlines (0.68%), P50 13 ms, P90 16 ms, P95 20 ms, P99 31 ms. Initial/cold interaction and rotation were substantially slower; this does not guarantee every frame meets a high-refresh deadline. Test scripts and screenshots are kept in ignored native/artifacts locally.

### Open gates

- Preview login by the user. The formal app and preview have separate Android UIDs, so preview cannot silently read the formal app's saved credentials.
- Read-only live checks for schedule, grades, exams, GPA, textbooks, classrooms, cultivation and PDF transcripts; session expiry/relaunch recovery and per-account cache isolation.
- Final widget appearance/update checks on the launcher and promoted live-activity behavior with a real schedule and user-granted system permissions.
- Additional cold-start/rotation/drag performance checks, production lint and formal entry/signing cutover. No release has been published for this migration.

### Requested layout refinement

The home screen now restores the original two-column 76 dp feature-card layout: cultivation, textbooks, exams, grades, GPA, transcript, library, physics lab and campus authentication. The current/next/classroom cards and campus-service list are also on home. The separate services route/tab is removed; home and timetable share the left-aligned main capsule, with profile in the adjacent circle. Feature and profile icons use distinct Apache-licensed Material vectors instead of a shared calendar placeholder.

MeiloX's scroll-away state machine is adapted with provenance under `third_party/meilox`. Real home/list, week-grid scroll, vertical month pager and semester-list viewports bind to the non-consuming observer. Forward consumed scroll compacts navigation and moves the 48 dp course accessory into the inline slot; sufficient reverse scroll or a compact-navigation tap reveals navigation. Its original 64 dp activation threshold, reverse handling and .8 damping/.3 response spring are retained. Three JVM tests cover forward/reverse transitions, short-content eligibility, non-consumption and explicit expansion.

Device recheck on the unlocked OnePlus verified home icons/cards/services, forward compaction, reverse reveal, compact navigation expansion, tab switching, compact course-detail tapping and system-back dismissal, landscape left alignment, and both light/dark appearances. The initial accessory integration lost its glass backplate at the compact endpoint in dark mode; it now uses a separately measured/placed 48 dp glass child in a fixed slot, driven by the same spring, without applying the player's additional shader morph displacement. The fixed debug APK was rebuilt (30 tests pass), installed and both endpoints rechecked. The device's original light mode, automatic rotation and plugged-in wake setting were restored. Real academic account validation remains pending.

The regular glass material has a lighter face fill and less luminance processing in both themes. Refraction geometry and gesture springs remain unchanged; the exact recipe differences are recorded in `third_party/glasmio/SOURCES.md`. Previous frame measurements above predate this layout refinement and are not a measurement of its final animation.

### Shapes and calendar viewport refinement

Explicit `io.github.kyant0:shapes:1.2.1` dependencies now back rounded application surfaces through `G2RoundedRectangle`, a Material CornerBasedShape adapter using Shapes UnevenRoundedRectangle. Menus, sheets, cards, course bars and icon badges share these outlines; navigation/icon-button capsules use Shapes Capsule. Glass clipping keeps its disjoint-corner optimization. Native window-edge transitions use Shapes with physical system-corner mapping, including RTL. Internal analytic adhesion segments retain their upstream path representation; see `third_party/shapes/SOURCES.md`.

Home's top-right profile action is removed; the bottom profile circle remains. Week content has narrower outer gutters, 18% greater vertical scale, and larger day/date/time-axis type. Monthly pages reserve the measured bottom chrome height instead of a fixed 179dp blank area. Portrait keeps two months per vertical page; landscape fits one month and starts with compact navigation. Semester view uses two columns in portrait, three in landscape, adjusts row heights to the available viewport, and remains scrollable when a short window or larger font needs more space. Six months and their final dates fit in portrait at the tested device's default font size.

Month section counts are memoized once per month using a pure date/week calculation instead of constructing daily lesson/Instant objects for every cell during composition. Tests compare the result against CourseClock across month/week boundaries. Calendar date taps retain spoken date/section counts and the existing lesson-detail interaction.

Debug and R8 benchmark APKs built successfully after these changes (performance-only vital-lint exclusions unchanged). On OnePlus PLZ110, checked the removed home action, enlarged week rendering, complete portrait double-month dates, portrait six-month grid, landscape full-month rendering, and bottom navigation retention. Synthetic fixture interaction test covered home forward/reverse scrolling, week horizontal/vertical gestures, month vertical paging, semester scrolling and root tab switches. During this 892-frame active-interaction sample, gfxinfo reported 28 missed deadlines (3.14%), P50 16ms, P90 21ms, P95 26ms, P99 48ms. This differs from the earlier tab-only sample and is not a before/after comparison or a guarantee of zero high-refresh frame drops. No crash was observed. Final debug APK installed to the preview; automatic rotation and original plugged-in wake behavior restored.

### Typography polish

Reference: [Apple HIG Typography](https://developer.apple.com/cn/design/human-interface-guidelines/typography), read through Apple's official article JSON when the localized landing page required JavaScript. Applied its semantic hierarchy, legibility and larger-text layout guidance to Android system fonts and `sp`, rather than bundling Apple font assets or equating platform units.

SachetTypography retains the 34/28/22/20/17 style hierarchy, uses semibold headings and regular readable body copy, neutral system-font tracking, 24sp Chinese body leading, and untrimmed font extents. Large-title/date spacing and section-heading emphasis are balanced; numeric countdowns use tabular figures, with more prominence on the current-course card. Course name/location/teacher fallbacks become 14/11/11sp, with explicit proportional leading and lighter hierarchy; the unset card-height fallback is 60dp to accommodate these readable defaults. Saved user appearance values are preserved. Week time labels are 11sp and their gutters/card scale respond to larger system text.

Common list cells use minimum heights and wrapped text; long detail values move beneath their label at font scale >=1.3. Home feature cards reduce columns based on width/font scale and meaningful icon badges scale modestly. Course/next-course panels allow more space for locations and timestamps. Larger-font onboarding can scroll instead of overflowing its fixed screen. Default and 1.3x device screenshots are retained locally; font scale is restored after the check. Existing navigation, academic calls and course-state logic are unchanged by this polish.

At font scale >=1.2, week day columns retain a readable minimum width and pan horizontally, with date headers synchronized and both time axes fixed. At default size all seven days still fit, and swiping continues to page between weeks. Device checks at 1.3x verified the home/course panels, single-column feature cards, growing profile rows, course-bar text, horizontal day panning and full `第12周` header after 11 normal-size week swipes. Latest debug and optimized benchmark builds pass, along with the existing 32 JVM tests. The native preview is updated; production entry/release remains under the earlier cutover gates. These checks cover the tested default and 1.3x settings, not every possible accessibility setting or live academic endpoint.

### Cresto motion, guide and MiSans refinement

Reference revision and attribution are under third_party/cresto. Root tabs use the reference's 0.95 scale/fade motion with separate incoming/outgoing timings; frame values are read in graphicsLayer rather than triggering page layout. Cached tabs remain mounted, hidden content has no semantics/touch handling, and a new selection cancels the previous animation from its current position. Detail AnimatedContent retains the outgoing route (including on back) instead of reading an already-cleared route during exit.

The five-step guide now uses centered headings, compact illustrated information cards, fixed bottom actions and a critically damped pager. It retains agreement gating, encrypted remembered-password login, cookie/web alternatives, truthful live permission status and optional setup. Web-login cancellation returns to the login step; successful authentication advances. The home/other root pages are preloaded behind the guide to avoid constructing them at completion. Only the visible welcome/completion emblem animates.

Home panels and feature cards use 24dp continuous corners instead of 38dp. The application embeds the unmodified official MiSans VF 4.009, with license and explicit About attribution. Every requested Compose weight maps to the original font's 80% weight axis (clamped to 150–700), with continuous integer weight registration and lazy font loading. A text-only density multiplier reduces all in-app sp values, including explicit timetable/Canvas text, to 80% while preserving dp geometry/touch targets and the original system font scale for responsive layout decisions. Custom appearance values remain nominal and are not overwritten. Android-hosted website content and system notification typography are system controlled.

Debug/optimized benchmark compilation and all 32 existing JVM tests pass. Release-only vital lint is excluded from the local performance build as before. On the unlocked OnePlus, the isolated optimized benchmark passed the guide's welcome/consent gate, password keyboard layout, optional login skip, permission page and completion-to-home flow. No real credentials were entered for this UI test. An explicit `show_onboarding` launch option is honored only by the `.benchmark` package, allowing guide replay without clearing any saved app data.

Default/1.3x text checks covered the fully visible week-12 heading, ordinary/staggered axes, month and semester modes; landscape showed week 11 and week 12 simultaneously and a full month viewport. A detail page opened/returned normally and survived five interrupted enter/back cycles. The benchmark process remained alive with the same PID through these checks. System font scale 1.0 and free rotation were restored afterward.

Warm optimized benchmark, 16 rapid root-tab selections: 277 rendered frames, 1 missed deadline (0.36%), P50 18ms, P90 20ms, P95 22ms, P99 32ms. The separately measured guide completion produced 60 frames, 1 missed deadline (1.67%), P95 32ms, P99 73ms. These are bounded device observations, not a guarantee for every cold start, refresh rate or device. UI hierarchies/screenshots/test scripts and gfxinfo captures are kept locally in ignored native/artifacts. Live academic endpoint parity gates above remain open.

### Component-origin transitions and bottom/calendar refinements

Detail pages now use independent interruptible springs in AnchoredPages, with complete control bounds registered from home feature cards, the classroom card, profile rows and the nested web-login entry. Incoming/outgoing bounds and continuous corner clips animate between that origin and the viewport. The page content always uses one uniform scale for both axes, so text/icons keep their aspect ratio while the window clip expands. Closing pages replay a retained graphics layer with their live child unplaced, allowing a new page to open underneath; reopening an existing flight reverses its current spring. Route changes clear focus/IME to prevent hidden fields retaining keyboard focus. Cresto root-tab timing and curves remain unchanged.

The home/timetable capsule is capped at 200dp and stays left aligned. Its independent profile control remains at the screen's right edge in expanded/compact and portrait/landscape modes. The course accessory retains its former expanded width (available screen width minus 40dp, capped at 560dp). Bottom controls use 0.86 material group opacity and scoped 1.8x blur/dispersion tuning; other toolbars, dialogs and pages retain reference optics. Gaussian/lens source support is enlarged for the stronger spectral rays.

WeekCourseIndex prepares all 60 week/day memberships and timeline positions once per schedule revision. Card colors, shapes and styles are prepared once, adjacent week pages are retained, and only the visible page binds the vertical navigation viewport. Course text uses a shared 256-entry TextMeasurer cache and cached drawing, retaining MiSans/appearance styles, height/max-line/ellipsis constraints, complete accessibility labels and course-detail taps. Two additional JVM tests compare cached memberships to the daily timeline across every week/day and validate shared block reuse. All 34 tests and debug/optimized builds pass (performance build still excludes release vital lint).

Month and semester modes use the same progressive upper scroll-edge blur as home. Month-page insets move inside each page, allowing moving calendar content to pass behind the toolbar blur. The lower page has no added mask; the calendar viewport sizing and reserved navigation clearance remain intact.

OnePlus checks: full open/back, five interrupted reversals, opening a second destination during exit, round clips with undistorted page content; 18 forward/back week swipes ending at week 7; calendar modes, month blur, landscape week 7/8, and right-profile placement in both orientations. Screenshots and scripts are in ignored native/artifacts. With the same 18-swipe fixture before/after shared text layout caching, observations were 37/668 missed deadlines (5.54%), P95 22ms/P99 40ms, then 28/710 (3.94%), P95 20ms/P99 25ms. These short runs preceded the final increased-optics request and do not establish a guaranteed frame rate. Final stronger optics were smoke-tested in light/dark, expanded/compact and drag states with no process restart; the restored expanded accessory measured 1076px on the 1216px screen. Real academic endpoints were not retested by this UI refinement.

### Course accessory docking on detail pages

The existing course accessory has a separate .9-damped, stiffness-350 spring targeting the bottom of its 118dp host whenever the navigation capsule is hidden (`detail != null`). The 48dp bar settles 70dp below the expanded origin, above the existing system inset and 8dp outer margin. Normal/compact navigation placement still uses its previous geometry, and width/material/content remain unchanged. Detail-to-detail navigation keeps the dock target at 1; opening/back/reopening retargets the same animated state, preserving current position and velocity.

Debug and optimized benchmark builds and the existing 34 JVM tests pass. On the OnePlus fixture, the bar moved from [70,2143][1146,2311] to [70,2388][1146,2556], retaining 1076px width. Five rapid open/back interruptions and reopening during the return animation reached the correct final position, with the benchmark process still alive. Screenshots and test script are in ignored native/artifacts. These checks cover UI geometry/interruptions, not live campus endpoints.

### Reduced dispersion, stronger refraction and animation frame-budget acceptance

The bottom-only optical override now restores chromaticStrength to 1.0, retains blurRadiusMultiplier 1.8 and applies an independent 1.35 refractionAmountMultiplier. Native inner/outer displacement profiles and explicit press lenses honor that multiplier; explicit chromatic vectors compensate for the increased displacement so their RGB separation stays at the original strength. Other page controls retain default optics. Existing widths, docking, tab curves and aspect-preserving page content are unchanged.

Frame-work reductions: source controls retain LayoutCoordinates instead of allocating/translating every registered component's bounds on every root scale frame. Only active flight origins resolve transformed coordinates, with cached snapshots for detached sources. Animated page corner clipping now updates a dedicated graphics layer rather than invalidating the enclosing page's draw callback. The course accessory reads docking progress in placement only, avoiding spring-driven remeasurement of its glass/text.

Acceptance protocol: OnePlus PLZ110, normal system text scale and fixed portrait; alternate the local appearance and import/export pages for 24 open/back cycles (500ms open hold, 450ms return hold), reset gfxinfo immediately before the sequence, and record stats after settlement without screenshots/UI dumps during motion. End-state profile and unchanged process PID are checked. Frame-drop rate is Android's missed-frame-deadline count divided by total rendered frames, not its legacy jank counter. This protocol covers continuous local-page opening, not all devices, refresh rates, cold application launch or arbitrary concurrent network workloads.

Results: prior optimized benchmark 25/2260 (1.11%); adjusted optimized benchmark 29/2221 (1.31%). The exact installed debug preview APK (SHA-256 E9E0458421CBF19267F86E74B9D25E170E92D18A5A1C0ACAC60A3D49DA32E3E3) passed two rounds: 40/2162 (1.85%) and 29/2196 (1.32%), both below the requested 2% threshold. P95/P99 were 27/89ms and 24/81ms respectively, so this is not a claim that every individual frame meets its deadline or that the optical change improved every percentile. All 34 JVM tests and debug/optimized builds pass; release vital lint remains excluded from the benchmark build. Raw gfxinfo, result JSON and the fixed test script are in ignored native/artifacts.

Final regression of the adjusted build also passed full open/back, five interrupted reversals and opening a different destination during exit. The page remains uniformly scaled and its component-origin rounded clip is preserved. The installed preview was visually checked with its cached timetable; no account or timetable data was edited. Native source compilation and all 34 tests passed before installing the exact APK measured above.

### Stronger bottom optics, opposed exit and scrolling budget

Bottom-only refraction is now 1.6x, with dispersion at 1.0. The main capsule exits left and the detached profile exits right, driven by the same reversible spring as course-accessory docking. A 450ms retained fade keeps both material/foreground nodes alive for their flight; retargeting a closing page reverses from the current spring position. Resting geometry, accessory width, right alignment, tab transition timing and page aspect ratio are preserved.

Scroll work is narrowed to a separate navigation-animation restart scope. Ordinary/staggered time-axis paints/font instances are shared between weeks; G2 outlines have a bounded 32-entry cache for recurring sizes/corners/directions, and the course clock's initial value is remembered rather than recalculated on route/viewport recomposition. Week viewport ownership changes without removing its nested-scroll node, and normal-size date columns no longer compete with the week pager for horizontal input; enlarged accessibility text retains horizontal day panning. Additional whole-page raster, atlas-copy, shader fast-path and broad source-scaling experiments did not establish a stable improvement and were reverted. Existing optical rendering and neighboring-week precomposition remain the baseline.

A release-optimized, development-signed `preview` build type shares `.localtest` identity and data with the existing preview; it does not enable fixture imports. `.benchmark` remains isolated. Device acceptance uses the optimized preview users actually run, rather than presenting release benchmark numbers as debug-APK performance. Build commands include `:app:assemblePreview`; local performance builds exclude release vital lint. No live academic requests are needed for the cached timetable and UI checks.

Scrolling protocol: unlocked OnePlus PLZ110, normal text scale, fixed portrait, warm lists/neighbors; 20 alternating home drags and 18 rapid forward/back week swipes. Reset gfxinfo before each workload and collect before any UI dump/screenshot. Report Android missed deadlines/total rendered frames separately per workload; check foreground and unchanged process. Raw captures and scripts are retained locally in ignored native/artifacts. Initial installed debug baseline measured home 124/891 (13.92%) and week 37/619 (5.98%); subsequent optical/caching candidates were not treated as accepted while week results exceeded 3%.

### Multi-sample background frost and denser light bottom coating

The user subsequently suspended the frame-drop threshold and requested replacement of glass-background Gaussian blur with overlays of sampled low-resolution backgrounds. Active native material pyramids now use a normalized tent kernel with nine contributing center/axial/diagonal samples on successive half-sized images. Generic reduced-source glass and quarter-resolution sheet backgrounds use three normalized nine-tap runtime-shader passes. The control-lens low-resolution planes use the same three-pass method, replacing both platform Gaussian calls and the managed Gaussian-weight/axis shaders. Background Gaussian blur is removed from those paths; foreground transition blur and silhouette shadows are separate effects.

Global frost is 3x with a .85 minimum central blur weight. Bottom frost is 4.5x with a .95 central floor so the small capsule's original size gate no longer leaves a sharp center. Strong-frost joined/toolbar sources are sampled at half resolution with their optical fields projected accordingly; final coverage, edges and foreground remain at device resolution. Optical displacement stays at 1.6x on the bottom controls, with original dispersion.

Light bottom material adds a white .22 face overlay and increases group opacity from .86 to .98. Dark bottom material keeps its existing tint/group opacity. The overlay is passed through native completion and morph completion, with the regular drawing fallback handling the same coating. It precedes foreground text/icons and does not paint the exterior shadow band. These changes are not claimed to meet the suspended 3% frame-drop threshold. System tracing used the local [Perfetto capture workflow](https://perfetto.dev/docs/getting-started/system-tracing); traces remain local.

Final optimized preview/benchmark builds and all 34 JVM tests pass. The installed `.localtest` preview (SHA-256 `33DEC9F2BEF708C128D89FE2388FF76834A17CC430408ABAF8A60E24973881EB`) passed OnePlus light/dark checks, the quarter-resolution course-status sheet, week/month/semester displays, appearance open/back, full opposing navigation exit/return and five interrupted reversals without a process restart. Saved account/timetable data were retained; these are cached-data UI checks, not fresh academic-endpoint verification. Final screenshots/scripts and a copy of the exact installed APK are in ignored native/artifacts. System light mode, 1.0 text scale, free rotation and normal screen timeout were restored. The app is left on its home page.

Subsequent opacity calibration: light bottom face overlay is reduced from .22 to .18, and light group opacity from .98 to .95. Blur, refraction and dark-mode values remain unchanged. This two-constant adjustment compiled as an optimized preview and was installed successfully on the connected OnePlus; no additional test suite was run. Current preview SHA-256: `2DEB0E7F3E286CE7F4DB59C0252017259CBDFCA16EC07663C7E9A0452E798932`.

Further opacity calibration: light face overlay is .14 and light group opacity is .92; blur, refraction and dark-mode values are unchanged. Optimized preview compilation and installation succeeded; no additional test suite was run. Latest preview SHA-256: `829D127011C6F6088A5E97F3321E997C42500F82FECADB31ABC8CE126D3D5601`.

### Shared bottom scroll-edge treatment

All app routes now render `BottomEdgeChrome` between page content and floating controls. It mirrors the existing top-edge progressive blur, reversed vertically: radius rises from 0 to 10dp toward the physical bottom edge. A theme-resolved white/black mask rises from transparent at the top to opaque at the edge. The band is 144dp plus the navigation-bar inset, reaching above the expanded floating-control stack and covering the system-gesture area.

The raw page plane is recorded independently; the existing exported backdrop contains both the page and its bottom treatment. Floating glass therefore samples the already-treated background without sampling itself. The decorative layer has no input handlers and does not tint or blur foreground controls. Onboarding separates its retained body and footer planes so the same treatment sits beneath the progress/action controls, including the keyboard layout; its embedded web-login route also receives the treatment.

Optimized preview/benchmark compilation and all 34 JVM tests pass. The connected OnePlus passed light/dark home, week/month/semester and appearance-route checks; full navigation fly-out/return and five interruptions; landscape double-week rendering; and the isolated guide's consent gate, login/IME, skip, permission and completion flow. Screenshots confirm the fade direction and clear controls. Saved preview account/timetable data were retained; live academic endpoints were not revalidated. Current installed preview SHA-256 is `B69D0943824DBEA8C187B7EF7C8756AF20F0AB97237BE7D784177D2631660B12`. The phone was returned to the preview home page with light mode, 1.0 text scale, free rotation and normal screen timeout.

Single-line course-accessory alignment: omit the subtitle Text node when its value is blank, eliminating the empty second line's reserved height. The existing centered row now centers the title inside the unchanged 48dp capsule; populated subtitles retain the two-line layout. Optimized preview build and installation succeeded. On-device title bounds `[126,2196][388,2259]` versus capsule `[70,2143][1146,2311]` differ in vertical center by 0.5px. No new unit tests were added for this layout adjustment. Current preview SHA-256: `7A3EC5A74D5B538DD4BBE5907F785FD21BC52D5FD148A010491BDEC78325EC9D`.


### Rapid detail-return selection and navigation flight rendering

The black selected capsule was captured on the OnePlus after quickly closing a home feature and switching tabs. The low-resolution control producer now contains an extract plus three sampling passes. The retained atlas compositor still treated four stages as the old extract/two-blur/scene arrangement: it read the wrong reduced tile and could turn an empty capture into an opaque black idle selection. `NativeGlassMipAtlas.controlBlurStageCount` now explicitly distinguishes blur passes from an optional scene pass; recording, packing and selection all use the actual last blur stage. The three normalized sampling passes and the existing glass opacity/refraction settings remain intact.

The sampled page includes the opaque app canvas during retained page transitions. `NavigationChromeSlot` keeps the bar/source composition alive across detail routes, removes fully hidden controls from placement and accessibility, and fades the complete bar using the existing interruptible docking spring. Its alpha layer reserves 280dp horizontal and 48dp vertical support beyond the unchanged control layout, so the flight and optical support do not meet the normal row-sized raster boundary. Separated flight rendering is limited to the actual capsule contours plus 24dp of shadow support, excluding empty rectangular image-filter extents. Opposing movement now updates placement, allowing global coordinates, shared glass geometry and hit targets to follow the same motion. Tab-selection spring/timing and course-accessory geometry are unchanged.

Final optimized preview build and the existing 34 app JVM tests pass; vital lint was excluded. The exact installed `.localtest` preview SHA-256 is `6543A612176C80700F427778AD3B61E7F7BE8C7E40C0ED073AA6A322058829A6`. Its final OnePlus regression passed full flight/return, the detached right profile position, five interrupted reversals, and four home-feature fast open/close cycles with sixteen immediate tab switches, retaining the same app process. The final light recording contains no black selected-background patch; diagnostic dark-pixel coverage in the navigation ROI remained below 2.2% (ordinary icon/text pixels), versus the previously captured solid-black selection. Earlier iterations also exercised twelve quick drags/eighteen quick taps and actual app dark mode; final-artifact acceptance here refers to the light regression. Local scripts/videos are ignored artifacts. These are UI/cached-data checks, not renewed campus endpoint or frame-budget certification. Saved account/schedule data were retained and the temporary app dark-theme change was restored to its original light setting.


### Light accent and neutral-button appearance

The saved default blue `#0088FF` now resolves to `#0066CC` in light mode; dark mode retains the existing saved blue, and other custom accent values remain unchanged. The independent static backdrop for page controls now records its background modifier inside the capture. Previously it recorded the empty child after that background, so ordinary buttons such as Settings / Save sampled transparency and produced a dark-gray face even in light mode. They now sample the actual theme canvas while retaining their glass material and interaction.

Optimized preview compilation and installation succeeded (SHA-256 `9550338CBAEA372BB9BA610D37E1E2AE7EA488B3EF59D907D6466A077C3214E2`). On the connected OnePlus, the light Home screenshot contains the new exact blue `(0,102,204)`; the Settings Save face sampled `(248,248,254)`. An actual app dark-theme check sampled the same button at `(32,32,32)`, and the original light setting was restored before returning Home. No new unit tests or repeated suite were added for this palette/capture-order adjustment. Saved account and schedule data were retained. Screenshots remain in ignored native/artifacts.


### Per-feature icon tints with the original visual style

Home and personal/settings entry badges retain their original Material glyph mapping, 34dp badge / 23dp symbol sizes, 11dp rounded backing and .12 backing opacity. Only their semantic tints vary by feature, with corresponding brighter dark-mode values. The home course-state decoration retains its original check/run vector, position, size and .14 opacity, using a green/amber tint. No replacement vector artwork, added Settings row icons, custom symbol provider or toolbar/nav recoloring is included. The bottom bar and other routes keep their original icon rendering.

Optimized preview compilation and installation succeeded. The final installed SHA-256 is `228CF5AD7D697DB2BCD2909F15C39740B27D99B5B2071EC7132E4B856A63B1C4`. OnePlus checks covered Home features/campus links, settings-entry icons, the restored Settings layout and navigation. An actual app dark-mode check confirmed the brighter tint variant; the original light setting and normal screen timeout were restored and the app was left at Home. These are visual checks; no new unit tests or repeated suite were added for the reversible tint adjustment. Saved account/schedule data were retained. Screenshots are in ignored native/artifacts.


### Home service spacing and featured campus-network card

Campus services use a 68dp minimum row height instead of the default 52dp. The list-row override applies to both the outer row and its inner separator/content row, preserving vertical centering and separator alignment; other callers keep their existing height. Only these service badges use the compact 30dp backing and 20dp glyph (previously 34dp / 23dp), with the original shape, color and adaptive text scaling retained.

Campus-network authentication is the first full-width quick feature. The eight remaining features keep their responsive regular grid. Both forms share the original card component and URL/navigation callback, so the promoted entry is not duplicated and keeps its existing destination and appearance.

Optimized preview compilation and installation passed (SHA-256 `DE1DB086BC2D4586A9A6F67A8C99BCA4BC8D86CC81997DD7D6352F2063E80B41`). OnePlus portrait verification measured the first network card at `[56,520][1160,786]`, above the next two cards `[56,821][585,1087]` and `[631,821][1160,1087]`. The campus-service rows measured 238px (68dp) and the reduced badge 105px square (30dp), at device density 3.5. Screenshots confirm the layout and original icon style. No new unit tests or repeated suite were added for these reversible layout edits; URLs were not opened during verification. The app was left at Home with normal timeout and free rotation restored.


### Legacy solid-color icon badges at 90 percent

The badge treatment follows the pre-rewrite `MiuixIconBadge` in `lib/widgets/utils_widgets/miuix_components.dart`: an opaque vivid rounded-square backing with a white foreground glyph, .28 corner-radius ratio and .62 glyph-size ratio. Feature colors use brighter saturated blue, purple, green, orange, cyan and pink instead of pastel transparent backings. Existing glyphs, the featured network card, larger campus-service rows and bottom navigation remain in place.

Both the colored backing and white glyph render at 90% of their preceding badge size, centered in the original 34dp / compact 30dp layout slots. The display sizes are therefore 30.6dp / 27dp; keeping the slots prevents shifting labels, card boundaries or touch targets.

Optimized preview compilation, installation and OnePlus visual checks passed. The final installed SHA-256 is `58B31E8459ABE926487090803BFEB15285013A31AEFFC1871A0BD744CCCD1F14`. Device inspection confirmed the solid legacy blue and white foreground, then the reduced standard backing measured 107px versus the preceding 119px at density 3.5; the network-card label still starts at x=252px. Home and personal/settings entries remain reachable. No new unit tests or repeated suite were added for these reversible visual adjustments. The app was left at Home with normal screen timeout restored.


### Native academic feature repair (2026-10-31)

The seven academic features now use explicit original-Dart request contracts, feature-specific fields and native query/detail screens. Confirmed repairs include the false grade login detection, omitted curriculum filters and JSON-escaped transcript URL. Real-account checks distinguish valid empty records from server-denied modules; the current account receives `无功能权限` for textbooks. The scope, build/tests, live counts and verification limits are recorded in [the academic repair report](native-academic-repair-2026-10-31.md). Synthetic UI timing fixtures are not evidence of endpoint functionality.


### Contextual course/book search

The curriculum detail and textbook query screens add a trailing 48dp liquid-glass search circle. The course accessory yields its width; independent underdamped springs control entrance, expansion, restoration and interruption. Search works on original feature metadata with normalized case/width, off-main filtering, reset-on-cancel and per-page ownership. The optimized preview, 59 JVM tests and eight new search UI assertions pass; the same report records the current installed artifact and live textbook permission limit.
