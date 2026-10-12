import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/widgets/utils_widgets/miuix_popup.dart';
import 'package:provider/provider.dart';

class MonthCountDropdownMenu extends StatefulWidget {
  const MonthCountDropdownMenu({super.key});

  @override
  State<MonthCountDropdownMenu> createState() => _MonthCountDropdownMenuState();
}

class _MonthCountDropdownMenuState extends State<MonthCountDropdownMenu> {
  @override
  Widget build(BuildContext context) {
    int curveDuration = context.select<SettingsProvider, int>(
        (settingsProvider) => settingsProvider.curveDuration);
    String curveType = context.select<SettingsProvider, String>(
        (settingsProvider) => settingsProvider.curveType);
    List<MonthData> monthList =
        context.select<ClassPageProvider, List<MonthData>>(
            (classPageModel) => classPageModel.monthList);
    int currentMonth = context.select<ClassPageProvider, int>(
        (classPageModel) => classPageModel.currentMonth);

    return MiuixPopup<MonthData>(
      tooltip: '选择月份',
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
              monthList
                      .firstWhereOrNull((e) => e.month == currentMonth)
                      ?.label ??
                  '$currentMonth 月',
              style: const TextStyle(fontSize: 18))),
      itemBuilder: (context) => monthList
          .map((entry) =>
              PopupMenuItem<MonthData>(value: entry, child: Text(entry.label)))
          .toList(),
      onSelected: (MonthData? monthData) {
        if (monthData != null) {
          context.read<ClassPageProvider>().animateToMonth(
                month: monthData.month,
                duration: Duration(milliseconds: curveDuration),
                curve: curveTypes[curveType] ?? Easing.standard,
              );
        }
      },
    );
  }
}
