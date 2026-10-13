import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/widgets/utils_widgets/liquid_dropdown_menu.dart';
import 'package:sachet/widgets/utils_widgets/miuix_glyph.dart';
import 'package:provider/provider.dart';

/// Month counterpart of [WeekCountDropdownMenu]; same NexioSchedule style
/// top-right glass control, listing the semesters' months instead of weeks.
class MonthCountDropdownMenu extends StatefulWidget {
  const MonthCountDropdownMenu({super.key});

  @override
  State<MonthCountDropdownMenu> createState() => _MonthCountDropdownMenuState();
}

class _MonthCountDropdownMenuState extends State<MonthCountDropdownMenu> {
  bool _show = false;

  void _select(MonthData monthData) {
    setState(() => _show = false);
    final settingsProvider = context.read<SettingsProvider>();
    context.read<ClassPageProvider>().animateToMonth(
          month: monthData.month,
          duration: Duration(milliseconds: settingsProvider.curveDuration),
          curve: curveTypes[settingsProvider.curveType] ?? Easing.standard,
        );
  }

  @override
  Widget build(BuildContext context) {
    final monthList = context.select<ClassPageProvider, List<MonthData>>(
        (classPageModel) => classPageModel.monthList);
    final currentMonth = context.select<ClassPageProvider, int>(
        (classPageModel) => classPageModel.currentMonth);
    final currentIndex =
        monthList.indexWhere((entry) => entry.month == currentMonth);
    return LiquidGlassDropdownMenu(
      show: _show,
      itemCount: monthList.length,
      entryLabels: [for (final entry in monthList) entry.label],
      icon: const MiuixGlyph(MiuixSymbol.calendar, size: 24),
      tooltip: '选择月份',
      semanticLabel: '选择月份',
      trailingBuilder: (index) => index == currentIndex
          ? const MiuixGlyph(MiuixSymbol.check, size: 18)
          : null,
      onExpanded: () => setState(() => _show = true),
      onDismissed: () => setState(() => _show = false),
      onSelected: (index) {
        final entry = monthList.elementAtOrNull(index);
        if (entry != null) _select(entry);
      },
    );
  }
}
