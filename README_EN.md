# Sachet Next

A modified version of [Sachet](https://github.com/wyvern1723/sachet) for Xiangtan University, maintained by **Pluvist**. Thanks to **wyvern1723** for developing and open-sourcing the upstream application.

[简体中文](README.md) · [Build guide](README_DEV.md) · [AGPL-3.0 license](LICENSE) · [Third-party notices](THIRD_PARTY_NOTICES.md)

## Downloads

[Latest release](https://github.com/Pluvist/sachet-next/releases/latest)

- [ARM64 v8a](https://github.com/Pluvist/sachet-next/releases/download/v0.19.75/sachet-next-v0.19.75-arm64-v8a.apk): most modern Android phones, including Xiaomi 17.
- [ARM v7a](https://github.com/Pluvist/sachet-next/releases/download/v0.19.75/sachet-next-v0.19.75-armeabi-v7a.apk): 32-bit ARM devices.
- [x86_64](https://github.com/Pluvist/sachet-next/releases/download/v0.19.75/sachet-next-v0.19.75-x86_64.apk): compatible 64-bit x86 Android devices/emulators.

Stable **0.19.75** fixes session restoration, login compatibility and narrow-screen home shortcuts. It uses the independent Android package ID `com.pluvist.sachet.next` and Pluvist's dedicated release signing key, with release/AOT APKs for all three architectures. Miuix styling, tablet/two-week landscape layouts, course live activities, dual widget sizes and paired-month paging remain available. It supports in-place upgrades from 0.19.74 and older identically signed builds. See the [release notes](docs/releases/0.19.75.md).

**Migration:** 0.19.58 and earlier releases used a different package ID. This version installs separately from those versions and does not automatically inherit their login, timetable, widget settings or permissions. Sign in and sync the timetable in the new app, then re-add widgets and enable notifications as needed. The old app and its data are retained. Versions with the same package and release signature support in-place updates. SHA-256 checksums are attached to the release.

## Changes from upstream

- Building-aware schedules: daytime lessons in Yifu Building and the Information Technology Building start 10 minutes later than ordinary buildings; evening lessons share the same times. Per-course overrides are supported.
- Two persistent time rails, time-based weekly card placement, staggered-course outlines, and compressed lunch/evening breaks. Details, calendar exports, live activities, home status and widgets share the actual timing rules. A small visual offset does not change actual course times.
- Two complete months per portrait page, vertical paging across year boundaries, independent month/week positions, and correctly mapped pages on rotation. Month-switch buttons are removed; return-to-current-month and tappable course details remain available.
- A three-card home overview: current lesson, location, time and countdown on the left; next lesson/time/location at the upper right; a free-classrooms shortcut at the lower right. Narrow displays and large text stack the cards. The current card is display-only. Campus service shortcuts are reorganized.
- Shared Miuix-inspired Flutter headers, rounded groups, colored icon tiles, search, forms, dialogs, pickers and tables, a two-item floating navigation capsule, profile access from the home header, and theme-aware top/bottom gradients. Grade loading uses a centred fixed-size ring.
- Android course Live Updates using the home page’s resolved lesson data: a numeric-only countdown during class (no text label), kept current by a foreground service while the screen is on and backed by the native chronometer without wake locks, next time/location between classes, a dismissible completion notification after the final lesson, and no notification on days without classes. Native alarms update cached state without an open app or a home-screen widget. Supported systems may promote the activity; others use an ongoing notification. System/OEM restrictions apply; compact chips abbreviate buildings and full locations remain in the notification. Manage permissions and the opt-out in Settings → 课程实时活动. Included in stable 0.19.59; actual promoted surfaces depend on the device and system settings. See [Android Live Updates](https://developer.android.com/develop/ui/views/notifications/live-update).
- Android home-screen course widgets in 2×2 and horizontal 4×2 layouts, selectable from the profile page or the launcher. The horizontal layout separates current status on the left from the next lesson, time and location on the right. Both use the home page's resolved timestamps, shared refresh scheduling, adaptive sizing and dark/light themes, with static coloured glows and fine illuminated edges. Default height is slightly reduced without changing launcher grid sizes.
- Idle-time tab preparation, retained tab/week state, lazy week creation, shared cached reads, deferred glass backdrop sampling, and fewer touch-triggered rebuilds. iOS-style page transitions are fixed as the default.
- Automatic timetable refresh on cold start and foreground resume, showing cached data first and retaining it on failures. Updates preserve colors and applicable manual settings and refresh widgets and live activity data. Legacy experimental settings and scheduled course reminders are removed, including upgrade cleanup of their old notifications and alarms.
- A five-step welcome → consent → account → background & widgets → completion setup, with offline usage/privacy notices and an explicit consent checkbox. Background/autostart settings and widget setup are optional and can be reopened from Settings. Agreement and account screens share centered blue icons, large headings, rounded panels and bottom actions. Home preloading reduces work during the final handoff; rounded expansion transitions retain background depth and support interruptions and parallel animations. Password, web, portal and Cookie authentication remain available. See the [0.19.74 release notes](docs/releases/0.19.74.md).
- Sachet Next branding and Pluvist credits, with explicit upstream acknowledgment. Upstream update checks and related settings were removed.

Upstream academic features remain the foundation: timetable, free classrooms, curriculum, textbooks, exams, grades, GPA ranking, transcripts, campus links and calendar export.

## Build and verification

Use Flutter 3.24.5 / Dart 3.5.4, JDK 17 and Android SDK 35. See [README_DEV.md](README_DEV.md).

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

Set `SACHET_LOCAL_TEST=1` for an isolated Android test package (`com.pluvist.sachet.next.localtest`). The production Android package is `com.pluvist.sachet.next`; separate package IDs do not share private app data. Configure your own signing key for releases; builds without a key use a development signature. Different signing keys prevent in-place updates.

Automated tests, static analysis and Android ARM64 release builds have been exercised, with installation/display checks on a Xiaomi 17. Real-account network tests are skipped by default. No measured frame-rate improvement is claimed. The new widget is Android-only; other platform project files are retained.

The GitHub Actions workflow provides manual/PR checks and a test APK, without upstream signing secrets or automatic releases.

## License and attribution

Code is distributed under the [AGPL-3.0 license](LICENSE), preserving `Copyright (c) 2025 wyvern1723` and adding `Copyright (c) 2026 Pluvist (Sachet Next modifications)`. Preserve the copyright and permission notices when redistributing.

Noto Serif SC is separately licensed under SIL OFL 1.1. Proprietary Anthropic fonts are excluded from this public version; optional serif headings use Noto Serif SC, while default headings use the system sans-serif font. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Report issues with this modified version in this repository. Upstream websites, releases and contact information belong to Sachet and are not support channels for Sachet Next.

Development 0.19.60-next.3 removes the legacy experimental reminder feature and its scheduling plugin, with upgrade cleanup that preserves live activities and widgets. Onboarding adds an optional background/auto-start/widget step; Settings also exposes it. The real home subtree is prepared in advance and retained during handoff, while control expansions support velocity-continuous reversal and concurrent transitions. See [implementation and validation](docs/onboarding-and-interruptible-motion.md).
