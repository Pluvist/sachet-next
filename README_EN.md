# Xachet

An Android academic companion for Xiangtan University, maintained by **Pluvist**, based on [Sachet](https://github.com/wyvern1723/sachet) by **wyvern1723**. Thank you to the upstream author and contributors.

Starting with **0.19.78**, production uses **Kotlin / Jetpack Compose** and Kotlin academic repositories. MeiloX / Glasmio provide the liquid-glass foundation; the music accessory becomes a course-status bar. The original Flutter implementation remains as a historical behavior reference.

[中文](README.md) · [Build instructions](README_DEV.md) · [Release notes](docs/releases/0.19.78.md) · [Third-party notices](THIRD_PARTY_NOTICES.md)

## Download

**Version 0.19.78 requires Android 13 or later.**

- [ARM64 APK](https://github.com/Pluvist/Xachet/releases/download/v0.19.78/xachet-v0.19.78-arm64-v8a.apk)
- [ARM v7a APK](https://github.com/Pluvist/Xachet/releases/download/v0.19.78/xachet-v0.19.78-armeabi-v7a.apk)
- [x86_64 APK](https://github.com/Pluvist/Xachet/releases/download/v0.19.78/xachet-v0.19.78-x86_64.apk)

Checksums and the certificate fingerprint are attached to the [release](https://github.com/Pluvist/Xachet/releases/latest). Production keeps `com.pluvist.sachet.next` and the existing release signature for in-place updates and compatible account/settings/cache reads. The `.localtest` preview has separate private data. Versions through 0.19.58 also used a different package identity.

For Android 12 and earlier, use [0.19.77](https://github.com/Pluvist/Xachet/releases/tag/v0.19.77).

## Changes from upstream

- Native Compose home, timetable, queries, profile, settings and onboarding, with continuous rounded shapes, MiSans variable typography, colored feature icons and light/dark themes.
- Liquid-glass navigation, course accessory and detail panels, with scroll-away behavior, interruptible spring motion and low-resolution multi-sampled backdrops.
- Building-aware lesson times: daytime classes in Yifu and Information Technology buildings start 10 minutes later. Ordinary/staggered rails and manual overrides share rules with details, widgets, calendar exports and live activities.
- Week/month/semester views, paired-month portrait paging and double-week landscape layouts.
- Current/next-course home overview, classroom shortcut, academic features and campus services.
- Kotlin login/session recovery, curriculum, textbooks, exams, grades, GPA ranking, classrooms and PDF transcripts. Curriculum and textbooks support keyword search.
- Cached startup, background timetable sync, preserved cache on failure, saved-password recovery and region-scoped refresh transitions.
- Course live activities and 2×2 / 4×2 widgets. In-class compact content is a numeric countdown; breaks show the next time and place; completed days show completion; class-free days create no activity. Promotion and refresh depend on system/OEM permissions and power policies.

## Build and verification

Use JDK 21+, Android SDK 37, NDK 27.1.12297006 and CMake 3.22.1. On Windows run `native/build-native.ps1`; on Linux/macOS:

```sh
bash native/gradlew -p native :app:assembleDebug :app:testDebugUnitTest --console=plain
```

See [README_DEV.md](README_DEV.md) for signing and ABI splits. Flutter is no longer the production APK entry point. Legacy non-Android projects have not received the native migration.

Native tests, builds, OnePlus interaction checks and authorized read-only queries have been exercised. See the [academic report](docs/native-academic-repair-2026-10-31.md) and [migration record](docs/meilox-migration-plan.md). The test account's textbook endpoint reports insufficient permission. Preview testing does not establish production signed-upgrade migration, and no universal frame-rate guarantee is claimed.

## License and attribution

The project uses [AGPL-3.0](LICENSE). Upstream Sachet code retains its [MIT license](LICENSE-MIT), **Copyright (c) 2025 wyvern1723**, with **Copyright (c) 2026 Pluvist (Xachet modifications)** for this fork.

Native sources acknowledge MeiloX, Glasmio, Shapes, Cresto, flutter_secure_storage and MiSans under their own licenses. Historical Flutter sources retain NexioSchedule, Kyant Backdrop, HyperCeiler and Noto notices. No Apple or proprietary Anthropic fonts are included. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Report fork-specific issues in [this repository](https://github.com/Pluvist/Xachet/issues).
