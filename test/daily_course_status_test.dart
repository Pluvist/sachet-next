import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/building_schedule.dart';
import 'package:sachet/utils/daily_course_status.dart';
import 'package:sachet/widgets/homepage_widgets/home_course_status_card.dart';

void main() {
  final semester = DateTime(2026, 10, 5);
  List<List<CourseSchedule>> timetable() => List.generate(35, (_) => []);
  CourseSchedule course(String name, String place, {List<int>? weeks}) =>
      CourseSchedule(title: name, place: place, length: 2, weeks: weeks ?? [1]);
  DateTime at(int hour, int minute, [int second = 0]) =>
      DateTime(2026, 10, 5, hour, minute, second);
  DailyCourseStatus resolve(List<List<CourseSchedule>> data, DateTime now,
          {Map<String, String> overrides = const {}}) =>
      DailyCourseStatus.resolve(
          now: now,
          semesterStart: semester,
          courses: data,
          overrides: overrides);

  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    AppGlobal.appSettings.semesterStartDate = '2026-10-05';
  });

  test('Real lesson boundaries, breaks, weeks and day end', () {
    final data = timetable();
    data[0] = [course('数学', '第一教学楼')];
    data[1] = [course('物理', '第二教学楼')];
    expect(resolve(data, at(7, 59)).next!.course.title, '数学');
    expect(resolve(data, at(8, 0)).current!.section, 1);
    expect(resolve(data, at(8, 44, 59)).current, isNotNull);
    expect(resolve(data, at(8, 45)).current, isNull);
    expect(resolve(data, at(8, 45)).next!.section, 2);
    expect(resolve(data, at(8, 55)).current!.section, 2);
    expect(resolve(data, at(9, 40)).next!.course.title, '物理');
    expect(resolve(data, at(12, 0)).next, isNull);
    expect(resolve(data, at(12, 0)).lessons, hasLength(4));
    expect(resolve(data, DateTime(2026, 10, 6, 8)).lessons, isEmpty);
    expect(resolve(data, DateTime(2026, 10, 12, 8)).lessons, isEmpty);
    expect(resolve(data, DateTime(2026, 10, 4, 8)).lessons, isEmpty);
  });

  test('Building and manual overrides use real times rather than visual offset',
      () {
    final data = timetable();
    final late = course('数学', '逸夫楼 201');
    data[0] = [late];
    data[4] = [course('晚课', '信息科技大楼')];
    expect(resolve(data, at(8, 5)).current, isNull);
    expect(resolve(data, at(8, 10)).current!.start, at(8, 10));
    expect(resolve(data, at(8, 55)).current, isNull);
    expect(resolve(data, at(8, 55)).next!.start, at(9, 5));
    final key = BuildingSchedule.overrideKey(late, 0);
    expect(
        resolve(data, at(8, 0), overrides: {key: 'normal'}).current, isNotNull);
    expect(resolve(data, at(19, 15)).current!.start, at(19, 15));
    expect(lessonCountdown(const Duration(seconds: 2700)), '00:45:00');
    expect(lessonCountdown(const Duration(seconds: -1)), '00:00:00');
  });

  Future<void> pumpCard(WidgetTester tester,
      {Future<List<List<CourseSchedule>>?> Function()? loader,
      DateTime Function()? clock}) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 376,
                  child:
                      HomeCourseStatusCard(loadCourses: loader, now: clock)))),
    ));
    await tester.pump();
  }

  Future<void> disposeCard(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('Countdown ticks without rereading file and changes at class end',
      (tester) async {
    final data = timetable();
    data[0] = [course('数学', '逸夫楼 201')];
    data[1] = [course('物理', '第一教学楼')];
    var now = at(8, 54, 58);
    var reads = 0;
    await pumpCard(tester,
        loader: () async {
          reads++;
          return data;
        },
        clock: () => now);
    expect(find.text('数学'), findsOneWidget);
    expect(find.text('剩余 00:00:02'), findsOneWidget);
    expect(find.byKey(const ValueKey('courseStatusGoingIcon')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('courseStatusCompletedIcon')), findsNothing);
    expect(find.text('下一节：数学 · 逸夫楼 201'), findsOneWidget);
    now = at(8, 54, 59);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('剩余 00:00:01'), findsOneWidget);
    now = at(8, 55);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('下一节 · 09:05 上课'), findsOneWidget);
    expect(find.byKey(const ValueKey('courseStatusGoingIcon')), findsOneWidget);
    now = at(11, 16);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('物理'), findsOneWidget);
    expect(find.text('今天没有下一节课啦'), findsOneWidget);
    now = at(12, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('今日课程已结束喵~'), findsOneWidget);
    expect(find.byKey(const ValueKey('courseStatusCompletedIcon')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('courseStatusGoingIcon')), findsNothing);
    now = DateTime(2026, 10, 6, 8);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('今日无课喵~'), findsOneWidget);
    expect(find.byKey(const ValueKey('courseStatusCompletedIcon')),
        findsOneWidget);
    expect(reads, 1);
    expect(tester.takeException(), isNull);
    await disposeCard(tester);
  });

  testWidgets('Missing timetable and failed reads are distinct from no classes',
      (tester) async {
    await pumpCard(tester);
    expect(find.text('请先导入课表'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('courseStatusCompletedIcon')), findsNothing);
    await disposeCard(tester);
    await pumpCard(tester, loader: () async => throw Exception('bad file'));
    expect(find.text('课表读取失败'), findsOneWidget);
    expect(find.text('今日无课喵~'), findsNothing);
    await disposeCard(tester);
  });
}
