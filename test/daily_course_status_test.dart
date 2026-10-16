import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sachet/utils/expressive_theme.dart';
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
  final preview = Platform.environment['SACHET_OVERVIEW_PREVIEW_DIR'];
  setUpAll(() async {
    if (preview == null) return;
    final font = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(
          await File('C:/Windows/Fonts/msyh.ttc').readAsBytes())));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(await File(
              'C:/Users/pluvi/dev/sachet-tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
          .readAsBytes())));
    await icons.load();
  });
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
      DateTime Function()? clock,
      double width = 376,
      double scale = 1,
      Brightness brightness = Brightness.light}) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MaterialApp(
          theme: applyExpressiveTheme(
              ThemeData(brightness: brightness, colorSchemeSeed: Colors.blue)),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: RepaintBoundary(
                      key: const ValueKey('courseOverviewPreview'),
                      child: SizedBox(
                          width: width,
                          child: HomeCourseStatusCard(
                              loadCourses: loader, now: clock)))))),
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
    expect(find.text('数学'), findsNWidgets(2));
    expect(find.text('00:00:02'), findsOneWidget);
    expect(find.byKey(const ValueKey('courseStatusGoingIcon')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('courseStatusCompletedIcon')), findsNothing);
    expect(find.text('09:05–09:50'), findsOneWidget);
    final next = find.byKey(const ValueKey('homeNextCourseCard'));
    expect(find.descendant(of: next, matching: find.text('逸夫楼 201')),
        findsOneWidget);
    now = at(8, 54, 59);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:01'), findsOneWidget);
    now = at(8, 55);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('课间休息'), findsOneWidget);
    expect(find.text('下一节 09:05 开始'), findsOneWidget);
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
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('homeCourseStatusCard')),
            matching: find.text('课表读取失败')),
        findsOneWidget);
    expect(find.text('今日无课喵~'), findsNothing);
    await disposeCard(tester);
  });
  for (final brightness in Brightness.values) {
    for (final size in [(376.0, 1.0), (320.0, 2.0), (900.0, 1.0)]) {
      testWidgets(
          'Overview keeps current/next/classrooms readable $brightness $size',
          (tester) async {
        final data = timetable();
        data[0] = [course('高等数学与空间解析几何', '信息科技大楼201')];
        data[1] = [course('大学物理实验与测量', '第三教学楼3-217')];
        await pumpCard(tester,
            loader: () async => data,
            clock: () => at(9, 20),
            width: size.$1,
            scale: size.$2,
            brightness: brightness);
        final current = find.byKey(const ValueKey('homeCourseStatusCard'));
        final next = find.byKey(const ValueKey('homeNextCourseCard'));
        final classrooms = find.byKey(const ValueKey('homeHeroCard'));
        expect(find.descendant(of: current, matching: find.text('高等数学与空间解析几何')),
            findsOneWidget);
        expect(find.descendant(of: next, matching: find.text('大学物理实验与测量')),
            findsOneWidget);
        expect(find.descendant(of: next, matching: find.text('10:20–11:05')),
            findsOneWidget);
        expect(find.descendant(of: next, matching: find.text('第三教学楼3-217')),
            findsOneWidget);
        expect(find.descendant(of: current, matching: find.byType(InkWell)),
            findsNothing);
        expect(find.descendant(of: classrooms, matching: find.byType(InkWell)),
            findsOneWidget);
        if (size.$2 == 1) {
          expect(tester.getRect(current).top, tester.getRect(next).top);
          expect(tester.getRect(current).bottom,
              tester.getRect(classrooms).bottom);
          expect(tester.getRect(current).right,
              lessThan(tester.getRect(next).left));
        } else {
          expect(tester.getRect(current).bottom,
              lessThan(tester.getRect(next).top));
        }
        expect(tester.takeException(), isNull);
        if (preview != null && size.$1 == 376) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('courseOverviewPreview')));
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(preview).create(recursive: true);
            await File('$preview/course-overview-${brightness.name}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await disposeCard(tester);
      });
    }
  }
}
