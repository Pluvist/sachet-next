import 'package:sachet/widgets/settingspage_widgets/miuix_settings_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/widgets/settingspage_widgets/advanced_settings_widgets/delete_cached_data_dialog.dart';
import 'package:sachet/widgets/settingspage_widgets/advanced_settings_widgets/set_curve_duration_dialog.dart';
import 'package:sachet/widgets/settingspage_widgets/advanced_settings_widgets/set_curve_type_dialog.dart';
import 'package:provider/provider.dart';
import 'package:sachet/widgets/settingspage_widgets/advanced_settings_widgets/set_free_classroom_sections_dialog.dart';

import 'package:sachet/widgets/settingspage_widgets/settings_section_title.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _scaffoldMessenger.hideCurrentSnackBar();
    super.dispose();
  }

  Future showDeleteCachedDataDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => DeleteCachedDataDialog(),
    );
    if (result == true) {
      _scaffoldMessenger.showSnackBar(SnackBar(content: Text('删除成功！')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("高级设置"),
      ),
      body: MiuixSettingsList(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: SettingsSectionTitle(
              title: '课程表页面动画',
              iconData: Icons.animation_outlined,
            ),
          ),
          // 翻页动画
          Selector<SettingsProvider, String>(
              selector: (_, settingsProvider) => settingsProvider.curveType,
              builder: (_, curveType, __) {
                return ListTile(
                  leading: const Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.view_array_outlined),
                  ),
                  title: const Text('翻页动画曲线'),
                  subtitle: Text(curveType),
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => SetCurveTypeDialog(),
                    );
                  },
                );
              }),
          Selector<SettingsProvider, int>(
              selector: (_, settingsProvider) => settingsProvider.curveDuration,
              builder: (_, curveDuration, __) {
                return ListTile(
                  leading: const Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.timer_outlined),
                  ),
                  title: const Text('翻页动画时长'),
                  subtitle: Text('$curveDuration ms'),
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => SetCurveDurationDialog(),
                    );
                  },
                );
              }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: SettingsSectionTitle(
              title: '显示设置',
              iconData: Icons.build,
            ),
          ),
          Selector<SettingsProvider, bool>(
              selector: (_, settingsProvider) =>
                  settingsProvider.isShowPageTurnArrow,
              builder: (_, isShowPageTurnArrow, __) {
                return ListTile(
                  leading: Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: isShowPageTurnArrow
                        ? const Icon(Icons.switch_right_outlined)
                        : const Icon(Icons.do_not_disturb_outlined),
                  ),
                  title: const Text('显示翻页箭头按钮'),
                  subtitle: Text('课程表页面切换上一周/下一周的按钮'),
                  trailing: Switch(
                    value: isShowPageTurnArrow,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .setIsShowPageTurnArrow(value);
                    },
                  ),
                );
              }),
          Selector<SettingsProvider, List>(
              selector: (_, settingsProvider) =>
                  settingsProvider.freeClassroomSections,
              builder: (_, sections, __) {
                return ListTile(
                  leading: const Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.horizontal_split),
                  ),
                  title: const Text('空闲教室查询节次分段'),
                  subtitle: Text(sections.join(',  ')),
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => SetFreeClassroomSectionsDialog(),
                    );
                  },
                );
              }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: SettingsSectionTitle(
              title: '应用设置',
              iconData: Icons.app_settings_alt,
            ),
          ),
          // 是否在外部浏览器打开链接开关
          if (defaultTargetPlatform == TargetPlatform.android)
            Selector<SettingsProvider, bool>(
                selector: (_, settingsProvider) =>
                    SettingsProvider.isOpenLinkInExternalBrowser,
                builder: (_, isOpenLinkInExternalBrowser, __) {
                  return ListTile(
                    leading: Align(
                      widthFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: isOpenLinkInExternalBrowser
                          ? const Icon(Icons.open_in_new)
                          : const Icon(Icons.open_in_new_off),
                    ),
                    title: const Text('在外部浏览器打开链接'),
                    subtitle: isOpenLinkInExternalBrowser
                        ? const Text('在外部浏览器打开（打开链接时离开应用）')
                        : const Text('在 Android Custom Tabs 打开（打开链接时不离开应用）'),
                    trailing: Switch(
                      value: isOpenLinkInExternalBrowser,
                      onChanged: (value) {
                        context
                            .read<SettingsProvider>()
                            .setIsOpenLinkInExternalBrowser(value);
                      },
                    ),
                  );
                }),
          if (defaultTargetPlatform == TargetPlatform.iOS)
            Selector<SettingsProvider, bool>(
                selector: (_, settingsProvider) =>
                    SettingsProvider.isOpenLinkInExternalBrowser,
                builder: (_, isOpenLinkInExternalBrowser, __) {
                  return ListTile(
                    leading: Align(
                      widthFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: isOpenLinkInExternalBrowser
                          ? const Icon(Icons.open_in_new)
                          : const Icon(Icons.open_in_new_off),
                    ),
                    title: const Text('在外部浏览器打开链接'),
                    subtitle: isOpenLinkInExternalBrowser
                        ? const Text('在外部浏览器打开（打开链接时离开应用）')
                        : const Text('在 SFSafariViewController 打开（打开链接时不离开应用）'),
                    trailing: Switch(
                      value: isOpenLinkInExternalBrowser,
                      onChanged: (value) {
                        context
                            .read<SettingsProvider>()
                            .setIsOpenLinkInExternalBrowser(value);
                      },
                    ),
                  );
                }),

          // 删除缓存数据
          ListTile(
            leading: Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Icon(Icons.delete_forever),
            ),
            title: const Text('删除缓存数据'),
            onTap: () async {
              await showDeleteCachedDataDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
