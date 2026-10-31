# MeiloX scroll-away navigation

Upstream: https://github.com/NEORUAA/MeiloX
Revision: 537c05f0158c2a489a06b9152dad08e3e8e97242
License: GPL-3.0; upstream LICENSE retained here.

`native/app/src/main/kotlin/com/pluvist/sachet/next/CourseNavigationScrollState.kt`
adapts `app/src/main/java/com/ljyh/mei/ui/navigation/MeiloXNavigationScrollState.kt`.
Package and class names are changed. Original distance thresholds, direction handling,
non-consuming nested scroll observer, reverse reveal and spring response are retained.
The course accessory uses MeiloX's 48 dp inline height, 63 dp center travel and 69 dp
additional side insets, replacing music data with lesson status.
