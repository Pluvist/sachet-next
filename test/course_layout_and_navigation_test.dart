import 'package:sachet/models/app_settings.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/course_card_settings.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/classpage_widgets/course_card.dart';
import 'package:sachet/widgets/utils_widgets/nav_bottom.dart';

void main() {
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    AppGlobal.courseCardSettings = CourseCardSettings.fromJson({
      ...defaultCourseCardSettingsConfig,
      'cardHeight': 60.0,
      'cardMargin': 2.0,
    });
  });

  Future<void> pumpCourse(
    WidgetTester tester, {
    int length = 2,
    String place = '逸夫楼',
    int classCount = 0,
    double sectionHeight = 60,
    CourseCardVariant variant = CourseCardVariant.normal,
  }) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Column(children: [
            CourseCard(
              cardHeight: sectionHeight,
              weekCount: 1,
              weekday: 1,
              classCount: classCount,
              variant: variant,
              courseScheduleItems: [
                CourseSchedule(
                  title: '测试课程',
                  place: place,
                  length: length,
                  weeks: [1],
                ),
              ],
              courseColorData: const {},
            ),
            const SizedBox(key: ValueKey('nextSlot'), height: 20),
          ]),
        ),
      ),
    ));
  }

  testWidgets('Cards retain section layout in compact and preview layouts',
      (tester) async {
    for (final length in [2, 4]) {
      await pumpCourse(tester, length: length);
      final bar = tester.getRect(find.byType(InkWell));
      expect(bar.top, 2);
      expect(bar.height, length * 60 - 4);
      expect(tester.getTopLeft(find.byKey(const ValueKey('nextSlot'))).dy,
          length * 60);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Building recognition never translates a compact section slot',
      (tester) async {
    await pumpCourse(tester, place: '教学楼');
    expect(tester.getRect(find.byType(InkWell)).top, 2);
    expect(tester.getRect(find.byType(InkWell)).height, 116);
    await pumpCourse(tester, classCount: 4, length: 3);
    expect(tester.getRect(find.byType(InkWell)).top, 2);
    expect(tester.getRect(find.byType(InkWell)).height, 176);
    await pumpCourse(tester, classCount: 3, length: 4);
    expect(tester.getRect(find.byType(InkWell)).top, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact views ignore obsolete fixed adjustment', (tester) async {
    await pumpCourse(tester,
        sectionHeight: 10, variant: CourseCardVariant.compact);
    expect(tester.getRect(find.byType(InkWell)).height, 18);
    AppGlobal.courseCardSettings.cardHeight = 160;
    await pumpCourse(tester,
        sectionHeight: 10, variant: CourseCardVariant.compact);
    expect(tester.getRect(find.byType(InkWell)).height, 18);
    expect(tester.getTopLeft(find.byKey(const ValueKey('nextSlot'))).dy, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Floating navigation fits a narrow screen and switches pages',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = ScreenNavProvider()..setCurrentPage('/class');
    const routes = ['/class', '/home', '/profile'];
    const destinations = [
      NavDestination(
          label: '课程表',
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          page: SizedBox(),
          routeName: '/class'),
      NavDestination(
          label: '主页',
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          page: SizedBox(),
          routeName: '/home'),
      NavDestination(
          label: '我',
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          page: SizedBox(),
          routeName: '/profile'),
    ];
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: applyExpressiveTheme(ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green, brightness: brightness),
            useMaterial3: true,
          )),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              padding: EdgeInsets.only(bottom: 24),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              bottomNavigationBar: Consumer<ScreenNavProvider>(
                builder: (_, provider, __) => NavBottom(
                  destinations: destinations,
                  routeNames: routes,
                  currentPageIndex:
                      routes.indexOf(ScreenNavProvider.currentPage),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final bar =
          tester.getRect(find.byKey(const ValueKey('floatingNavToolbar')));
      expect(bar.left, greaterThanOrEqualTo(16));
      expect(bar.right, lessThanOrEqualTo(304));
      expect(bar.center.dx, 160);
      expect(bar.bottom, lessThanOrEqualTo(616));
      final maskFinder = find.byKey(const ValueKey('floatingNavBottomMask'));
      final mask = tester.widget<DecoratedBox>(maskFinder);
      final gradient =
          (mask.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(gradient.colors.first.alpha, 0);
      expect(gradient.colors.last,
          brightness == Brightness.dark ? Colors.black : Colors.white);
      expect(tester.getRect(maskFinder).top, lessThan(bar.top));
      expect(tester.getRect(maskFinder).bottom, 640);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Semantics &&
              widget.properties.label == '课程表' &&
              widget.properties.selected == true),
          findsOneWidget);
      await tester.tap(find.byTooltip('我'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(ScreenNavProvider.currentPage, '/profile');
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Semantics &&
              widget.properties.label == '我' &&
              widget.properties.selected == true),
          findsOneWidget);
      expect(tester.getSize(find.byTooltip('我')).width,
          tester.getSize(find.byTooltip('主页')).width);
      await tester.tap(find.byTooltip('课程表'));
      await tester.pumpAndSettle();
      expect(ScreenNavProvider.currentPage, '/class');
      expect(tester.takeException(), isNull);
    }
  });
}
