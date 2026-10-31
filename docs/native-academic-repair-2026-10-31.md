# Native academic feature repair — 2026-10-31

## Scope and original contracts

The Flutter services under `lib/services/zhengfang_jwxt` remain the behavior reference. This repair replaces the native all-purpose select/form/result adapter with explicit contracts in `AcademicRequests`, `AcademicProtocol`, `AcademicRecords`, and `AcademicPages`. The existing saved-account store, password recovery, timetable, navigation, glass materials, and app identity are retained.

| Feature | Original contract restored | Live account result |
| --- | --- | --- |
| 培养方案 | `nj_cx/jg_id/zyh_id_cx` → `njdm_id/jg_id/zyh_id`; dependent school majors; separate plan/course queries; all empty curriculum filter fields and original sorting | One plan and 114 courses; detail opening and returning checked |
| 教材预订 | `xnm_cx/xqm_cx` → `xnm/xqm`, original empty book filters, 100-row pagination, correct author/price/reservation fields | Server explicitly returns **无功能权限** for this account. UI reports module permission denial; it does not log out or invent empty results |
| 考试时间 | `cx_xnm/cx_xqm` → `xnm/xqm`, original exam filters/sort, all-semester option, empty-state display; existing calendar export retained | Current and all semesters return zero records; form and empty-state UI checked |
| 成绩查询 | Original semester fields, blank sort name, timestamp and grade filters; notices; no false session expiry from an unrelated username input | Current and all semesters return zero records; form and empty-state UI checked |
| 绩点排名 | Combined `qsXnxq/zzXnxq` semester codes and `xbx`; all-semester default; original 600-second read timeout retained; correct `jdnjzypm` ranking field | Query returns zero records; selector and query UI checked |
| 空闲教室 | Semester/campus/building dependency, room type/name/seat filters; week/session bitmasks; five daily time blocks combined only after every query succeeds | 482 free rooms for the tested 1–2 block; 505 rooms in the union of the five blocks; 51 building choices; daily matrix UI checked |
| 成绩单 | Original format/print endpoints and fields; JSON-escaped slash decoding; same-origin print-folder URL validation; authenticated PDF download | Three formats; PDF signature validated and first page rendered on the phone |

Counts reflect the account, date and filters at test time. Zero-row responses verify successful empty-state handling, not rendering of this account's nonempty grades/exams/ranking. Those response fields are additionally covered by local tests. Textbook access cannot be enabled by changing the client; populated live textbook results remain unverified because of the server permission response.

## Faults confirmed

- The grade page contains a non-login `yhm` input. Native code treated any such input as a login page, retried login, and then rejected the valid page again. Detection now follows the original complete-login-form rule: username and password inside the same form.
- Generic parsing submitted unrelated HTML selects and omitted fields required by the curriculum endpoint. The native course query returned zero courses before repair and 114 with the original request contract.
- The transcript endpoint returns a JSON-quoted path with escaped slashes. A raw-path regex rejected it; JSON decoding now precedes URL validation. HTTPS, origin, directory, extension and traversal checks remain enforced.
- The textbook server response is a permission-denial page, not an empty form or expired login. It now has a distinct error state.

## UI, caching and execution

Feature forms show only relevant controls. Dependent choices reload when the parent changes; loading, query failure, server denial and successful empty results are separate states, with retry actions. Curriculum detail retains the parent query for returning. Classroom total-day and manual-session modes share the same backend filters. PDF format loading can be retried.

Requests, response parsing, account-scoped atomic cache writes and PDF rendering run off the UI thread. Result presentation is prepared on a background dispatcher and displayed through lazy lists. Pagination follows the server total instead of silently dropping later records. Existing optimized page transitions and bottom navigation are retained.

## Verification boundary

The optimized `preview` build and 52 app JVM tests pass; vital lint was excluded. Unit tests cover original request fields, semester aliases, login-form detection, denied/empty/malformed responses, escaped PDF URLs and origin/traversal rejection, textbook/GPA field mapping, classroom bitmasks, seat validation and daily availability aggregation.

