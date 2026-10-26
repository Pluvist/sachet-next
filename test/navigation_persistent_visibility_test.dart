import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/class_child_pages/week_view.dart';
import 'package:sachet/pages/with_navbar_view.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/app_global.dart';

class _MemorySettings extends SettingsProvider {
  @override
  Future<CourseScheduleData> loadCourseScheduleData() async => (
        courseScheduleItemsList: List.generate(35, (_) => <CourseSchedule>[]),
        courseColorData: <String, dynamic>{},
        classSessionSummerDataList: <dynamic>[],
        classSessionWinterDataList: <dynamic>[],
      );
}

void main() {
  late ScreenNavProvider nav;
  final toolbar = find.byKey(const ValueKey('floatingNavToolbar'));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppGlobal.init();
    AppGlobal.homeEntrancePending = false;
  });

  Future<void> idle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    nav = ScreenNavProvider()..setCurrentPage('/home');
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => nav),
      ChangeNotifierProvider<SettingsProvider>(
          create: (_) => _MemorySettings()),
      ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
      ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
    ], child: const MaterialApp(home: WithNavigationBarView())));
    await idle(tester);
  }

  testWidgets('Capsule stays visible from startup through an idle interval',
      (tester) async {
    await open(tester);
    expect(toolbar.hitTestable(), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(toolbar.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scrolling and inertia keep the capsule and page size unchanged',
      (tester) async {
    await open(tester);
    final page = find.descendant(
        of: find.byType(HomePage), matching: find.byType(CustomScrollView));
    final viewport = tester.getSize(page);
    for (final delta in [const Offset(0, -400), const Offset(0, 200)]) {
      await tester.fling(page, delta, 1400);
      await tester.pump(const Duration(milliseconds: 50));
      expect(toolbar.hitTestable(), findsOneWidget);
      expect(tester.getSize(page), viewport);
      await idle(tester);
      expect(toolbar.hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Capsule stays available while held and after switching tabs',
      (tester) async {
    await open(tester);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byTooltip('课程表')));
    await tester.pump(const Duration(milliseconds: 800));
    expect(toolbar.hitTestable(), findsOneWidget);
    await gesture.up();
    await idle(tester);
    expect(ScreenNavProvider.currentPage, '/class');
    expect(toolbar.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Week paging preserves a visible capsule and a fixed viewport',
      (tester) async {
    await open(tester);
    nav.setCurrentPage('/class');
    await idle(tester);
    final week =
        tester.element(find.byType(WeekView)).read<ClassPageProvider>();
    week.pageController.jumpToPage(3);
    await idle(tester);
    final pager = find.byType(PageView).hitTestable();
    final viewport = tester.getSize(pager);
    await tester.fling(pager, const Offset(-240, 0), 800);
    await tester.pump(const Duration(milliseconds: 16));
    expect(toolbar.hitTestable(), findsOneWidget);
    expect(tester.getSize(pager), viewport);
    await idle(tester);
    expect(week.pageController.page, 4);
    expect(toolbar.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Returning from a detail page leaves navigation visible',
      (tester) async {
    await open(tester);
    final navigator = Navigator.of(tester.element(find.byType(HomePage)));
    navigator.push<void>(MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Detail')))));
    await idle(tester);
    navigator.pop();
    await idle(tester);
    expect(toolbar.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
