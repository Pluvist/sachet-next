import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sachet/pages/with_navbar_view.dart';
import 'package:sachet/pages/class_child_pages/week_view.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/widgets/classpage_widgets/day_of_the_week_topbar.dart';

class _MemorySettings extends SettingsProvider {
  @override
  Future<CourseScheduleData> loadCourseScheduleData() async => (
        courseScheduleItemsList: List.generate(
            35,
            (i) => [
                  CourseSchedule(
                      title: '课程${i ~/ 5 + 1}',
                      place: i.isEven ? '逸夫楼201' : '第三教学楼',
                      length: 2,
                      weeks: List.generate(20, (w) => w + 1))
                ]),
        courseColorData: <String, dynamic>{},
        classSessionSummerDataList: <dynamic>[],
        classSessionWinterDataList: <dynamic>[]
      );
}

void main() {
  final preview = Platform.environment['SACHET_VISUAL_QA_DIR'];
  setUpAll(() async {
    if (preview == null) return;
    final font = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(
          await File('C:/Windows/Fonts/msyh.ttc').readAsBytes())));
    await font.load();
  });
  Future<void> capture(WidgetTester tester, String name) async {
    if (preview == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(preview).create(recursive: true);
      await File('$preview/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppGlobal.init();
  });
  void size(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final brightness in Brightness.values) {
    testWidgets('Landscape uses top tabs and matching gradient $brightness',
        (tester) async {
      size(tester, const Size(900, 450));
      final nav = ScreenNavProvider()..setCurrentPage('/home');
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: nav),
            ChangeNotifierProvider<SettingsProvider>(
                create: (_) => _MemorySettings()),
            ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
            ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
            ChangeNotifierProvider(create: (_) => ClassPageProvider()),
          ],
          child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: const WithNavigationBarView())));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(const ValueKey('floatingNavToolbar')), findsNothing);
      final tabs = find.byKey(const ValueKey('floatingNavTopToolbar'));
      expect(tabs, findsOneWidget);
      expect(tester.getRect(tabs).center.dx, closeTo(450, .1));
      expect(tester.getRect(tabs).bottom, lessThan(80));
      expect(tester.getSize(tabs).height, 44);
      expect(tester.getSize(tabs).width, closeTo(270, .1));
      final mask = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('floatingNavTopMask')));
      final gradient =
          (mask.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.colors.first,
          brightness == Brightness.dark ? Colors.black : Colors.white);
      expect(gradient.colors.last.opacity, 0);
      await capture(tester, 'home-landscape-${brightness.name}');
      await tester.tap(find.byKey(const ValueKey('homeCourseStatusCard')));
      await tester.pumpAndSettle();
      expect(ScreenNavProvider.currentPage, '/home');
      expect(tabs, findsOneWidget);
      await tester.tap(find.byTooltip('课程表'));
      await tester.pumpAndSettle();
      expect(ScreenNavProvider.currentPage, '/class');
      final weekModel =
          tester.element(find.byType(WeekView)).read<ClassPageProvider>();
      weekModel.pageController.jumpToPage(22);
      await tester.pumpAndSettle();
      expect(weekModel.currentWeekCount, 6);
      await tester.tap(find.byTooltip('上一周'));
      await tester.pumpAndSettle();
      expect(weekModel.currentWeekCount, 5);
      expect(weekModel.pageController.page, 18);
      await tester.tap(find.byTooltip('下一周'));
      await tester.pumpAndSettle();
      expect(weekModel.currentWeekCount, 6);
      expect(weekModel.pageController.page, 22);
      await capture(tester, 'class-landscape-${brightness.name}');
      await tester.tap(find.byTooltip('主页'));
      await tester.pumpAndSettle();
      expect(ScreenNavProvider.currentPage, '/home');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'Landscape shows two days, all seven accessible, portrait restores week',
      (tester) async {
    size(tester, const Size(900, 450));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<SettingsProvider>(
          create: (_) => _MemorySettings()),
      ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
      ChangeNotifierProvider(create: (_) => ClassPageProvider()),
    ], child: MaterialApp(home: Scaffold(body: const WeekView()))));
    await tester.pumpAndSettle();
    final model =
        tester.element(find.byType(WeekView)).read<ClassPageProvider>();
    final pager = tester.widget<PageView>(find.byType(PageView));
    final seen = <int>{};
    for (var i = 0; i < 4; i++) {
      pager.controller!.jumpToPage(i);
      await tester.pumpAndSettle();
      final headers =
          tester.widgetList<DateAndWeekday>(find.byType(DateAndWeekday));
      expect(headers.length, 2);
      seen.addAll(headers.map((h) => h.weekday));
      expect(find.byKey(const ValueKey('normalTimeRail')), findsOneWidget);
      expect(find.byKey(const ValueKey('staggeredTimeRail')), findsOneWidget);
    }
    expect(seen, {1, 2, 3, 4, 5, 6, 7});
    expect(model.currentWeekCount, 1);
    tester.view.physicalSize = const Size(450, 900);
    await tester.pumpAndSettle();
    expect(find.byType(DateAndWeekday), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Real horizontal drags cross weeks both ways and controls retain dates',
      (tester) async {
    size(tester, const Size(900, 450));
    final model = ClassPageProvider()..updateCurrentWeekCount(5);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: model),
      ChangeNotifierProvider<SettingsProvider>(
          create: (_) => _MemorySettings()),
      ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
    ], child: const MaterialApp(home: Scaffold(body: WeekView()))));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    model.pageController.jumpToPage(5 * 4 - 1);
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 5);
    await tester.drag(find.byType(PageView), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 6);
    expect(
        tester
            .widgetList<DateAndWeekday>(find.byType(DateAndWeekday))
            .map((h) => h.weekday),
        [1, 2]);
    await tester.drag(find.byType(PageView), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 5);
    expect(
        tester
            .widgetList<DateAndWeekday>(find.byType(DateAndWeekday))
            .map((h) => h.weekday),
        [6, 7]);
    // Day arrow also moves across the boundary.
    await tester.tap(find.byTooltip('后两天'));
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 6);
    expect(model.pageForWeek(7), 24);
    // Preserve the logical week when rotating and round-trip the day group.
    tester.view.physicalSize = const Size(450, 900);
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 6);
    expect(model.pageController.page, 5);
    tester.view.physicalSize = const Size(900, 450);
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 6);
    expect(model.pageController.page, 20);
    // End of semester cannot overshoot.
    model.pageController.jumpToPage(79);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 20);
    expect(model.pageController.page, 79);
    model.pageController.jumpToPage(0);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(model.currentWeekCount, 1);
    expect(model.pageController.page, 0);
    expect(tester.takeException(), isNull);
  });
}
