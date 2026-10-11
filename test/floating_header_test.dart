import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/pages/with_navbar_view.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/pages/profile_page.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/classpage_widgets/classpage_appbar.dart';
import 'package:sachet/widgets/classpage_widgets/week_count_dropdown_menu.dart';

void main() {
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson({
      ...defaultAppSettingsConfig,
      'semesterStartDate': '2026-09-01',
      'curveDuration': 1,
      'isAutoCheckUpdate': false,
    });
    AppGlobal.startupPage = '/class';
  });

  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(376, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Restored header preserves five button bounds and interactions',
      (tester) async {
    setPhoneSize(tester);
    final courses = ClassPageProvider();
    final settings = SettingsProvider();
    Future<void> pumpHeader({required bool restored}) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: courses),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          theme: applyExpressiveTheme(ThemeData(
            colorSchemeSeed: Colors.green,
            useMaterial3: true,
          )),
          home: Scaffold(
            appBar: restored
                ? ClassPageAppBar() as PreferredSizeWidget
                : AppBar(
                    titleSpacing: 12,
                    title: const WeekCountDropdownMenu(),
                    actions: [
                      ViewModeToggle(
                          currentViewMode: ClassScheduleViewMode.week,
                          onModeChanged: (_) {}),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            icon: const Icon(Icons.skip_previous_outlined),
                            tooltip: '上一周',
                            onPressed: () {}),
                        IconButton(
                            icon: const Icon(Icons.skip_next_outlined),
                            tooltip: '下一周',
                            onPressed: () {}),
                      ]),
                      IconButton(
                          icon: const Icon(Icons.today),
                          tooltip: '回到本周',
                          onPressed: () {}),
                      PopupMenuButton(tooltip: '更多操作', itemBuilder: (_) => []),
                    ],
                  ),
            body: PageView(
              controller: courses.pageController,
              onPageChanged: (page) => courses.updateCurrentWeekCount(page + 1),
              children: List.generate(20, (_) => const SizedBox.expand()),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    const labels = ['切换视图', '上一周', '下一周', '回到本周', '更多操作'];
    await pumpHeader(restored: false);
    final originalBounds = {
      for (final label in labels) label: tester.getRect(find.byTooltip(label)),
    };
    await pumpHeader(restored: true);
    for (final label in labels) {
      expect(tester.getRect(find.byTooltip(label)), originalBounds[label]);
    }
    expect(find.byKey(const ValueKey('courseTitleCapsule')), findsNothing);
    expect(find.byKey(const ValueKey('courseActionsCapsule')), findsNothing);
    final week = courses.currentWeekCount;
    await tester.tap(find.byTooltip('下一周'));
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, week + 1);
    await tester.tap(find.byTooltip('上一周'));
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, week);
    await tester.tap(find.byType(WeekCountDropdownMenu));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('第 2 周').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 2 周').last);
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, 2);
    await tester.tap(find.byTooltip('回到本周'));
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, week);
    await tester.tap(find.byTooltip('切换视图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('月').last);
    await tester.pumpAndSettle();
    expect(courses.currentViewMode, ClassScheduleViewMode.month);
    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    expect(find.text('课表设置'), findsOneWidget);
    expect(find.text('导出课表'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Page viewport continues behind floating bottom navigation',
      (tester) async {
    setPhoneSize(tester);
    final navigation = ScreenNavProvider()
      ..setCurrentPage('/home')
      ..showNavBottom();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: navigation),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
      ],
      child: MaterialApp(
        theme: applyExpressiveTheme(ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
        )),
        home: const WithNavigationBarView(),
      ),
    ));
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(CustomScrollView));
    final capsule =
        tester.getRect(find.byKey(const ValueKey('floatingNavToolbar')));
    expect(viewport.bottom, 800);
    expect(viewport.bottom, greaterThan(capsule.bottom));
    expect(capsule.left, greaterThan(0));
    expect(capsule.right, lessThan(376));
    expect(find.byTooltip('我'), findsNothing);
    expect(tester.getRect(find.byTooltip('主页')).left,
        lessThan(tester.getRect(find.byTooltip('课程表')).left));
    await tester.tap(find.byKey(const ValueKey('homeProfileButton')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('未登录'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.byKey(const ValueKey('floatingNavToolbar')), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('homeProfileButton')), findsOneWidget);
    expect(ScreenNavProvider.currentPage, '/home');
    expect(tester.takeException(), isNull);
  });
}
