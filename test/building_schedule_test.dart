import 'package:sachet/widgets/classpage_widgets/course_card.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_card_settings.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/pages/class_child_pages/single_week_page.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/building_schedule.dart';
import 'package:sachet/utils/time_manager.dart';
import 'package:sachet/widgets/classpage_widgets/course_timing_editor.dart';
import 'package:sachet/widgets/classpage_widgets/school_time_rail.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'appSettings': jsonEncode({
        ...defaultAppSettingsConfig,
        'isAutoCheckUpdate': false,
      })
    });
    await AppGlobal.init();
    AppGlobal.courseCardSettings =
        CourseCardSettings.fromJson(defaultCourseCardSettingsConfig);
  });

  test('Default card appearance matches the supplied settings screenshot', () {
    final settings = CourseCardSettingsProvider();
    expect(
        [settings.cardHeight, settings.cardBorderRadius, settings.cardMargin],
        [50.0, 6.0, 2.0]);
    expect([
      settings.titleFontSize,
      settings.placeFontSize,
      settings.instructorFontSize
    ], [
      13.0,
      9.0,
      8.0
    ]);
    expect([
      settings.titleFontWeight + 1,
      settings.placeFontWeight + 1,
      settings.instructorFontWeight + 1
    ], [
      9,
      5,
      3
    ]);
    expect([
      settings.titleMaxLines,
      settings.placeMaxLines,
      settings.instructorMaxLines
    ], [
      3,
      5,
      2
    ]);
    expect(intToFontWeight(settings.titleFontWeight), FontWeight.w900);
  });

  test('All eleven sections match the supplied school timetable', () {
    const expected = [
      '08:00–08:45',
      '08:55–09:40',
      '10:20–11:05',
      '11:15–12:00',
      '14:00–14:45',
      '14:55–15:40',
      '16:20–17:05',
      '17:15–18:00',
      '19:15–20:00',
      '20:10–20:55',
      '21:05–21:50',
    ];
    for (int section = 1; section <= 11; section++) {
      final normal = BuildingSchedule.lesson(section, BuildingRoutine.normal);
      final shifted =
          BuildingSchedule.lesson(section, BuildingRoutine.staggered);
      expect(normal.label, expected[section - 1]);
      expect(shifted.start - normal.start, section <= 8 ? 10 : 0);
      expect(shifted.end - normal.end, section <= 8 ? 10 : 0);
    }
    expect(
        BuildingSchedule.identify(' 逸 夫 楼 A-201 '), BuildingRoutine.staggered);
    expect(BuildingSchedule.identify('信息科技大楼-202'), BuildingRoutine.staggered);
    expect(BuildingSchedule.identify(null), BuildingRoutine.normal);
    expect(BuildingSchedule.identify('第三教学楼'), BuildingRoutine.normal);
  });

  test('Shared axis is monotonic and compresses only long breaks', () {
    const axis = SchoolTimeAxis(45);
    for (int minute = 481; minute <= 1310; minute++) {
      expect(axis.y(minute), greaterThan(axis.y(minute - 1)));
    }
    expect(axis.y(590) - axis.y(580), 10);
    expect(axis.y(620) - axis.y(580), 40);
    expect(axis.y(840) - axis.y(730), closeTo(20, 0.0001));
    expect(axis.y(1155) - axis.y(1090), closeTo(20, 0.0001));
    final normal = BuildingSchedule.course(1, 2, BuildingRoutine.normal);
    final shifted = BuildingSchedule.course(1, 2, BuildingRoutine.staggered);
    expect(normal.label, '08:00–09:40');
    expect(shifted.label, '08:10–09:50');
    expect(axis.courseHeight(normal), axis.courseHeight(shifted));
    expect(axis.y(shifted.start) - axis.y(normal.start), 10);
    expect(
        axis.displayY(shifted.start, BuildingRoutine.staggered) -
            axis.displayY(normal.start, BuildingRoutine.normal),
        15);
    for (int minute = 481; minute <= 1310; minute++) {
      expect(axis.displayY(minute, BuildingRoutine.staggered),
          greaterThan(axis.displayY(minute - 1, BuildingRoutine.staggered)));
    }
    for (final section in [9, 10, 11]) {
      final lesson =
          BuildingSchedule.lesson(section, BuildingRoutine.staggered);
      expect(axis.displayY(lesson.start, BuildingRoutine.staggered),
          axis.y(lesson.start));
      expect(axis.displayY(lesson.end, BuildingRoutine.staggered),
          axis.y(lesson.end));
    }

    expect(BuildingSchedule.course(8, 2, BuildingRoutine.staggered).label,
        '17:25–20:00');
    expect(BuildingSchedule.course(9, 30, BuildingRoutine.normal).label,
        '19:15–21:50');
    final calendar = getStartAndEndTime(
        item: 0,
        week: 1,
        courseLength: 2,
        semesterStartDate: DateTime(2026, 9, 7),
        routine: BuildingRoutine.staggered);
    expect(calendar.startTime, DateTime(2026, 9, 7, 8, 10));
    expect(calendar.endTime, DateTime(2026, 9, 7, 9, 50));
  });

  test('Rail modes and course overrides survive settings serialization',
      () async {
    final settings = SettingsProvider();
    final course = CourseSchedule(title: '实验', place: '逸夫楼', length: 2);
    settings.setTimeRailMode(TimeRailMode.dual);
    settings.setCourseRoutine(course, 0, 'normal');
    final saved =
        (await SharedPreferences.getInstance()).getString('appSettings')!;
    AppGlobal.appSettings = AppSettings.fromJson(jsonDecode(saved));
    expect(settings.timeRailMode, TimeRailMode.dual);
    expect(BuildingSchedule.resolve(course, 0, settings.courseRoutineOverrides),
        BuildingRoutine.normal);
    expect(BuildingSchedule.resolve(course, 1, settings.courseRoutineOverrides),
        BuildingRoutine.staggered);
    settings.setCourseRoutine(course, 0, 'auto');
    expect(BuildingSchedule.resolve(course, 0, settings.courseRoutineOverrides),
        BuildingRoutine.staggered);
    expect(BuildingSchedule.visibleRoutines(TimeRailMode.auto, []),
        {BuildingRoutine.normal});
    expect(
        BuildingSchedule.visibleRoutines(
            TimeRailMode.auto, [BuildingRoutine.staggered]),
        {BuildingRoutine.staggered});
    expect(
        BuildingSchedule.visibleRoutines(
            TimeRailMode.auto, BuildingRoutine.values),
        BuildingRoutine.values.toSet());
    for (final mode in TimeRailMode.values) {
      expect(BuildingSchedule.visibleRoutines(mode, BuildingRoutine.values),
          isNotEmpty);
    }
  });

  Future<void> pumpWeek(WidgetTester tester, List<List<CourseSchedule>> courses,
      {double scale = 1, int week = 1}) async {
    tester.view.physicalSize = const Size(376, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
        ],
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: SingleWeekPage(
                    weekCount: week,
                    courseScheduleItemsList: courses,
                    classSessionSummerDataList: null,
                    classSessionWinterDataList: null,
                    courseColorData: const {},
                    cardHeight: 65,
                    pointerCount: 0)))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Mixed buildings align with separate rail times; detail correction updates geometry',
      (tester) async {
    final courses = List.generate(35, (_) => <CourseSchedule>[]);
    courses[0].add(
        CourseSchedule(title: '普通课', place: '第三教学楼', length: 2, weeks: [1]));
    courses[5]
        .add(CourseSchedule(title: '错峰课', place: '逸夫楼', length: 2, weeks: [1]));
    await pumpWeek(tester, courses);
    const axis = SchoolTimeAxis(65);
    final normal =
        tester.getRect(find.byKey(const ValueKey('timed-course-1-0')));
    final shifted =
        tester.getRect(find.byKey(const ValueKey('timed-course-1-5')));
    expect(shifted.top - normal.top, closeTo(15 * 65 / 45, 0.001));
    expect(shifted.height, closeTo(normal.height, 0.001));
    BorderSide borderFor(String title) {
      final card = find.ancestor(
          of: find.text(title), matching: find.byType(CourseCardNormal));
      final surface = tester
          .widget<Card>(find.descendant(of: card, matching: find.byType(Card)));
      return (surface.shape! as RoundedRectangleBorder).side;
    }

    final color = Theme.of(tester.element(find.byType(SchoolTimeRail).first))
        .colorScheme
        .primary;
    expect(borderFor('错峰课').color, color);
    expect(borderFor('错峰课').width, 1.5);
    expect(borderFor('普通课'), BorderSide.none);

    final rail =
        tester.getTopLeft(find.byKey(const ValueKey('staggeredTimeRail')));
    final startLabel =
        tester.getRect(find.byKey(const ValueKey('rail-staggered-1-start')));
    expect(startLabel.top - rail.dy,
        closeTo(axis.displayY(490, BuildingRoutine.staggered), 0.001));
    expect(find.text('普通'), findsOneWidget);
    expect(find.text('错峰'), findsOneWidget);
    final leftRail =
        tester.getRect(find.byKey(const ValueKey('normalTimeRail')));
    final rightRail =
        tester.getRect(find.byKey(const ValueKey('staggeredTimeRail')));
    expect(leftRail.right, lessThanOrEqualTo(normal.left));
    expect(rightRail.left, greaterThan(shifted.right));
    expect(leftRail.top, rightRail.top);
    expect(leftRail.height, rightRail.height);
    expect(
        tester.getCenter(find.text('周一')).dx, closeTo(normal.center.dx, 0.001));

    await tester.tap(find.text('错峰课'));
    await tester.pumpAndSettle();
    expect(find.text('08:10–09:50'), findsOneWidget);
    expect(find.byType(CourseTimingEditor), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('普通作息').last);
    await tester.pumpAndSettle();
    expect(find.text('08:00–09:40'), findsOneWidget);
    final context = tester.element(find.byType(CourseTimingEditor));
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('timed-course-1-5'))).top,
        normal.top);
    expect(find.text('错峰'), findsOneWidget);
    expect(borderFor('错峰课'), BorderSide.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Large text, missing locations, empty weeks and full evening range remain scrollable',
      (tester) async {
    final courses = List.generate(35, (_) => <CourseSchedule>[]);
    courses[0].add(CourseSchedule(title: '未指定地点', length: 2, weeks: [1]));
    courses[4].add(
        CourseSchedule(title: '晚课', place: '信息科技大楼', length: 3, weeks: [1]));
    await pumpWeek(tester, courses, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('晚课'));
    await tester.pumpAndSettle();
    expect(find.text('21:50'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await pumpWeek(tester, courses, scale: 2, week: 2);
    expect(find.byType(SchoolTimeRail), findsNWidgets(2));
    expect(find.text('普通'), findsOneWidget);
    expect(find.text('错峰'), findsOneWidget);
    final settings =
        tester.element(find.byType(SingleWeekPage)).read<SettingsProvider>();
    settings.setTimeRailMode(TimeRailMode.staggered);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('normalTimeRail')), findsOneWidget);
    expect(
        tester.getRect(find.byKey(const ValueKey('staggeredTimeRail'))).right,
        376);
    expect(find.text('错峰'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
