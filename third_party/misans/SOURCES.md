# MiSans variable font

This application uses MiSans fonts. Copyright © 2020–2025 Beijing Xiaomi Mobile Software Co., Ltd. All Rights Reserved.

- Official download page: https://hyperos.mi.com/font/en/download/
- Official archive: https://hyperos.mi.com/font-download/MiSans.zip
- Original archive member: `MiSans/可变字体/MiSansVF.ttf`
- Application resource (unchanged): `native/app/src/main/res/font/misans_vf.ttf`
- Version: 4.009
- SHA-256: `0ddef90648998900175cfdca9a6f087a2544c182f130b0ad4f7e94a03a115e79`
- Weight axis: 150–700, default 330.
- License: Xiaomi MiSans Font Intellectual Property License Agreement, retained in `LICENSE.pdf` and the application's legal assets. MiSans is not relicensed under the application license.

Rendering selects the original variable font's weight axis at 80% of the requested UI weight, clamped to its supported axis range. The text-only size factor is 0.8 and continues to multiply the user's Android text scaling. Neither operation edits or subsets the font file. Layout dimensions and touch targets are not scaled. Registration covers the integer FontWeight range, with lazy loading of only requested variations, so typography can vary continuously at runtime.
