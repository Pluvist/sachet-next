import 'package:sachet/widgets/settingspage_widgets/miuix_settings_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/constants/app_info_constants.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sachet/utils/utils_functions.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String appVersion = '';
  String appBuildNumber = '';

  /// 上一次 Tap 时间
  DateTime? _lastTapTime;

  /// 有效 Tap 次数
  int _tapCount = 0;
  late bool _isDeveloperModeEnabled;

  void _hitDev(BuildContext context) {
    Duration twoTapDuration =
        DateTime.now().difference(_lastTapTime ??= DateTime.now());
    // 如果间隔时间 < 500ms，记为有效 Tap => _tapCount++（如果是第一次 Tap，也记为有效 Tap）
    if (twoTapDuration < Duration(milliseconds: 500)) {
      _tapCount++;
    } else {
      // 间隔时间 >= 500ms，间隔过长，重置 _tapCount = 1
      _tapCount = 1;
    }
    _lastTapTime = DateTime.now();
    if (_tapCount == 7) {
      _tapCount = 0;
      if (_isDeveloperModeEnabled == false) {
        _isDeveloperModeEnabled = true;
        context.read<SettingsProvider>().enableDevMode();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('开发者模式已启用'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('您已处于开发者模式'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }
  }

  Future getAppVersion() async {
    // 获取 App 当前版本
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      appVersion = packageInfo.version;
      appBuildNumber = packageInfo.buildNumber;
    });
  }

  void showAboutAppDialog(BuildContext context) {
    showAboutDialog(
      applicationName: appName,
      applicationVersion: appVersion,
      applicationIcon: SizedBox(
        width: 74,
        height: 94,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Image.asset(
              'assets/icon/icon.png',
              fit: BoxFit.fill,
              width: 70,
              height: 70,
              cacheWidth:
                  (70 * MediaQuery.of(context).devicePixelRatio).round(),
              cacheHeight:
                  (70 * MediaQuery.of(context).devicePixelRatio).round(),
            ),
          ),
        ),
      ),
      applicationLegalese: '©2026 Pluvist\n上游版权：©2025 wyvern1723',
      children: [
        const Text(upstreamAcknowledgement),
        const SizedBox(height: 12),
        const Text('Sachet Next 遵循 MIT 许可证，以免费软件形式提供，不作任何担保。'),
      ],
      context: context,
    );
  }

  @override
  void initState() {
    super.initState();
    getAppVersion();
    _isDeveloperModeEnabled = context.read<SettingsProvider>().isEnableDevMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: MiuixSettingsList(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.fill,
                  cacheWidth:
                      (88 * MediaQuery.of(context).devicePixelRatio).round(),
                  cacheHeight:
                      (88 * MediaQuery.of(context).devicePixelRatio).round(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('作者'),
            subtitle: Text(authorName),
          ),
          const ListTile(
            leading: Icon(Icons.favorite_outline),
            title: Text('开源来源与鸣谢'),
            subtitle: Text(upstreamAcknowledgement),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于应用'),
            onTap: () => showAboutAppDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Sachet Next 源代码'),
            subtitle: const Text(sachetNextRepoUrl),
            onTap: () => openLink(sachetNextRepoUrl),
            onLongPress: () =>
                copyToClipboard(context, sachetNextRepoUrl, prefix: '链接'),
          ),
          ListTile(
            leading: const Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Icon(
                // Icons.web,
                Icons.web_asset,
                // Icons.attachment,
                // Icons.link,
              ),
            ),
            title: const Text('上游 Sachet 官网'),
            subtitle: const Text(appOfficialWebsiteUrl),
            onTap: () => openLink(appOfficialWebsiteUrl),
            onLongPress: () =>
                copyToClipboard(context, appOfficialWebsiteUrl, prefix: '链接'),
          ),
          ListTile(
            leading: const Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Icon(Icons.person),
            ),
            title: const Text('上游作者'),
            subtitle: const Text(upstreamAuthorName),
            onTap: () => openLink(appDeveloperProfileUrl),
          ),
          ListTile(
            leading: Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Icon(Icons.code),
            ),
            title: Text('上游 Sachet 源代码'),
            subtitle: Text(appRepoUrl),
            onTap: () => openLink(appRepoUrl),
            onLongPress: () =>
                copyToClipboard(context, appRepoUrl, prefix: '链接'),
          ),
          ListTile(
            leading: Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Icon(Icons.android),
            ),
            title: Text('当前版本'),
            subtitle: Text('v$appVersion ($appBuildNumber)  $abi'),
            onTap: () => _hitDev(context),
          ),
        ],
      ),
    );
  }
}
