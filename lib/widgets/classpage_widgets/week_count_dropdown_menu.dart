import 'package:flutter/material.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/widgets/utils_widgets/liquid_dropdown_menu.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:provider/provider.dart';

/// Top-right control of the course schedule.
///
/// The old form opened a plain list of tabs; this uses the NexioSchedule
/// control instead: one glass button in the app bar that grows into the week
/// list panel in place (see [LiquidGlassDropdownMenu]).
class WeekCountDropdownMenu extends StatefulWidget {
  const WeekCountDropdownMenu({super.key});

  @override
  State<WeekCountDropdownMenu> createState() => _WeekCountDropdownMenuState();
}

class _WeekCountDropdownMenuState extends State<WeekCountDropdownMenu> {
  bool _show = false;

  void _select(int page) {
    setState(() => _show = false);
    final settingsProvider = context.read<SettingsProvider>();
    context.read<ClassPageProvider>().pageController.animateToPage(
          page - 1,
          duration: Duration(milliseconds: settingsProvider.curveDuration),
          curve: curveTypes[settingsProvider.curveType] ?? Easing.standard,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentWeekCount = context.select<ClassPageProvider, int>(
        (classPageModel) => classPageModel.currentWeekCount);
    return LiquidGlassDropdownMenu(
      show: _show,
      itemCount: pageMenuList.length,
      entryLabels: [for (final week in pageMenuList) '第 $week 周'],
      icon: const MiuixGlyph(MiuixSymbol.calendar, size: 24),
      tooltip: '选择周次',
      semanticLabel: '选择周次',
      trailingBuilder: (index) => index + 1 == currentWeekCount
          ? const MiuixGlyph(MiuixSymbol.check, size: 18)
          : null,
      onExpanded: () => setState(() => _show = true),
      onDismissed: () => setState(() => _show = false),
      onSelected: (index) => _select(pageMenuList[index]),
    );
  }
}

// List<int> pageMenuList = <int>[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19];
List<int> pageMenuList = List.generate(20, (i) => i + 1);
