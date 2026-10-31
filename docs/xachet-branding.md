# Xachet product name

The product-facing name is **Xachet**. Android/native/Flutter UI, onboarding and permission instructions, about/legal modification labels, widget names and accessibility descriptions, calendar export names/PRODID, web/iOS/desktop application titles, build-project labels, CI artifact names, packaging scripts and project documentation use the new name. The preview label is `Xachet 原生预览`.

Compatibility identifiers are deliberately retained:

- Android application/namespace `com.pluvist.sachet.next` and its `.localtest`/`.benchmark` variants, provider/service names and broadcast actions. Keeping these identities and the signing key permits replacement installation and retains existing app/widget ownership.
- Existing stored preferences/migration keys, including `sachet_next_migrations` and `sachetNextBlueThemeV1`, and calendar event UID suffixes. Renaming these would repeat migrations or change the identity of previously exported events.
- Historical asset filenames and tags. The repository is now published as `Pluvist/Xachet`; new source links and downloads use that name. Previously released binaries retain their historical filenames.
- Upstream Sachet's original name, authorship and license text. Only Pluvist's modification label is renamed; upstream attribution remains accurate.

The private Flutter widget channel is changed consistently on both ends to `xachet/course_widget`. The internal Dart library/import name is retained. Generated files, old binary releases and private test screenshots/logs are historical artifacts rather than new product labels.

Validation: optimized native preview build and 82 application unit tests passed; the four targeted Flutter branding/home/onboarding/interface suites passed 66 tests. Android APK metadata reports `Xachet 原生预览` with the unchanged application ID. Replacement installation succeeded; the application UID stayed the same and the installed APK SHA-256 matches the built file. This verifies packaging/installation without launching over the phone's current foreground application. Desktop product/scheme/output references were checked for consistency but those platforms were not built on this Windows/Android setup.

Installed preview SHA-256: `BF1D88DA6E18DB6DA8804DC5A66DE15CFA0BB6C078F4D9FD5C1C9DB843AA2178`.

## 0.19.78 publication

The native production build is version 0.19.78 / code 54. It keeps `com.pluvist.sachet.next` and the existing official certificate. README and the repository description now present the Kotlin / Compose implementation; Flutter files remain a reference. New APK asset names begin with `xachet-`. Source, native labels and upgrade identifiers are checked separately from old binary-release branding.

Final release build and release vital lint passed, with all 82 application unit tests passing. The ARM64, ARM v7a and x86_64 APKs were checked for production identity, Xachet label, version/code, API 33 minimum, exact ABI, non-debuggable packaging, legal assets, original signing certificate, ZIP/ELF alignment and SHA-256 checksums. No Flutter engine is bundled. The official certificate fingerprint remains `e42806c32da8fbbf836a94b3e65978137288619a005c8ce81533985edb769152`.
