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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
      _preparation.schedule(() {
        widget.onPrepareHome?.call();
      });
    });
  }

  Future<void> _reload() async {
    try {
      final status = await CourseWidgetBridge.channel
          .invokeMapMethod<dynamic, dynamic>('backgroundStatus');
      if (mounted) setState(() => _status = status ?? {});
    } on MissingPluginException {
      /* Other platforms keep the optional guide. */
    } on PlatformException {/* Settings remain optional. */}
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
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    _preparation.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProvisionPage(
      title: '后台与桌面',
      symbol: MiuixSymbol.tune,
      busy: _opening,
      subtitle: '让课程状态及时更新，也能在桌面一眼看到',
      content:
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ProvisionPanel(
            child: Column(children: [
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
              subtitle: const Text('前往系统设置为 Sachet Next 开启自启动；是否开启请在系统中确认'),
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
