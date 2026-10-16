# Sachet Next 构建说明

## 环境

- Flutter 3.24.5，Dart 3.5.4（仓库提供 `.fvmrc`）。
- JDK 17、Android SDK 35，安装 Android command-line tools、platform-tools 和所需 NDK。
- 构建前运行 `flutter doctor`，确认 Android 工具链及 SDK 许可。
- Windows 建议将仓库放在不含中文或空格的路径，以避免 Android Gradle 路径兼容问题。

## 本地检查

```sh
flutter pub get
flutter analyze
flutter test
```

需要真实教务账号的联网测试默认跳过，测试文件不包含真实账号或密码。

## Android 测试构建

PowerShell：

```powershell
$env:SACHET_LOCAL_TEST = '1'
flutter build apk --release --target-platform android-arm64
```

Linux/macOS：

```sh
SACHET_LOCAL_TEST=1 flutter build apk --release --target-platform android-arm64
```

输出：`build/app/outputs/flutter-apk/app-release.apk`。

测试包 ID 为 `com.pluvist.sachet.next.localtest`。没有配置签名密钥时使用本机开发签名，CI 使用运行环境的开发签名；不同机器或 CI 运行产生的签名可能不同，不能据此保证覆盖安装。

## 自行签名

创建自己的签名密钥，在本机 `android/key.properties` 中配置：

```properties
storeFile=/absolute/path/to/your-release-key.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

请勿提交该文件、密钥或实际密码；它们已加入忽略规则。也不需要上游作者的签名密钥。

未设置 `SACHET_LOCAL_TEST=1` 的 release 构建使用独立包名 `com.pluvist.sachet.next`。官方 Release 自 0.19.59 起使用专用发布密钥；仓库不包含该密钥。旧版 `io.github.wyvern1723.sachet.localtest` 与新版是两个应用，已有数据不会自动迁移。今后的覆盖升级必须保持包名和签名一致。

可使用 `flutter build apk --release --split-per-abi` 生成多架构构建。正式发布前会验证三种 APK 的包名、架构、版本和签名，并运行 Flutter 与原生测试；其他平台的工程文件来自上游，新增桌面课程组件仅支持 Android。

## GitHub Actions

本仓库的 Android workflow 在手动触发或针对 main 的 Pull Request 时执行依赖安装、静态分析、自动测试与 ARM64 测试构建。只需要仓库读取权限，不读取上游签名密钥，不自动创建 Release。

## 分发许可

请同时保留根目录 `LICENSE`、`LICENSE-MIT`、`third_party/nexio/`、`THIRD_PARTY_NOTICES.md` 与字体许可证。构建将项目 AGPL、上游 MIT 和衍生着色器 Apache-2.0 文本和 Noto 字体 OFL 文本作为资源打包，并在应用关于对话框的“查看许可”中展示。

公开构建使用 Noto Serif SC，不需要早期本地试验的 Anthropic 字体文件。上游地址与作者说明见 [README](README.md)。