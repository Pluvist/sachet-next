import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/services/course_widget_bridge.dart';
import 'package:sachet/widgets/settingspage_widgets/miuix_settings_list.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';

class CourseLiveActivitySettingsPage extends StatefulWidget {
  const CourseLiveActivitySettingsPage({super.key});
  @override
  State<CourseLiveActivitySettingsPage> createState() =>
      _CourseLiveActivitySettingsPageState();
}

class _CourseLiveActivitySettingsPageState
    extends State<CourseLiveActivitySettingsPage> with WidgetsBindingObserver {
  Map<dynamic, dynamic> status = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    try {
      final value = await CourseWidgetBridge.channel
          .invokeMapMethod<dynamic, dynamic>('liveStatus');
      if (mounted) setState(() => status = value ?? {});
    } on PlatformException catch (error) {
      debugPrint("Course activity unavailable: ${error.code}");
    } on MissingPluginException {
      debugPrint("Course activity is only available on Android.");
    }
  }

  Future<void> _settings(String kind) async {
    try {
      await CourseWidgetBridge.channel.invokeMethod<void>('liveSettings', kind);
    } on PlatformException catch (error) {
      debugPrint("Course activity unavailable: ${error.code}");
    } on MissingPluginException {
      debugPrint("Course activity is only available on Android.");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        context.watch<SettingsProvider>().isEnableCourseLiveActivity;
    return Scaffold(
        appBar: MiuixAppBar(title: const Text('课程实时活动')),
        body: MiuixSettingsList(children: [
          MiuixListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('课程实时活动'),
              subtitle: const Text('同步主页课程状态；无课当天不显示'),
              trailing: Switch.adaptive(
                  value: enabled,
                  onChanged: (value) async {
                    context
                        .read<SettingsProvider>()
                        .setEnableCourseLiveActivity(value);
                    if (value) {
                      try {
                        await CourseWidgetBridge.channel
                            .invokeMethod<void>('livePermission', false);
                      } on PlatformException catch (error) {
                        debugPrint(
                            "Course permission unavailable: ${error.code}");
                      } on MissingPluginException {
                        debugPrint(
                            "Course activity is only available on Android.");
                      }
                    }
                    _reload();
                  })),
          MiuixListTile(
              title: const Text('通知权限'),
              subtitle:
                  Text(status['notifications'] == true ? '已允许' : '允许通知后显示课程状态'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                try {
                  await CourseWidgetBridge.channel
                      .invokeMethod<void>('livePermission');
                } on PlatformException catch (error) {
                  debugPrint("Course permission unavailable: ${error.code}");
                } on MissingPluginException {
                  debugPrint("Course activity is only available on Android.");
                }
                _reload();
              }),
          MiuixListTile(
              title: const Text('系统实时活动'),
              subtitle: Text(status['supported'] == true
                  ? status['promoted'] == true
                      ? '系统已允许实时活动'
                      : '在系统中允许实时活动'
                  : '当前系统使用持续课程通知'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _settings('promoted')),
          MiuixListTile(
              title: const Text('准时更新'),
              subtitle: Text(status['exactAlarms'] == true
                  ? '已允许在上课、下课时更新'
                  : '允许闹钟权限可更准时切换课程状态'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _settings('exact')),
          const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  '上课时缩略内容只显示下课倒计时，课程详情展开查看；课前、课间显示下一堂课的时间和地点。今天全部结束后显示可清除的“课程已完成”提示。\n\n'
                  '完整课程信息可展开查看。状态栏短文字的长度和显示位置由系统决定；可以选择“今天不再显示”暂停当天活动。')),
        ]));
  }
}
