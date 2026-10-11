import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sachet/pages/with_navbar_view.dart';
import 'package:sachet/pages/class_child_pages/week_view.dart';
import 'package:sachet/pages/class_child_pages/single_week_page.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/providers/theme_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/models/course_schedule.dart';

class _MemorySettings extends SettingsProvider {
  Future<CourseScheduleData>? _future;
  @override
  Future<CourseScheduleData> loadCourseScheduleData() =>
      _future ??= Future.value((
        courseScheduleItemsList: List.generate(
            35,
            (slot) => [
                  CourseSchedule(
                    item: slot,
                    title: '课程 $slot',
                    place: slot.isEven ? '逸夫楼201' : '教三楼301',
                    length: 2,
                    weeks: List.generate(20, (i) => i + 1),
                  )
                ]),
        courseColorData: <String, dynamic>{},
        classSessionSummerDataList: <dynamic>[],
        classSessionWinterDataList: <dynamic>[],
      ));
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppGlobal.init();
  });

  test('Old transition preference cannot re-enable another transition', () {
    AppGlobal.appSettings.pageTransition = 'zoom';
    expect(ThemeProvider().transitionBuilder,
        isA<CupertinoPageTransitionsBuilder>());
    expect(ThemeProvider().pageTransition, 'cupertino');
  });

  test('Repeated readers share a cached future; explicit invalidation reloads',
      () async {
    final settings = SettingsProvider();
    final first = settings.loadCourseScheduleData();
    expect(identical(first, settings.loadCourseScheduleData()), isTrue);
    await first;
    settings.invalidateCourseData();
    expect(identical(first, settings.loadCourseScheduleData()), isFalse);
    await settings.loadCourseScheduleData();
    settings.dispose();
  });

  testWidgets(
      'Real capsule preserves week controller over 40 switches and back',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final nav = ScreenNavProvider()..setCurrentPage('/class');
    final cachedSettings = _MemorySettings();
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: nav),
      ChangeNotifierProvider<SettingsProvider>.value(value: cachedSettings),
      ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
      ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
    ], child: const MaterialApp(home: WithNavigationBarView())));
    await tester.pumpAndSettle();
    final week = tester.state(find.byType(WeekView));
    final provider = Provider.of<ClassPageProvider>(
        tester.element(find.byType(WeekView)),
        listen: false);
    provider.pageController.jumpToPage(6);
    await tester.pumpAndSettle();
    for (int i = 0; i < 40; i++) {
      await tester.tap(find.byTooltip(i.isEven ? '主页' : '课程表'));
      await tester.pumpAndSettle();
    }
    expect(identical(week, tester.state(find.byType(WeekView))), isTrue);
    expect(provider.currentWeekCount, 7);
    // Inactive home PopScope must not prevent leaving the startup class page.
    expect(await tester.binding.handlePopRoute(), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    nav.dispose();
    cachedSettings.dispose();
  });

  testWidgets('One finger does not rebuild weeks; two fingers still zoom',
      (tester) async {
    final provider = ClassPageProvider();
    final settings = CourseCardSettingsProvider();
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ], child: const MaterialApp(home: Scaffold(body: WeekView()))));
    await tester.pumpAndSettle();
    int rebuilds = 0;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce &&
          (element.widget is WeekView || element.widget is SingleWeekPage)) {
        rebuilds++;
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    final gesture =
        await tester.startGesture(const Offset(300, 250), pointer: 1);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(rebuilds, 0);
    final height = settings.cardHeight;
    final first = await tester.startGesture(const Offset(220, 250), pointer: 2);
    final second =
        await tester.startGesture(const Offset(420, 250), pointer: 3);
    await tester.pump();
    await first.moveTo(const Offset(180, 250));
    await second.moveTo(const Offset(460, 250));
    await tester.pump();
    expect(tester.widget<PageView>(find.byType(PageView)).physics,
        isA<NeverScrollableScrollPhysics>());
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(settings.cardHeight, greaterThan(height));
    expect(tester.widget<PageView>(find.byType(PageView)).physics,
        isA<AlwaysScrollableScrollPhysics>());
    debugOnRebuildDirtyWidget = null;
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    settings.dispose();
  });
}
