# Xachet

面向湘潭大学的 Android 教务应用，基于 [Sachet](https://github.com/wyvern1723/sachet) 二次开发，由 **Pluvist** 修改与维护。感谢上游作者 **wyvern1723** 的开发与开源贡献。

**0.19.78 起采用 Kotlin / Jetpack Compose 原生界面和 Kotlin 教务服务**。以 MeiloX / Glasmio 的液态玻璃交互为基础，将音乐活动栏改为课程状态栏，保留错峰课表、教务查询、离线缓存、课程实时活动和桌面组件。原 Flutter 实现留作历史与行为对照。

[English](README_EN.md) · [构建说明](README_DEV.md) · [修改记录](CHANGELOG.md) · [AGPL-3.0](LICENSE) · [第三方声明](THIRD_PARTY_NOTICES.md)

## 下载

**当前正式版：0.19.78，要求 Android 13 及以上。**

| 架构 | 适用设备 | 下载 |
| --- | --- | --- |
| arm64-v8a | 大多数现代 Android 手机和平板 | [ARM64 APK](https://github.com/Pluvist/Xachet/releases/download/v0.19.78/xachet-v0.19.78-arm64-v8a.apk) |
| armeabi-v7a | 运行 Android 13+ 的 32 位 ARM 设备 | [ARM v7a APK](https://github.com/Pluvist/Xachet/releases/download/v0.19.78/xachet-v0.19.78-armeabi-v7a.apk) |
| x86_64 | 64 位 x86 设备或模拟器 | [x86_64 APK](https://github.com/Pluvist/Xachet/releases/download/v0.19.78/xachet-v0.19.78-x86_64.apk) |

[最新 Release](https://github.com/Pluvist/Xachet/releases/latest) 附有校验和及签名证书指纹。安装包继续使用 `com.pluvist.sachet.next` 和原正式版发布签名，支持同包名、同签名版本覆盖升级；账号、设置及课表缓存采用兼容读取。原生预览版 `.localtest` 是独立应用，数据不与正式版共享。0.19.58 及更早的不同包名版本也需要单独登录。

Android 12 及更早系统可使用 [0.19.77 历史版本](https://github.com/Pluvist/Xachet/releases/tag/v0.19.77)。验证范围与已知限制见 [发布说明](docs/releases/0.19.78.md)。

## 相比上游的主要变化

| 部分 | Xachet 的修改 |
| --- | --- |
| 原生界面 | Kotlin / Jetpack Compose 和 Glasmio 构建主页、课表、教务查询、个人、设置与引导页面；连续圆角、MiSans 可变字体、彩色功能图标和明暗主题。 |
| 液态玻璃交互 | 左侧主页/课程表导航、右侧个人入口和课程状态栏；支持滚动收纳、详情展开、连续打断与回弹。玻璃使用低分辨率背景多次采样。 |
| 教学楼错峰 | 自动识别逸夫楼、信息科技大楼，第 1–8 节采用晚 10 分钟的作息；第 9–11 节一致。保留普通/错峰双时间轴及手动纠正。 |
| 多种课表 | 周、月、学期视图；竖屏双月上下翻页、横屏双周布局。详情、主页、日历、实时活动与组件共享实际作息规则。 |
| 主页 | 当前课程、下一节与空闲教室概览；校园网认证置顶，培养方案、教材、考试、成绩、绩点、成绩单及校园服务集中展示。 |
| 教务服务 | Kotlin 实现登录、会话恢复、培养方案、教材预订、考试、成绩、绩点、空闲教室与 PDF 成绩单；培养方案课程和教材支持关键词搜索。 |
| 缓存与刷新 | 优先读取本地课表，启动及恢复时后台同步；失败保留缓存。按刷新范围淡入淡出，未更新的组件保持原位。保存密码后，会话失效可自动重新登录。 |
| 课程实时活动 | 上课显示纯数字倒计时；课前/课间标题显示下一课时间地点，内容显示课程时段；全部结束显示完成，无课日不触发。系统提升显示取决于版本、厂商及权限。 |
| 桌面组件 | 2×2 今日课程与 4×2 横向概览，共享课表与课程状态；静态流光、边缘辉光、明暗模式和刷新调度。 |
| 引导与设置 | 协议、账号、通知/后台/自启动及桌面组件引导；保留上游鸣谢，移除上游更新检查和旧实验性课程提醒。 |

作息依据学校的《错峰上课试行时间表》。未识别的楼名默认使用普通作息，可在课程详情中修正。视觉偏移不改变实际课程时间。

## 功能与验证

教务功能沿用 Sachet 的业务规则，并逐项对照原 Dart 请求、参数与解析逻辑重写。已进行原生自动测试、Android 构建和 OnePlus 真机交互及账号只读查询验证。记录见 [教务实测](docs/native-academic-repair-2026-10-31.md) 和 [迁移计划](docs/meilox-migration-plan.md)。

学校接口和账号权限会影响结果：测试账号的教材接口返回“无功能权限”，应用保留学校提示。原生预览版的账号测试不能代替正式签名覆盖升级的数据迁移测试；没有为所有设备承诺统一帧率。实时活动及组件刷新还受系统权限、省电策略和启动器影响。

## 构建

开发环境：JDK 21+、Android SDK 37、NDK 27.1.12297006、CMake 3.22.1。工具版本由工程固定。

Windows：

```powershell
.\native\build-native.ps1
```

Linux/macOS（安装上述 Android 工具链后）：

```sh
bash native/gradlew -p native :app:assembleDebug :app:testDebugUnitTest --console=plain
```

默认生成隔离测试包。签名、多架构及 CI 说明见 [README_DEV.md](README_DEV.md)。仓库不包含发布私钥和真实账号。Flutter 不再是本版本正式 APK 构建入口；其他平台旧工程保留但未完成原生迁移。

## 许可证与鸣谢

项目整体按 [AGPL-3.0](LICENSE) 开源，Sachet 原始代码保留 [MIT 许可证](LICENSE-MIT) 及 **Copyright (c) 2025 wyvern1723**。修改版权为 **Copyright (c) 2026 Pluvist (Xachet modifications)**。分发时请保留对应源码、版权及第三方许可。

- 上游：[wyvern1723/Sachet](https://github.com/wyvern1723/sachet)，感谢作者 **wyvern1723**。
- 原生视觉与组件：[MeiloX](https://github.com/NEORUAA/MeiloX)、[Glasmio](https://github.com/NEORUAA/Glasmio)。未复制 Apple 字体。
- 轮廓、动画与字体：Kyant0/Shapes、Cresto、MiSans；各自遵循独立许可。
- 历史 Flutter 实现还参考 NexioSchedule、Kyant Backdrop、HyperCeiler，保留相关来源及声明。

完整来源与许可证见 [第三方说明](THIRD_PARTY_NOTICES.md)。问题请在 [Xachet Issues](https://github.com/Pluvist/Xachet/issues) 反馈。

大部分构建与本日志由 AI 完成。感谢学长 @wyvern1723 的付出，希望湘潭大学可以越办越好。如果 Xachet 对你有帮助，欢迎 Star。
