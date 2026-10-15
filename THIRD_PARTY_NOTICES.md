# 第三方资源与上游声明

## Sachet

- 来源：https://github.com/wyvern1723/sachet
- 作者：wyvern1723
- 许可证：MIT
- 上游版权：Copyright (c) 2025 wyvern1723
- 原有代码、图标与工程资源来源于 Sachet，保留上游版权及许可全文，见 [LICENSE-MIT](LICENSE-MIT)。
- Sachet Next 修改版权：Copyright (c) 2026 Pluvist (Sachet Next modifications)。

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

首次账号引导布局转写自 ReChronoRain/HyperCeiler，Copyright (C) 2023-2026 HyperCeiler Contributions，AGPL-3.0。原始XML、固定提交和适配说明保存在 [来源目录](third_party/hyperceiler/SOURCES.md)。品牌改为Sachet Next，仅保留账号步骤，保留原glow.glsl与GlowPainter默认参数，转写为Flutter着色器；未包含其系统专属活动动画库。
