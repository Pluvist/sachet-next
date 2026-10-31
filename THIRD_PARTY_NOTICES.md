# 第三方资源与上游声明

## 原生 Compose 迁移

`native/` 使用 MeiloX 所引用的 Glasmio 六个开源组件模块。Glasmio 源码按 Apache-2.0 分发，版本、集成修改及原始第三方声明见 [Glasmio 来源](third_party/glasmio/SOURCES.md)。MeiloX 是 GPL-3.0 的界面与交互参考项目：https://github.com/NEORUAA/MeiloX 。未复制其 Apple 字体资源。

旧账号兼容复用 flutter_secure_storage 9.2.4 的 MIT Java 存储与加密实现，见 [来源与许可](third_party/flutter_secure_storage/SOURCES.md)。

## Sachet

- 来源：https://github.com/wyvern1723/sachet
- 作者：wyvern1723
- 许可证：MIT
- 上游版权：Copyright (c) 2025 wyvern1723
- 原有代码、图标与工程资源来源于 Sachet，保留上游版权及许可全文，见 [LICENSE-MIT](LICENSE-MIT)。
- Xachet 修改版权：Copyright (c) 2026 Pluvist (Xachet modifications)。

## Noto Serif SC 标题字体

- 文件：`assets/fonts/NotoSerifSC-Titles.ttf`（标题用子集）
- 来源：https://github.com/notofonts/noto-cjk
- 版权：(c) 2017-2024 Adobe (http://www.adobe.com/).（与字体内嵌版权一致）
- 许可证：SIL Open Font License 1.1，全文见 [字体许可证](assets/fonts/NotoSerifSC-LICENSE.txt)。
- 字体遵循其独立许可证，不改为 MIT。可选衬线标题使用该字体，默认标题使用系统无衬线字体。

## 公开资源范围

早期本地试验使用的 Anthropic 专有字体不包含在公开源码或新构建中。参考 Miuix 的视觉思路由 Flutter 代码实现，没有直接引入 Miuix Compose 库。

Flutter 及 pubspec.yaml 中的依赖遵循各自许可证；Flutter 构建生成的第三方许可信息可通过应用关于对话框的“查看许可”查看。本声明不改变这些依赖原有的许可条件。
## NexioSchedule 与 Kyant Backdrop

底栏尺寸、手势、弹簧及菜单变形逻辑移植自 HaoZai000/NexioSchedule，遵循 AGPL-3.0；着色器公式版权为 Copyright 2025 Kyant，遵循 Apache-2.0。修改者 Pluvist。源码版本、原文、许可全文和移植差异见 [来源说明](third_party/nexio/SOURCES.md)。

## HyperCeiler

首次账号引导布局转写自 ReChronoRain/HyperCeiler，Copyright (C) 2023-2026 HyperCeiler Contributions，AGPL-3.0。原始XML、固定提交和适配说明保存在 [来源目录](third_party/hyperceiler/SOURCES.md)。品牌改为Xachet，仅保留账号步骤，保留原glow.glsl与GlowPainter默认参数，转写为Flutter着色器；未包含其系统专属活动动画库。来源控件捕获与展开入口另参考同一提交的 StartupFragment.java / ViewUtils.java；Flutter 版本保持目标页面原尺寸，通过完整控件边缘揭示下一页，时长和曲线为本项目适配参数。

## MeiloX 原生底栏滚动逻辑

原生版的滚动收纳驱动适配自 NEORUAA/MeiloX（GPL-3.0），保留来源、版本与许可全文，见 [来源说明](third_party/meilox/SOURCES.md)。修改者 Pluvist；音乐活动内容替换为课程状态。

## Kyant0/Shapes

原生界面的窗口、卡片、菜单与 bar 使用 Kyant0/Shapes 1.2.1 的连续圆角轮廓，按 Apache-2.0 分发。依赖坐标和适配说明见 [Shapes 来源](third_party/shapes/SOURCES.md)。

## Cresto and MiSans (native app)

Page motion is adapted from Nevodev/Cresto (Apache-2.0), revision 74564563a686106d76d7d9a403dd994a4fbcb6a7. Its guide layout is used as a design reference with Sachet-specific content. See third_party/cresto/SOURCES.md and LICENSE. The app includes the Apache license and credits in About.

This application uses MiSans fonts. Copyright © 2020–2025 Beijing Xiaomi Mobile Software Co., Ltd. All Rights Reserved. The unmodified official MiSansVF.ttf (4.009) is included as an app resource under Xiaomi's MiSans Font Intellectual Property License Agreement, not the application's source license. The license is retained in third_party/misans/LICENSE.pdf and app legal assets. Source, checksum and weight-axis details: third_party/misans/SOURCES.md. The About page explicitly credits MiSans.
