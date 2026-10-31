# Xachet 构建说明

0.19.78 起正式 APK 使用独立的 `native/` Kotlin / Jetpack Compose 工程。根目录 Flutter 工程保留为历史与行为对照。

## 环境

- JDK 21+，本地使用 Android Studio JBR。
- Android SDK 37（SDK Manager 包名 `platforms;android-37.0`）、platform-tools、build-tools 36.0.0。
- NDK 27.1.12297006、CMake 3.22.1。
- 工程固定 Gradle 9.6.0、AGP 9.4.1、Compose 插件 2.4.21；最低系统 Android 13 / API 33。
- 首次构建需联网获取依赖并接受 Android SDK 许可。

## 测试构建

Windows，在仓库根目录：

```powershell
.\native\build-native.ps1
```

脚本将源码暂存到 ASCII 路径，规避 Windows CMake 中文路径问题。默认构建 debug 并运行应用 JVM 测试；可用 `-BuildDirectory`、`-JavaDirectory`、`-Tasks` 覆盖。仅当依赖齐备时使用 `-Offline`。`SACHET_LOCAL_MAVEN` 可选指向本地 Maven 仓库，不是构建必需项。

Linux/macOS：

```sh
bash native/gradlew -p native :app:assembleDebug :app:testDebugUnitTest --console=plain
```

测试包名 `com.pluvist.sachet.next.localtest`，输出在所用构建目录的 `native/app/build/outputs/apk/debug/`。优化预览可运行 `:app:assemblePreview`；`.benchmark` 供合成数据性能测试。它们均不与正式版共享私有数据。

## 正式签名与三架构构建

在仓库外创建自己的签名配置，替换占位值：

```properties
storeFile=/absolute/path/to/your-release-key.p12
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

Windows：

```powershell
$env:XACHET_SIGNING_PROPERTIES = 'C:/private/xachet-key.properties'
.\native\build-native.ps1 -Tasks ':app:assembleRelease',':app:testDebugUnitTest','-PxachetReleaseAbis=arm64-v8a,armeabi-v7a,x86_64'
```

Linux/macOS：

```sh
XACHET_SIGNING_PROPERTIES=/private/xachet-key.properties bash native/gradlew -p native :app:assembleRelease :app:testDebugUnitTest -PxachetReleaseAbis=arm64-v8a,armeabi-v7a,x86_64 --console=plain
```

输出在 `native/app/build/outputs/apk/release/`；Windows 脚本输出在暂存目录。正式打包缺少签名配置时停止，避免误发开发签名包。不要提交密码、配置、账号或私钥。发布前检查包名、版本、标签、最低系统、架构、签名和校验和。

正式包继续使用 `com.pluvist.sachet.next`；覆盖升级必须保持包名与签名一致。维护者发布私钥不在仓库中，自行构建的不同签名版本不能覆盖官方版。

## CI 与验证范围

GitHub Actions 在手动触发或 main 的 Pull Request 时构建原生 debug APK、运行应用单元测试并上传测试产物，不读取发布密钥，不自动创建正式 Release。

真实教务查询、系统权限、桌面组件及实时活动需分别验证，单元测试或编译不能代替真实账号与厂商系统验证。参考 [原生说明](native/README.md)、[教务实测](docs/native-academic-repair-2026-10-31.md) 及 [迁移计划](docs/meilox-migration-plan.md)。

## 历史 Flutter 工程

`lib/`、`android/`、`test/` 使用 Flutter 3.24.5 / Dart 3.5.4，可对照旧版行为。本次正式发布不执行 Flutter 打包。历史版本号保留，当前版本以 `native/app/build.gradle.kts` 为准。其他平台旧工程未完成原生迁移。

## 分发许可

保留 `LICENSE`、`LICENSE-MIT`、`THIRD_PARTY_NOTICES.md` 及 `third_party/` 的来源与独立许可证。原生 APK 打包项目和上游许可、Cresto 及 MiSans 字体许可；第三方资源继续遵循各自许可。
