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
import 'package:sachet/widgets/utils_widgets/liquid_dropdown_menu.dart';

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

  testWidgets('Header keeps one row of controls and the NexioSchedule menus',
      (tester) async {
    setPhoneSize(tester);
    final courses = ClassPageProvider();
    final settings = SettingsProvider();
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
          appBar: ClassPageAppBar() as PreferredSizeWidget,
          body: PageView(
            controller: courses.pageController,
            onPageChanged: (page) => courses.updateCurrentWeekCount(page + 1),
            children: List.generate(20, (_) => const SizedBox.expand()),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The title is plain text now; the week list lives behind the top-right
    // glass button instead of a clickable tab on the title.
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && (widget.data ?? '').startsWith('第 ')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('courseTitleCapsule')), findsNothing);
    expect(find.byKey(const ValueKey('courseActionsCapsule')), findsNothing);

    // Five controls, ordered left to right, all on one 56dp row.
    const labels = ['切换视图', '上一周', '下一周', '回到本周', '更多操作'];
    final rects = {
      for (final label in labels) label: tester.getRect(find.byTooltip(label)),
    };
    for (final label in labels) {
      expect(rects[label]!.top, greaterThanOrEqualTo(0));
      expect(rects[label]!.bottom, lessThanOrEqualTo(56));
    }
    for (var index = 1; index < labels.length; index++) {
      expect(rects[labels[index]]!.left,
          greaterThan(rects[labels[index - 1]]!.left),
          reason: '${labels[index]} must sit right of ${labels[index - 1]}');
    }
    // The two morphing controls keep the reference trigger footprint.
    for (final label in ['更多操作']) {
      expect(rects[label]!.width, kLiquidDropdownButtonDiameter);
      expect(rects[label]!.height, kLiquidDropdownButtonDiameter);
    }

    final week = courses.currentWeekCount;
    await tester.tap(find.byTooltip('下一周'));
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, week + 1);
    await tester.tap(find.byTooltip('上一周'));
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, week);

    expect(find.byTooltip('选择周次'), findsNothing);

    await tester.tap(find.byTooltip('回到本周'));
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, week);

    await tester.tap(find.byTooltip('切换视图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('月').last);
    await tester.pumpAndSettle();
    expect(courses.currentViewMode, ClassScheduleViewMode.month);

    // More actions: same control, opened from the right-most button.
    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    expect(find.text('课表设置'), findsWidgets);
    expect(find.text('导出课表'), findsWidgets);
    await tester.tapAt(const Offset(10, 400));
    await tester.pumpAndSettle();
    expect(find.text('导出课表'), findsNothing);
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
