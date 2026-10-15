import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/classpage_widgets/classpage_appbar.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/utils_widgets/miuix_select.dart';

void main() {
  setUp(() =>
      AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig));
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Header and date tabs do not overlap $brightness $scale',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
            theme: applyExpressiveTheme(ThemeData(brightness: brightness)),
            home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: DefaultTabController(
                    length: 3,
                    child: Scaffold(
                        appBar: const MiuixAppBar(
                            title: Text('空闲教室'),
                            bottom: TabBar(isScrollable: true, tabs: [
                              Tab(text: '今日'),
                              Tab(text: '明日'),
                              Tab(text: '自选日期')
                            ])),
                        body: const SizedBox())))));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.text('空闲教室')).bottom,
            lessThan(tester.getRect(find.byType(TabBar)).top));
        expect(tester.takeException(), isNull);
      });
      testWidgets('Twenty-week heading and view menu fit $brightness $scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final course = ClassPageProvider()..updateCurrentWeekCount(20);
        await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider.value(value: course),
            ],
            child: MaterialApp(
                theme: applyExpressiveTheme(ThemeData(brightness: brightness)),
                home: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                        appBar: ClassPageAppBar(), body: const SizedBox())))));
        await tester.pumpAndSettle();
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text('第 20 周'));
        expect(paragraph.didExceedMaxLines, isFalse);
        await tester.tap(find.byTooltip('切换视图'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('月'));
        await tester.pumpAndSettle();
        expect(course.currentViewMode, ClassScheduleViewMode.month);
        expect(tester.takeException(), isNull);
      });
      testWidgets(
          'Selector preserves values and retry action $brightness $scale',
          (tester) async {
        String? value;
        int retries = 0;
        await tester.pumpWidget(MaterialApp(
            theme: applyExpressiveTheme(ThemeData(brightness: brightness)),
            home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                    body: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          MiuixSelect<String>(
                              label: const Text('学年'),
                              initialSelection: '2026',
                              dropdownMenuEntries: const [
                                DropdownMenuEntry(
                                    value: '2026', label: '2026–2027'),
                                DropdownMenuEntry(
                                    value: '2025', label: '2025–2026')
                              ],
                              onSelected: (selected) => value = selected),
                          MiuixButton.icon(
                              onPressed: () => retries++,
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试')),
                        ]))))));
        await tester.pumpAndSettle();
        expect(find.byType(DropdownMenu<String>), findsNothing);
        await tester.tap(find.text('2026–2027'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2025–2026'));
        await tester.pumpAndSettle();
        expect(value, '2025');
        await tester.tap(find.text('重试'));
        expect(retries, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