Real read-only endpoint checks and 13 UI assertions ran on the connected OnePlus using the saved preview account. No app data was cleared and no account was logged out. Screenshots, UI scripts, endpoint count logs and query data stay in ignored `native/artifacts` / private device storage. These functional checks are separate from earlier synthetic animation benchmarks and do not certify a frame-rate target for these pages.


Academic-repair preview before the search addition, SHA-256: `F614EEA25571D729F1263735761AC80554339D25187B58773B427D4026003890`. It was installed with an in-place update to `com.pluvist.sachet.next.localtest` (Xachet 原生预览); the formal package was not replaced.


## Contextual liquid-glass search

Curriculum course detail and the textbook page now own independent contextual search sessions. The bottom-right entry is a 48dp glass circle (24dp radius, equal to the course capsule's radius). Its arrival reserves 60dp including separation; the course capsule yields that width. Opening expands the circle from the trailing edge into a glass input while the course capsule moves/fades left. Closing clears the filter and restores the course capsule. The input follows the keyboard insets and requests focus after the expansion has substantially completed.

Presence and expansion use independent underdamped springs (.73/410 and .77/390), preserving interruption velocity. They can run alongside the existing course docking/page transitions. Retained outgoing pages cannot detach a newly registered search session. Hidden input/close controls are removed from composition in the collapsed state so they cannot consume the circle's touch target. Filter-support guards keep group fading outside the visible glass contour.

Search covers displayed course/book metadata, including course codes, authors, publishers and ISBN. NFKC normalization handles full-width characters and case-insensitive codes; several whitespace-separated keywords must all match. Filtering runs off the UI thread after a cancellable 70ms typing debounce. Cancel restores all records without another request; backend errors remain visible and a failed load is not presented as a successful zero-match query.

The optimized preview and **59 JVM tests** pass. Eight new phone assertions passed: circle/capsule equal height, course width reservation, textbook input/cancel, real curriculum course-code filtering, no-match display, cancel restoration and five consecutive interrupted expansion/collapse cycles. Textbook populated live-record filtering remains blocked by the account's server permission denial; its record matching is covered by unit tests.

Current installed search preview SHA-256: `9E213EE602BB8C91F88F8CE72487A437F53D659F86B27773537F3444C71FC1F1`. The original saved account and app light theme were retained. Functional checks do not assert a new animation frame-deadline percentage.

## Search background and outside dismissal

The textbook search and cultivation-course search now share a route-owned dimming overlay (18% maximum in light appearance, 26% in dark). The floating input remains above the overlay. An ancestor pointer interceptor converts the actual search surface bounds into root coordinates, consumes outside taps before page/footer controls receive them, and closes through the existing session reset/focus/keyboard path. Inside-field input and the close button retain normal handling. The dimming spring is interruptible; route changes discard another page's overlay immediately. Keyboard hide is repeated after editor teardown on the next frame only while the owning route is visible, and reopening cancels that cleanup.

The application test suite includes a regression ensuring an expanded session on another route cannot dim or intercept the current page. This UI change does not change academic requests or server permissions. Device verification results and the installed APK hash are appended after the final check.

Final verification: optimized preview build and 72 application tests passed. On the connected device, both textbook and cultivation-course search passed four checks each: dimming overlay visible, text input remains interactive, outside tap collapses/reset search without opening a course panel, and the keyboard hides. Search overlays were captured and visually inspected. The textbook account still reports no server permission; this check validates its search UI, not textbook data access or reservation. Installed preview hash is recorded below.

Search-scrim preview SHA-256: D74BFB04C3E378A7F581E54F250D62B1544C7B73816C870C8384BA93E2949748

## Coordinated search return and compact home cards

The search accessory now owns its keyboard lift instead of using the footer's IME padding as a second position owner. Width and lift use the same interruptible .77/390 spring. Dismissal targets the resting bottom position immediately, together with collapse, so removal of the IME inset cannot teleport the already-collapsed search circle. The keyboard height excludes the navigation-bar inset; other editors continue following the system's animated inset directly. Actual moved input coordinates still drive outside hit testing.

The home course-card row is 210dp instead of 280dp before accessibility scaling. The right-hand stack and its internal gap shrink proportionally, retaining common top/bottom edges. Compact padding and bounded title/location lines keep course times and countdown space available. The current-course face uses the same elevated surface token as the neighboring cards (white/light, deep gray/dark). Global bottom-edge blur/gradient overlays have been removed from the app and guide; the top chrome is unchanged.

The subsequent typography adjustment sets app text to 95% of the system-scaled size instead of 80%. MiSans now uses the full requested variable-font weight (for example, normal 400 instead of 320), retaining separate semantic weights and dynamic-weight support. The same mapping is used for timetable canvas text. Course-card padding/spacing is tightened to accommodate the larger text without changing the new 210dp row height.

Verification: optimized preview and all 72 application unit tests passed. Before the typography-only follow-up, both search routes passed the eight input/scrim/outside-dismiss/keyboard checks. Two recorded dismissals (close control and outside tap) were inspected frame by frame: the input narrows while traveling down rather than collapsing above the IME then jumping. The compact light-theme home layout was also visually inspected. A further rapid-reopen check was not completed because the foreground route had changed; it is not counted as passed. The final typography preview was installed in place, but the phone was locked afterward, so its final visual check remains separate from the successful build/install.

Final installed preview SHA-256: `A20DC28343B4F3E966D7A8D3E4BBE8548B609BBD54A726374F6F87EFA7D0379B`.

## Reload fades

Refreshed regions use the tab's 200ms opacity tween with no extra delay: an observed request starts fading out immediately, and completion retargets toward visible immediately. Same-frame cache/local reloads replay an out/in pair with no intervening pause. Interruption continues from the current opacity. The existing tab scale/timing is unchanged.

`rememberCrestoReloadAlpha` shares one animation across the visible nodes of a refreshed region, without recreating pages or capturing screenshots. Home refresh targets the current/next course cards, leaving the classroom shortcut and other functions stable. Weekly schedule refresh targets course bars while headers, axes and guides remain visible. Month/semester refresh targets the month cards. Academic result queries leave page titles, form choices and controls stable; metadata/dependent-option requests animate only the relevant options. Transcript format/document regions and managed-file list/editor regions own independent fades. Account-row animation depends on visible name/ID changes. Keyword input, countdown ticks and ordinary recomposition do not replay a fade.

Manual schedule synchronization starts its region fade on the click. Automatic startup synchronization keeps the cached page visible while fetching and animates its course region on completion. Query and PDF progress use a centered overlay rather than inserting a row that shifts existing content. Previous errors/empty states and PDF images are retained while their refreshed regions fade out. The classroom hero reuses `HomeFeatureCard`; current/next labels use identical 14dp top insets.

The optimized preview and 82 application unit tests pass, including immediate hide/reveal, unchanged-region isolation, same-frame cache reloads, course-detail damping and status-companion intent reversal. With the phone paused for testing, eight real-device assertions passed: hero-label alignment, status open, navigation departure, reopen during return, navigation restoration, query form/result preservation, contextual search departure and search restoration. The opening recording was inspected frame by frame and shows panel expansion overlapping the companion flights. The classroom shortcut's shared style was visually checked.

Pixel comparison exposed a separate layout shift: removing a filter row's click action during loading also removed its disclosure arrow, moving the selected value. The row now explicitly preserves disclosure while input remains unavailable. After rebuilding and replacing the preview, the GPA query was rechecked; title and selected-value regions stayed stable while the result region faded out. The endpoint completed after the bounded seven-second recording, so result restoration is verified by a separate settled screenshot and the enabled query control, rather than claimed as present in that recording. Evidence is retained privately in ignored `native/artifacts`.

Final installed preview SHA-256: `688612B9B2F0ACE7E6D0EFC9E632F7EC5798600DAEAB34D6FD6B6326B3A528A4`. The user account/data were preserved and the phone was returned to Home. These checks validate behavior and appearance; they are not a new frame-deadline benchmark.
