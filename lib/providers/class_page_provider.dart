import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/time_manager.dart';

class MonthData {
  int index;
  int month;
  DateTime monthDate;
  String label;
  MonthData(this.index, this.month, this.monthDate, this.label);
}

enum ClassScheduleViewMode { week, month, semester }

class ClassPageProvider extends ChangeNotifier {
  // 转到 Class_Page 页面中的数字时需要转化, pageList 的 list 是 [0,1,2...19]
  // 第一页(pagelist[0]) => 第一周
  // 所以需要 - 1
  // 比如  _pageController.animateToPage(int index),index = currentWeekCount - 1;

  // final int _todayWeekCount = weekCountOfToday(semesterStartDate);
  // int get todayWeekCount => _todayWeekCount;

  // 当前页面周次（显示的周次，会随着页面的变化变化）
  int _currentWeekCount =
      weekCountOfToday(SettingsProvider.semesterStartDateDateTime)
          .clamp(1, 20); // 如果当前周次超过最大周次，使用最大周次(防止超出 List length,虽然实际上完全不会报错)
  int get currentWeekCount => _currentWeekCount;

  int _currentMonth = DateTime.now().month;
  int get currentMonth => _currentMonth;
  PageController? _monthPageController;
  int _monthsPerPage = 2;
  int get monthsPerPage => _monthsPerPage;
  int get currentMonthIndex => _monthList
      .indexWhere((entry) => entry.month == _currentMonth)
      .clamp(0, _monthList.length - 1);
  int pageForMonthIndex(int index) => index ~/ _monthsPerPage;
  PageController get monthPageController => _monthPageController ??=
      PageController(initialPage: pageForMonthIndex(currentMonthIndex));
  List<MonthData> get displayMonths {
    if (_monthsPerPage == 1 || _monthList.length.isEven) return _monthList;
    final next =
        DateTime(_monthList.last.monthDate.year, _monthList.last.month + 1);
    return [
      ..._monthList,
      MonthData(
          _monthList.length, next.month, next, '${next.year}年${next.month}月'),
    ];
  }

  List<MonthData> get visibleMonths {
    final start = pageForMonthIndex(currentMonthIndex) * _monthsPerPage;
    return displayMonths.skip(start).take(_monthsPerPage).toList();
  }

  String get visibleMonthLabel {
    final months = visibleMonths;
    if (months.length == 1) return months.first.label;
    final first = months.first.monthDate;
    final last = months.last.monthDate;
    return first.year == last.year
        ? '${first.year}年${first.month}–${last.month}月'
        : '${months.first.label}–${months.last.label}';
  }

