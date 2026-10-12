import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:sachet/pages/settings_child_pages/theme_settings_page.dart';
import 'package:sachet/providers/theme_provider.dart';
import 'package:sachet/widgets/utils_widgets/section_card.dart';

class IntroThemeScreen extends StatefulWidget {
  /// 引导页：选择主题模式
  const IntroThemeScreen({super.key});

  @override
  State<IntroThemeScreen> createState() => _IntroThemeScreenState();
}

class _IntroThemeScreenState extends State<IntroThemeScreen> {
  @override
  Widget build(BuildContext context) {
    var themeProvider = context.watch<ThemeProvider>();
    return CustomScrollView(
      slivers: [
        MiuixSliverAppBar(
          pinned: true,
          snap: false,
          floating: false,
          title: Text('选择主题模式'),
        ),
        SliverList.list(children: [
          SizedBox(height: 20),
          SectionCard(
            title: '应用主题',
            childPadding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const <ButtonSegment<int>>[
                      ButtonSegment<int>(
                        value: 0,
                        icon: Icon(Icons.brightness_6_outlined),
                        label: Text('跟随系统'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('明亮'),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('黑暗'),
                      ),
                    ],
                    selected: <int>{themeProvider.themeMode},
                    onSelectionChanged: (Set<int> newSelection) {
                      context
                          .read<ThemeProvider>()
                          .setThemeMode(newSelection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          SectionCard(
            title: '主题颜色',
            child: Column(
              children: [
                // 动态取色开关
                MiuixListTile(
                  leading: Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.colorize,
                      color: themeProvider.isUsingDynamicColors
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  title: const Text('动态取色'),
                  subtitle: const Text('从壁纸提取主题色'),
                  trailing: Switch(
                      value: themeProvider.isUsingDynamicColors,
                      onChanged: (value) {
                        context
                            .read<ThemeProvider>()
                            .setIsUsingDynamicColors(value);
                      }),
                ),

                // 如果启用动态取色，隐藏这个供用户自定义主题色的组件
                Offstage(
                  offstage: themeProvider.isUsingDynamicColors,
                  // 可折叠（可展开）选择主题颜色 ListTile
                  child: ExpansionTile(
                    leading: const Align(
                      widthFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.palette),
                    ),
                    title: const Text('选择主题颜色'),
                    subtitle: Text('0x${colorToHex(themeProvider.themeColor)}'),
                    children: const [
                      SizedBox(height: 10),
                      ChooseThemeColor(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          const SectionCard(
            title: '界面风格',
            child: MiuixListTile(
                leading: Icon(Icons.auto_awesome_outlined),
                title: Text('Miuix'),
                subtitle: Text('统一的大标题、圆角卡片与轻量交互')),
          ),
          SizedBox(height: 80),
        ]),
      ],
    );
  }
}
