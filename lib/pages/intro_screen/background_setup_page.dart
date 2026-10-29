import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sachet/services/course_widget_bridge.dart';
import 'package:sachet/widgets/intro_widgets/provision_page.dart';
import 'package:sachet/widgets/utils_widgets/course_widget_picker.dart';
import 'package:sachet/widgets/utils_widgets/idle_frame_work.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:sachet/widgets/utils_widgets/source_expand_route.dart';

class BackgroundSetupPage extends StatefulWidget {
  const BackgroundSetupPage(
      {super.key, this.completionBuilder, this.onPrepareHome});
  final WidgetBuilder? completionBuilder;
  final Future<void> Function()? onPrepareHome;
  @override
  State<BackgroundSetupPage> createState() => _BackgroundSetupPageState();
}

class _BackgroundSetupPageState extends State<BackgroundSetupPage>
    with WidgetsBindingObserver {
  final _continueKey = GlobalKey();
  final _preparation = IdleFrameWork();
  Map<dynamic, dynamic> _status = {};
  bool _opening = false;
  bool _active = true;
  bool _loadingStatus = false;
  bool _autostartPending = false;
  Timer? _statusTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPermissionGuide();
      _preparation.schedule(() {
        widget.onPrepareHome?.call();
      });
    });
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_active && (ModalRoute.of(context)?.isCurrent ?? false)) _reload();
    });
  }

  Future<void> _reload() async {
    if (_loadingStatus) return;
    _loadingStatus = true;
    try {
      final status = await CourseWidgetBridge.channel
          .invokeMapMethod<dynamic, dynamic>('backgroundStatus');
      if (mounted && jsonEncode(_status) != jsonEncode(status ?? {})) {
        setState(() => _status = status ?? {});
      }
    } on MissingPluginException {
      /* Other platforms keep the optional guide. */
    } on PlatformException {/* Settings remain optional. */} finally {
      _loadingStatus = false;
    }
  }

  Future<void> _startPermissionGuide() async {
    await _reload();
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    try {
      await CourseWidgetBridge.channel
          .invokeMethod<bool>('setupNotificationPermission');
      await _reload();
      _autostartPending = _status['autostartAvailable'] == true;
      _openPendingAutostart();
    } on MissingPluginException {
      // Optional on platforms without the Android bridge.
    } on PlatformException {
      // Individual settings remain available from the page.
    }
  }

  void _openPendingAutostart() {
    if (!mounted ||
        !_active ||
        !_autostartPending ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _autostartPending = false;
    _settings('autostart');
  }

  Future<void> _liveSettings(String kind) async {
    try {
      if (kind == 'notifications') {
        await CourseWidgetBridge.channel.invokeMethod<void>('livePermission');
      } else {
        await CourseWidgetBridge.channel
            .invokeMethod<void>('liveSettings', kind);
      }
      await _reload();
    } on MissingPluginException {
      if (mounted) _manualHelp();
    } on PlatformException {
      if (mounted) _manualHelp();
    }
  }

  Future<void> _settings(String kind) async {
    try {
      final opened = await CourseWidgetBridge.channel
          .invokeMethod<bool>('backgroundSettings', kind);
      if (opened != true && mounted) _manualHelp();
    } on MissingPluginException {
      if (mounted) _manualHelp();
    } on PlatformException {
      if (mounted) _manualHelp();
    }
  }

  void _manualHelp() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请在系统应用设置中，找到 Sachet Next 的后台运行和自启动设置')));
  Future<void> _continue() async {
    if (_opening) return;
    if (widget.completionBuilder == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _opening = true);
    await expandPage<void>(context, widget.completionBuilder!(context),
        sourceKey: _continueKey,
        sourceColor: Theme.of(context).colorScheme.primary);
    if (mounted) setState(() => _opening = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      _reload();
      _openPendingAutostart();
    }
  }

  @override
  void dispose() {
    _preparation.cancel();
    _statusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = _status['live'] as Map<dynamic, dynamic>?;
    return ProvisionPage(
        title: '后台与桌面',
        symbol: MiuixSymbol.tune,
        busy: _opening,
        subtitle: '让课程状态及时更新，也能在桌面一眼看到',
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ProvisionPanel(
              child: Column(children: [
            MiuixListTile(
                key: const ValueKey('setupNotifications'),
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('通知权限'),
                subtitle: Text(live == null
                    ? '正在检查权限状态'
                    : live['notifications'] == true
                        ? '已允许通知'
                        : '请允许通知，以显示课程状态'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _liveSettings('notifications')),
            MiuixListTile(
                key: const ValueKey('setupLiveActivity'),
                leading: const Icon(Icons.timer_outlined),
                title: const Text('系统实时活动'),
                subtitle: Text(live == null
                    ? '正在检查权限状态'
                    : live['supported'] != true
                        ? '当前系统使用持续课程通知'
                        : live['promoted'] == true
                            ? '已允许实时活动'
                            : '请在系统中允许实时活动'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _liveSettings('promoted')),
            MiuixListTile(
                key: const ValueKey('setupBackground'),
                leading: const Icon(Icons.battery_saver_outlined),
                title: const Text('允许后台运行'),
                subtitle: Text(_status['batteryUnrestricted'] == true
                    ? '系统电池优化已放行'
                    : '在系统中选择无限制或允许后台运行'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _settings('battery')),
            MiuixListTile(
                key: const ValueKey('setupAutostart'),
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('允许自启动'),
                subtitle: const Text('请在系统设置中开启；系统不提供状态查询'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _settings('autostart')),
          ])),
          const SizedBox(height: 16),
          ProvisionPanel(
              child: MiuixListTile(
                  key: const ValueKey('setupWidget'),
                  leading: const Icon(Icons.widgets_outlined),
                  title: const Text('添加桌面小组件'),
                  subtitle: Text((_status['widgetCount'] as int? ?? 0) > 0
                      ? '桌面已添加课程小组件，可继续添加其他尺寸'
                      : '选择 2×2 今日课程或 4×2 横向课程概览'),
                  trailing: const Icon(Icons.add_rounded),
                  onTap: () => showCourseWidgetPicker(context))),
          const SizedBox(height: 16),
          Text('这些设置均可稍后完成，不影响继续使用。不同手机的选项名称可能不同，按系统提示确认即可。',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        action: ExpansionAnchor(
            key: _continueKey,
            child: ProvisionButton(
                key: const ValueKey('backgroundSetupContinue'),
                label: widget.completionBuilder == null ? '完成' : '继续',
                onPressed: _opening ? null : _continue)));
  }
}