  // Month paging has its own controller, so returning to the week view cannot
  // reinterpret a month page as a week (or lose a landscape two-week position).
  void configureMonthPaging(bool portrait) {
    final count = portrait ? 2 : 1;
    if (_monthsPerPage == count) return;
    _monthsPerPage = count;
    final previous = _monthPageController;
    _monthPageController =
        PageController(initialPage: pageForMonthIndex(currentMonthIndex));
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void updateMonthPage(int page) =>
      updateCurrentMonthByIndex(page * _monthsPerPage);

  PageController _pageController = PageController(
      initialPage: weekCountOfToday(SettingsProvider.semesterStartDateDateTime)
              .clamp(1, 20) -
          1);
  PageController get pageController => _pageController;
  int _weeksPerPage = 1;
  int get weeksPerPage => _weeksPerPage;
  int pageForWeek(int week) => (week.clamp(1, 20) - 1) ~/ _weeksPerPage;
  int get firstVisibleWeek =>
      pageForWeek(_currentWeekCount) * _weeksPerPage + 1;

  void configureWeekPaging(bool landscape) {
    final count = landscape ? 2 : 1;
    if (_weeksPerPage == count) return;
    _weeksPerPage = count;
    final previous = _pageController;
    _pageController =
        PageController(initialPage: pageForWeek(_currentWeekCount));
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  void updateWeekPage(int page) {
    final week = page * _weeksPerPage + 1;
    if (week != _currentWeekCount) updateCurrentWeekCount(week);
  }

  ClassScheduleViewMode _currentViewMode = ClassScheduleViewMode.week;
  ClassScheduleViewMode get currentViewMode => _currentViewMode;

  List<MonthData> _monthList = getMonthList(
      SettingsProvider.semesterStartDateDateTime,
      getDateFromWeekCountAndWeekday(
        semesterStartDate: SettingsProvider.semesterStartDateDateTime,
        weekCount: 20,
        weekday: 7,
      ));
  List<MonthData> get monthList => _monthList;

  static List<MonthData> getMonthList(DateTime startDate, DateTime endDate) {
    final List<MonthData> monthList = [];
    final start = DateTime(startDate.year, startDate.month);
    final end = DateTime(endDate.year, endDate.month);
    DateTime iterateMonth = start;
    int index = 0;
    while (!iterateMonth.isAfter(end)) {
      monthList.add(
        MonthData(
          index,
          iterateMonth.month,
          iterateMonth,
          '${iterateMonth.year}年${iterateMonth.month}月',
        ),
      );
      index++;
      iterateMonth = iterateMonth.month == 12
          ? DateTime(iterateMonth.year + 1, 1)
          : DateTime(iterateMonth.year, iterateMonth.month + 1);
    }
    return monthList;
  }

  // // 初始化周次信息
  // void initValue() {
  //   var value = weekCountOfToday(DateTime(2024, 8, 26));
  //   _todayWeekCount = value;
  //   if (value > 20) {
  //     _currentWeekCount = 20;
  //   } else {
  //     _currentWeekCount = _todayWeekCount;
  //   }
  //   notifyListeners();
  // }

  // 更新当前周次
  void resetCurrentWeekCount() {
    _currentWeekCount =
        weekCountOfToday(SettingsProvider.semesterStartDateDateTime)
            .clamp(1, 20);
    notifyListeners();
  }

  // 更新当前周次
  void updateCurrentWeekCount(int i) {
    _currentWeekCount = i;
    notifyListeners();
  }

  void incrementCurrentWeekCount() {
    if (_currentWeekCount < 20) {
      _currentWeekCount++;
      notifyListeners();
    }
  }

  void decrementCurrentWeekCount() {
    if (_currentWeekCount > 1) {
      _currentWeekCount--;
      notifyListeners();
    }
  }

  void updatePageController(int index) {
    final previous = _pageController;
    _pageController = PageController(initialPage: index - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    notifyListeners();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _monthPageController?.dispose();
    super.dispose();
  }

  // 更新当前月份
  void updateCurrentMonth(int month) {
    if (_currentMonth == month) return;
    _currentMonth = month;
    notifyListeners();
  }

  void updateCurrentMonthByIndex(int index) {
    final newMonth = monthList.firstWhereOrNull((e) => e.index == index)?.month;
    if (newMonth == null) {
      return;
    }
    _currentMonth = newMonth;
    // Also refresh the month-range title after a change of orientation, when
    // the first visible month may stay the same but the page capacity changes.
    notifyListeners();
  }

  /// 动画跳到指定月（通过月份）
  void animateToMonth({required int month, Duration? duration, Curve? curve}) {
    final index = monthList.firstWhereOrNull((e) => e.month == month)?.index;
    if (index == null) {
      return;
    }
    animateToMonthIndex(monthIndex: index, duration: duration, curve: curve);
  }

  /// 动画跳到指定月（通过 Index）
  void animateToMonthIndex(
      {required int monthIndex, Duration? duration, Curve? curve}) {
    final index = monthIndex.clamp(0, monthList.length - 1);
    final page = pageForMonthIndex(index);
    if (monthPageController.hasClients) {
      monthPageController.animateToPage(
        page,
        duration: duration ?? const Duration(milliseconds: 420),
        curve: curve ?? Curves.easeOutCubic,
      );
    } else {
      _resetMonthController(page);
      updateMonthPage(page);
    }
  }

  /// 动画跳到上个月
  void animateToLastMonth({Duration? duration, Curve? curve}) {
    final currentMonthIndex =
        monthList.firstWhereOrNull((e) => e.month == _currentMonth)?.index;
    if (currentMonthIndex == null) {
      return;
    }
    final lastMonthIndex = currentMonthIndex - _monthsPerPage;
    animateToMonthIndex(
        monthIndex: lastMonthIndex, duration: duration, curve: curve);
  }

  /// 动画跳到下个月
  void animateToNextMonth({Duration? duration, Curve? curve}) {
    final currentMonthIndex =
        monthList.firstWhereOrNull((e) => e.month == _currentMonth)?.index;
    if (currentMonthIndex == null) {
      return;
    }
    final nextMonthIndex = currentMonthIndex + _monthsPerPage;
    animateToMonthIndex(
        monthIndex: nextMonthIndex, duration: duration, curve: curve);
  }

  /// 回到本月（今天所在的月份）
  void animateToTodayMonth({Duration? duration, Curve? curve}) {
    final now = DateTime.now();
    final index = monthList.indexWhere((entry) =>
        entry.monthDate.year == now.year && entry.month == now.month);
    animateToMonthIndex(
        monthIndex: index >= 0
            ? index
            : (now.isBefore(monthList.first.monthDate)
                ? 0
                : monthList.length - 1),
        duration: duration,
        curve: curve);
  }

  /// 无动画跳到指定月
  void jumpToMonth({required int month, Duration? duration, Curve? curve}) {
    final newIndex = monthList.firstWhereOrNull((e) => e.month == month)?.index;
    if (newIndex == null) {
      return;
    }
    final page = pageForMonthIndex(newIndex);
    if (monthPageController.hasClients) {
      monthPageController.jumpToPage(page);
    } else {
      _resetMonthController(page);
    }
    updateMonthPage(page);
  }

  void _resetMonthController(int page) {
    final previous = _monthPageController;
    _monthPageController = PageController(initialPage: page);
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void updateMonthList() {
    _monthList = getMonthList(
        SettingsProvider.semesterStartDateDateTime,
        getDateFromWeekCountAndWeekday(
          semesterStartDate: SettingsProvider.semesterStartDateDateTime,
          weekCount: 20,
          weekday: 7,
        ));
    if (!monthList.any((entry) => entry.month == _currentMonth)) {
      _currentMonth = monthList.first.month;
    }
    final page = pageForMonthIndex(currentMonthIndex);
    // The rebuilt pager reattaches to a correctly bounded month position.
    _resetMonthController(page);
    notifyListeners();
  }

  void updateClassScheduleViewMode(ClassScheduleViewMode viewMode) {
    _currentViewMode = viewMode;
    notifyListeners();
  }
}
