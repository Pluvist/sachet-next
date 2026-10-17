import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_card_settings.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/pages/class_child_pages/month_view.dart';
import 'package:sachet/pages/class_child_pages/single_month_page.dart';
import 'package:sachet/pages/home_child_pages/grade_page_zf.dart';
import 'package:sachet/pages/with_navbar_view.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/classpage_widgets/classpage_appbar.dart';
import 'package:sachet/widgets/classpage_widgets/course_card.dart';
import 'package:sachet/widgets/classpage_widgets/course_details_bottom_sheet.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';

class _EmptyCalendarSettings extends SettingsProvider {
  @override
  Future<CourseScheduleData> loadCourseScheduleData() async => (
        courseScheduleItemsList: null,
        courseColorData: <String, dynamic>{},
        classSessionSummerDataList: <dynamic>[],
        classSessionWinterDataList: <dynamic>[],
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
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson({
      ...defaultAppSettingsConfig,
      'semesterStartDate': '2026-09-01',
    });
    AppGlobal.courseCardSettings = CourseCardSettings();
  });

  void size(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (preview == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(preview).create(recursive: true);
      await File('$preview/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<ClassPageProvider> monthPage(WidgetTester tester,
      {Size viewport = const Size(400, 860),
      Brightness brightness = Brightness.dark,
      double textScale = 1}) async {
    size(tester, viewport);
    final model = ClassPageProvider()
      ..updateCurrentWeekCount(1)
      ..updateClassScheduleViewMode(ClassScheduleViewMode.month);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: model),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
      ],
      child: MaterialApp(
        theme: applyExpressiveTheme(ThemeData(brightness: brightness)),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!),
        home: RepaintBoundary(
          key: const ValueKey('preview'),
          child: Scaffold(
            appBar: ClassPageAppBar(),
            body: MonthView(
              courseScheduleItemsList: List.generate(
                  35,
                  (i) => [
                        CourseSchedule(
                            title: '课程${i % 5 + 1}',
                            place: i.isEven ? '逸夫楼201' : '第三教学楼',
                            length: i % 5 == 4 ? 3 : 2,
                            weeks: List.generate(20, (w) => w + 1)),
                      ]),
              courseColorData: const {
                '课程1': '#4088EF',
                '课程2': '#36B8B4',
                '课程3': '#F4A445',
                '课程4': '#9C72DB',
                '课程5': '#D57591',
              },
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return model;
  }

  testWidgets(
      'Portrait shows two full calendars and swipes vertically across year',
      (tester) async {
    final model = await monthPage(tester);
    expect(model.visibleMonthLabel, '2026年9–10月');
    final pager = find.byKey(const ValueKey('month-pager-2'));
    expect(tester.widget<PageView>(pager).scrollDirection, Axis.vertical);
    expect(find.byType(SingleMonthPage), findsNWidgets(2));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byTooltip('选择月份'), findsNothing);
    expect(find.byTooltip('上个月'), findsNothing);
    expect(find.byTooltip('下个月'), findsNothing);
    final beforeWeek = model.currentWeekCount;
    await capture(tester, 'month-pair-dark');
    await tester.fling(pager, const Offset(0, -520), 900);
    await tester.pumpAndSettle();
    expect(model.visibleMonthLabel, '2026年11–12月');
    await tester.fling(pager, const Offset(0, -520), 900);
    await tester.pumpAndSettle();
    expect(model.visibleMonthLabel, '2027年1–2月');
    expect(model.visibleMonths, hasLength(2));
    expect(model.currentWeekCount, beforeWeek);
    await capture(tester, 'month-pair-year-boundary');
    await tester.tap(find.byTooltip('回到本月'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    if (now.year == 2026 && (now.month == 9 || now.month == 10)) {
      expect(model.visibleMonthLabel, '2026年9–10月');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Month rotation remaps its page and leaves week position untouched',
      (tester) async {
    final model = await monthPage(tester);
    final weekController = model.pageController;
    model.monthPageController.jumpToPage(1);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 450);
    await tester.pumpAndSettle();
    expect(model.monthsPerPage, 1);
    expect(model.monthPageController.page, 2);
    expect(find.text('2026年11月'), findsNWidgets(2));
    expect(tester.widget<PageView>(find.byType(PageView)).scrollDirection,
        Axis.horizontal);
    tester.view.physicalSize = const Size(400, 860);
    await tester.pumpAndSettle();
    expect(model.monthPageController.page, 1);
    expect(model.visibleMonthLabel, '2026年11–12月');
    expect(model.pageController, same(weekController));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Dense six-row months fit small screens and retain course details',
      (tester) async {
    final model = await monthPage(tester,
        viewport: const Size(360, 700),
        brightness: Brightness.light,
        textScale: 1.3);
    model.monthPageController.jumpToPage(1); // November has six calendar rows.
    await tester.pumpAndSettle();
    await capture(tester, 'month-pair-light-large-text');
    final firstCalendar = tester.getRect(find.byType(SingleMonthPage).first);
    final secondCalendar = tester.getRect(find.byType(SingleMonthPage).last);
    expect(secondCalendar.top, greaterThan(firstCalendar.bottom));
    expect(secondCalendar.bottom, lessThanOrEqualTo(700 - 104));
    expect(tester.takeException(), isNull);
    final card = find.byType(CourseCardCompact).hitTestable().first;
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(CourseDetailsBottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Month swipes restore floating navigation when paging finishes',
      (tester) async {
    size(tester, const Size(400, 860));
    final nav = ScreenNavProvider()..setCurrentPage('/class');
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: nav),
          ChangeNotifierProvider<SettingsProvider>(
              create: (_) => _EmptyCalendarSettings()),
          ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
          ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
        ],
        child: MaterialApp(
            theme: applyExpressiveTheme(ThemeData()),
            home: const WithNavigationBarView())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('切换视图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('月').last);
    await tester.pumpAndSettle();
    final pager = find.byType(PageView).hitTestable();
    final model =
        tester.element(find.byType(MonthView)).read<ClassPageProvider>();
    model.monthPageController.jumpToPage(0);
    await tester.pumpAndSettle();
    await tester.fling(pager, const Offset(0, -500), 900);
    await tester.pumpAndSettle();
    expect(model.monthPageController.page, 1);
    expect(nav.isNavBottomVisible, isTrue);
    final pill =
        tester.getRect(find.byKey(const ValueKey('floatingNavToolbar')));
    final calendars = find.byType(SingleMonthPage);
    expect(tester.getRect(calendars.last).bottom, lessThanOrEqualTo(pill.top));
    expect(tester.takeException(), isNull);
  });

  test('Paired month title handles December and January in the same page', () {
    AppGlobal.appSettings = AppSettings.fromJson({
      ...defaultAppSettingsConfig,
      'semesterStartDate': '2026-10-01',
    });
    final model = ClassPageProvider();
    model.updateMonthPage(1);
    expect(model.visibleMonthLabel, '2026年12月–2027年1月');
    model.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets('Header fades down in $brightness and does not block actions',
        (tester) async {
      size(tester, const Size(400, 860));
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
              body: CustomScrollView(slivers: [
            MiuixSliverAppBar(title: const Text('标题'), actions: [
              IconButton(
                  tooltip: '操作',
                  onPressed: () => tapped = true,
                  icon: const Icon(Icons.add)),
            ]),
            SliverList.builder(
                itemCount: 30,
                itemBuilder: (_, i) => SizedBox(
                    height: 72,
                    child: ColoredBox(
                        color: i.isEven ? Colors.blue : Colors.orange))),
          ]))));
      await tester.pumpAndSettle();
      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      final mask = tester
          .widget<DecoratedBox>(find.byKey(const ValueKey('pageTopMask')));
      final gradient =
          (mask.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.colors.first,
          brightness == Brightness.dark ? Colors.black : Colors.white);
      expect(gradient.colors.last.opacity, 0);
      expect(gradient.begin, Alignment.topCenter);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('操作'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Grade semester loading is a small ring centred in remaining body',
      (tester) async {
    size(tester, const Size(400, 860));
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ZhengFangUserProvider(),
        child: const MaterialApp(home: GradePageZF())));
    // No account or real network is used; inspect the initial waiting frame.
    final ring = find.byType(CircularProgressIndicator);
    expect(ring, findsOneWidget);
    expect(tester.getSize(ring), const Size.square(36));
    final appBar = tester.getRect(find.byType(AppBar));
    final rect = tester.getRect(ring);
    expect(rect.center.dx, 200);
    expect(rect.center.dy, closeTo((appBar.bottom + 860) / 2, 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
