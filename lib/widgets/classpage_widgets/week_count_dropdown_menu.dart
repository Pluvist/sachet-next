import 'package:flutter/material.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/widgets/utils_widgets/miuix_popup.dart';
import 'package:provider/provider.dart';

class WeekCountDropdownMenu extends StatefulWidget {
  const WeekCountDropdownMenu({super.key});

  @override
  State<WeekCountDropdownMenu> createState() => _WeekCountDropdownMenuState();
}

class _WeekCountDropdownMenuState extends State<WeekCountDropdownMenu> {
  @override
  Widget build(BuildContext context) {
    int curveDuration = context.select<SettingsProvider, int>(
        (settingsProvider) => settingsProvider.curveDuration);
    String curveType = context.select<SettingsProvider, String>(
        (settingsProvider) => settingsProvider.curveType);
    int currentWeekCount = context.select<ClassPageProvider, int>(
        (classPageModel) => classPageModel.currentWeekCount);
    return MiuixPopup<int>(
      tooltip: '选择周次',
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('第 $currentWeekCount 周',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
      itemBuilder: (context) => pageMenuList
          .map((value) =>
              PopupMenuItem<int>(value: value, child: Text('第 $value 周')))
          .toList(),
      onSelected: (int? page) {
        if (page != null) {
          context.read<ClassPageProvider>().pageController.animateToPage(
                page - 1,
                duration: Duration(milliseconds: curveDuration),
                curve: curveTypes[curveType] ?? Easing.standard,
              );
        }
      },
    );
  }
}

// List<int> pageMenuList = <int>[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19];
List<int> pageMenuList = List.generate(20, (i) => i + 1);
