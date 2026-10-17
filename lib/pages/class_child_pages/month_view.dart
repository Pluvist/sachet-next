import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/pages/class_child_pages/single_month_page.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/time_manager.dart';

class MonthView extends StatefulWidget {
  final List<List<CourseSchedule>>? courseScheduleItemsList;
  final Map? courseColorData;
  final List? classSessionSummerDataList;
  final List? classSessionWinterDataList;

  const MonthView({
    super.key,
    this.courseScheduleItemsList,
    this.courseColorData,
    this.classSessionSummerDataList,
    this.classSessionWinterDataList,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  static const double _minCardHeight = 5.0;
  static const double _maxCardHeight = 50.0;

  double _cardHeight = 10.0;
  double _baseCardHeight = 10.0;
  int _pointerCount = 0;

  void _changePointers(int delta) {
    final wasScaling = _pointerCount >= 2;
    _pointerCount = (_pointerCount + delta).clamp(0, 10);
    if (wasScaling != (_pointerCount >= 2)) setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentWeekCount =
          context.read<ClassPageProvider>().currentWeekCount;

      final currentMonth = getDateFromWeekCountAndWeekday(
        semesterStartDate: SettingsProvider.semesterStartDateDateTime,
        weekCount: currentWeekCount,
        weekday: DateTime.now().weekday,
      ).month;
      context.read<ClassPageProvider>().jumpToMonth(month: currentMonth);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = context.read<ClassPageProvider>();
    model.configureMonthPaging(
        MediaQuery.orientationOf(context) == Orientation.portrait);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      model.updateMonthPage(model.pageForMonthIndex(model.currentMonthIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    context.select<ClassPageProvider, List<MonthData>>(
        (provider) => provider.monthList);
    final model = context.read<ClassPageProvider>();
    final monthList = model.displayMonths;
    final count = model.monthsPerPage;
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;

    Widget month(MonthData data) => RepaintBoundary(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(data.label,
                  key: ValueKey('month-heading-${data.monthDate}'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: SingleMonthPage(
                key: ValueKey(data.monthDate),
                month: data.month,
                monthDate: data.monthDate,
                courseScheduleItemsList: widget.courseScheduleItemsList,
                courseColorData: widget.courseColorData,
                classSessionSummerDataList: widget.classSessionSummerDataList,
                classSessionWinterDataList: widget.classSessionWinterDataList,
                cardHeight: _cardHeight,
                pointerCount: _pointerCount >= 2 ? 2 : 0,
                fitToViewport: portrait,
              ),
            ),
          ]),
        );

    return Listener(
      onPointerDown: (event) => _changePointers(1),
      onPointerUp: (event) => _changePointers(-1),
      onPointerCancel: (event) => _changePointers(-1),
      child: GestureDetector(
        onScaleStart: (details) {
          _baseCardHeight = _cardHeight;
        },
        onScaleUpdate: (details) {
          if (details.pointerCount < 2) return;
          setState(() {
            _cardHeight = (_baseCardHeight * details.scale)
                .clamp(_minCardHeight, _maxCardHeight);
          });
        },
        child: PageView.builder(
          key: ValueKey('month-pager-$count'),
          scrollDirection: portrait ? Axis.vertical : Axis.horizontal,
          controller: model.monthPageController,
          onPageChanged: model.updateMonthPage,
          physics: _pointerCount >= 2
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          // Prebuilding adjacent pages can lay out six calendars on a swipe.
          allowImplicitScrolling: false,
          itemCount: (monthList.length / count).ceil(),
          itemBuilder: (context, page) => Padding(
            // Leave room for the floating pill without covering the last row.
            padding: EdgeInsets.only(bottom: portrait ? 104 : 0),
            child: Column(children: [
              for (var offset = 0; offset < count; offset++) ...[
                if (offset > 0) const Divider(height: 12, thickness: .5),
                Expanded(
                  child: page * count + offset < monthList.length
                      ? month(monthList[page * count + offset])
                      : const SizedBox.expand(),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
