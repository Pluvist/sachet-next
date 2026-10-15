import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/settingspage_widgets/miuix_settings_list.dart';
import 'package:flutter/material.dart';
import 'package:sachet/constants/app_constants.dart';
import 'package:sachet/providers/theme_provider.dart';
import 'package:sachet/widgets/settingspage_widgets/theme_settings_widgets/choose_theme_mode_dialog.dart';
import 'package:sachet/widgets/settingspage_widgets/theme_settings_widgets/pick_theme_color_dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: MiuixAppBar(title: const Text("应用主题")),
      body: MiuixSettingsList(
        children: [
          // 选择主题模式(系统、明亮、黑暗)
          Selector<ThemeProvider, int>(
              selector: (_, themeProvider) => themeProvider.themeMode,
              builder: (_, themeMode, __) {
                return MiuixListTile(
                  leading: Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: themeMode == 0
                        ? const Icon(Icons.contrast)
                        : themeMode == 1
                            ? const Icon(Icons.light_mode_outlined)
                            : const Icon(Icons.dark_mode),
                  ),
                  title: const Text('主题选择'),
                  subtitle: const Text('明亮、黑暗、跟随系统'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          ChooseThemeModeDialog(themeMode: themeMode),
                    );
                  },
                );
              }),
          const MiuixListTile(
            leading: Icon(Icons.auto_awesome_outlined),
            title: Text('界面风格'),
            subtitle: Text('Miuix · 大标题与圆角分组'),
          ),

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
    );
  }
}

class ChooseThemeColor extends StatefulWidget {
  const ChooseThemeColor({super.key});

  @override
  State<ChooseThemeColor> createState() => _ChooseThemeColorState();
}

class _ChooseThemeColorState extends State<ChooseThemeColor> {
  Future _showChangeThemeColorDialog(
    BuildContext context,
    Color pickerColor,
  ) async {
    Color? result = await showDialog(
      context: context,
      builder: (context) => PickThemeColorDialog(pickerColor: pickerColor),
    );

    if (!context.mounted) return;

    if (result != null) {
      context.read<ThemeProvider>().setThemeColor(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = context.select<ThemeProvider, Color>(
        (themeProvider) => themeProvider.themeColor);
    final Color inversePrimary = Theme.of(context).colorScheme.inversePrimary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        // alignment: WrapAlignment.spaceBetween,
        spacing: 4,
        runSpacing: 4,
        direction: Axis.horizontal,
        children: [
          // MaterialColors
          ...defaultThemeColors.map<Widget>((e) {
            return GestureDetector(
              child: SizedBox(
                height: 100,
                width: 70,
                child: MiuixCard(
                  color: e,
                  shape: (themeColor.value == e.value)
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: e.shade200,
                            width: 4,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        )
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                  elevation: 0,
                  child: Center(
                    child: themeColor.value == e.value
                        ? Icon(Icons.check_circle_outlined, color: onPrimary)
                        : null,
                  ),
                ),
              ),
              onTap: () => context.read<ThemeProvider>().setThemeColor(e),
            );
          }),
          // 应用主题色(brand color)
          GestureDetector(
            child: SizedBox(
              height: 100,
              width: 70,
              child: MiuixCard(
                color: appBrandColor,
                shape: (themeColor.value == appBrandColor.value)
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                          color: inversePrimary,
                          width: 4,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      )
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                elevation: 0,
                child: Center(
                  child: themeColor.value == Colors.white.value
                      ? Icon(Icons.check_circle_outlined, color: onPrimary)
                      : Icon(Icons.android, color: onPrimary),
                ),
              ),
            ),
            onTap: () {
              context.read<ThemeProvider>().setThemeColor(appBrandColor);
            },
          ),
          // 自定义颜色
          GestureDetector(
            child: SizedBox(
              height: 100,
              width: 70,
              // padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: MiuixCard(
                color: themeColor,
                shape:
                    // 是否预设的 Global.themes 列表中没有 一项的值 == 当前主题颜色的值（即任意一项都不等于当前主题颜色），且不是 brand color, 说明当前颜色为用户自定义的颜色
                    (!defaultThemeColors.any((element) =>
                                element.value == themeColor.value) &&
                            themeColor.value != appBrandColor.value)
                        ? RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                              color: onPrimary,
                              width: 4,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          )
                        : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                elevation: 0,
                child: Center(
                  child: themeColor.value == Colors.white.value
                      ? Icon(Icons.check_circle_outlined, color: onPrimary)
                      : Icon(Icons.colorize, color: onPrimary),
                ),
              ),
            ),
            onTap: () async {
              await _showChangeThemeColorDialog(context, themeColor);
            },
          ),
        ],
      ),
    );
  }
}
