import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/utils/building_schedule.dart';
import 'package:sachet/widgets/classpage_widgets/school_time_rail.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/widgets/classpage_widgets/course_card.dart';
import 'package:sachet/widgets/classpage_widgets/day_of_the_week_topbar.dart';

class SingleWeekPage extends StatefulWidget {
  /// 为每周创建一个 SingleWeekPage
  const SingleWeekPage({
    super.key,
    required this.weekCount,
    required this.courseScheduleItemsList,
    required this.classSessionSummerDataList,
    required this.classSessionWinterDataList,
    required this.courseColorData,
    required this.cardHeight,
    required this.pointerCount,
  });
  final int weekCount;
  final List<List<CourseSchedule>>? courseScheduleItemsList;
  final Map? courseColorData;
  final List? classSessionSummerDataList;
  final List? classSessionWinterDataList;
  final double cardHeight;
  final int pointerCount;
  @override
  State<SingleWeekPage> createState() => _SingleWeekPageState();
}

class _SingleWeekPageState extends State<SingleWeekPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = context.watch<SettingsProvider>();
    final overrides = settings.courseRoutineOverrides;
    final axis = SchoolTimeAxis(widget.cardHeight);
    final active = <({int item, CourseSchedule course})>[];
    final lists = widget.courseScheduleItemsList ?? [];
    for (int item = 0; item < lists.length && item < 35; item++) {
      final index = lists[item].indexWhere((course) =>
          (course.weeks ?? []).contains(widget.weekCount) &&
          (course.title ?? '').isNotEmpty);
      if (index >= 0) active.add((item: item, course: lists[item][index]));
    }
    const routines = {BuildingRoutine.normal, BuildingRoutine.staggered};
    final sideWidth = routines.length == 2 ? 46.0 : 52.0;
    final leftWidth =
        routines.contains(BuildingRoutine.normal) ? sideWidth : 0.0;
    final rightWidth =
        routines.contains(BuildingRoutine.staggered) ? sideWidth : 0.0;
    Widget railHeading(BuildingRoutine routine) => SizedBox(
          width: sideWidth,
          height: 30,
          child: InkWell(
            onTap: () => showDialog<void>(
                context: context,
                builder: (context) => const AlertDialog(
                      title: Text('教学楼作息'),
                      content: Text(
                          '左侧普通：其他教学楼。\n右侧错峰：逸夫楼、信息科技大楼，第 1–8 节晚 10 分钟。\n第 9–11 节两侧时间一致。\n两侧时间栏始终显示，可在课程详情中手动纠正作息。'),
                    )),
            child: Center(
                child: Text(routine == BuildingRoutine.normal ? '普通' : '错峰',
                    style: TextStyle(
                        fontSize: 11,
                        color: routine == BuildingRoutine.staggered
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant))),
          ),
        );
    return Column(children: [
      DayOfTheWeekTopBar(
          weekCount: widget.weekCount,
          semesterStartDate: SettingsProvider.semesterStartDateDateTime,
          timeRailWidth: leftWidth,
          rightTimeRailWidth: rightWidth),
      Row(children: [
        if (leftWidth > 0) railHeading(BuildingRoutine.normal),
        const Expanded(child: SizedBox(height: 30)),
        if (rightWidth > 0) railHeading(BuildingRoutine.staggered),
      ]),
      Expanded(
          child: SingleChildScrollView(
        physics: widget.pointerCount >= 2
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (leftWidth > 0)
            SizedBox(
                width: leftWidth,
                child: SchoolTimeRail(
                    key: const ValueKey('normalTimeRail'),
                    axis: axis,
                    routines: const {BuildingRoutine.normal})),
          Expanded(
              child: SchoolTimeGrid(
            axis: axis,
            showStaggered: routines.contains(BuildingRoutine.staggered),
            child: SizedBox(
                height: axis.height,
                child: Stack(children: [
                  for (final gap in SchoolTimeAxis.breaks)
                    Positioned(
                        top: axis.y(gap.start),
                        left: 0,
                        right: 0,
                        height: axis.y(gap.end) - axis.y(gap.start),
                        child: IgnorePointer(
                            child: Center(
                                child: Text(gap.start == 730 ? '午休' : '晚休',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant))))),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (int weekday = 1; weekday <= 7; weekday++)
                      Expanded(
                          child: SizedBox(
                              height: axis.height,
                              child: Stack(children: [
                                for (final entry in active
                                    .where((e) => e.item ~/ 5 + 1 == weekday))
                                  Builder(builder: (context) {
                                    final routine = BuildingSchedule.resolve(
                                        entry.course, entry.item, overrides);
                                    final time = BuildingSchedule.course(
                                        entry.item % 5 * 2 + 1,
                                        entry.course.length ?? 2,
                                        routine);
                                    return Positioned(
                                      key: ValueKey(
                                          'timed-course-${widget.weekCount}-${entry.item}'),
                                      top: axis.displayY(time.start, routine),
                                      left: 0,
                                      right: 0,
                                      height: axis.displayCourseHeight(
                                          time, routine),
                                      child: CourseCard(
                                          cardHeight: widget.cardHeight,
                                          displayHeight:
                                              axis.displayCourseHeight(
                                                  time, routine),
                                          weekCount: widget.weekCount,
                                          weekday: weekday,
                                          classCount: entry.item % 5,
                                          courseScheduleItems:
                                              lists[entry.item],
                                          courseColorData:
                                              widget.courseColorData),
                                    );
                                  }),
                              ]))),
                  ]),
                ])),
          )),
          if (rightWidth > 0)
            SizedBox(
                width: rightWidth,
                child: SchoolTimeRail(
                    key: const ValueKey('staggeredTimeRail'),
                    axis: axis,
                    routines: const {BuildingRoutine.staggered})),
        ]),
      )),
    ]);
  }
}
