import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/classpage_widgets/week_count_dropdown_menu.dart';
import 'package:sachet/widgets/utils_widgets/liquid_dropdown_menu.dart';
import 'package:sachet/widgets/utils_widgets/nav_bottom.dart';
import 'package:sachet/widgets/utils_widgets/nexio_bottom_tabs.dart';

/// NexioSchedule parity: `LiquidBottomTabs` uses a 56dp bar occupying 63% of
/// the width, 4dp padding and a 48dp selector; `LiquidGlassDropdownMenu` morphs
/// a 42dp glass button into a 200dp wide panel below it.
void main() {
  testWidgets('Drag commits once and pointer cancellation restores selection',
      (tester) async {
    var selected = 0;
    var commits = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: StatefulBuilder(
      builder: (context, setState) => SizedBox(
          width: 200,
          child: NexioBottomTabs(
            selected: selected,
            children: const [Text('主页'), Text('课程表')],
            onSelected: (value) => setState(() {
              selected = value;
              commits++;
            }),
          )),
    )))));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(NexioBottomTabs));
    await tester.dragFrom(
        Offset(rect.left + 30, rect.center.dy), const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(commits, 1);
    final gesture =
        await tester.startGesture(Offset(rect.right - 30, rect.center.dy));
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(commits, 1);
    expect(tester.takeException(), isNull);
  });
  setUp(() =>
      AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig));

  Widget wrapper(Widget child, {Size size = const Size(412, 892)}) {
    return MaterialApp(
      theme: applyExpressiveTheme(
          ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true)),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('Bottom bar keeps the NexioSchedule geometry', (tester) async {
    const size = Size(412, 892);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const routes = ['/home', '/class'];
    const labels = ['home-tab', 'class-tab'];
    final destinations = List.generate(
        2,
        (index) => NavDestination(
              label: labels[index],
              icon: const Icon(Icons.circle_outlined),
              selectedIcon: const Icon(Icons.circle),
              page: const SizedBox(),
              routeName: routes[index],
            ));
    final navigation = ScreenNavProvider()..setCurrentPage('/home');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: navigation,
      child: MaterialApp(
        theme: applyExpressiveTheme(
            ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true)),
        home: MediaQuery(
          data: const MediaQueryData(size: size),
          child: Scaffold(
            bottomNavigationBar: Consumer<ScreenNavProvider>(
              builder: (_, provider, __) => NavBottom(
                destinations: destinations,
                routeNames: routes,
                currentPageIndex: routes.indexOf(ScreenNavProvider.currentPage),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final bar =
        tester.getRect(find.byKey(const ValueKey('floatingNavToolbar')));
    expect(bar.height, kNavBottomHeight);
    expect(bar.width, closeTo(size.width * kNavBottomWidthFactor, .5));
    expect(bar.center.dx, closeTo(size.width / 2, .5));

    final selector =
        tester.getRect(find.byKey(const ValueKey('liquidNavSelection')));
    expect(selector.height, kNavBottomSelectorHeight);
    // One tab of the padded row.
    expect(selector.width, closeTo(bar.width / 2 - kNavBottomPadding, .5));
    expect(selector.left, closeTo(bar.left + kNavBottomPadding - .5, .5));

    // Selecting the other tab moves the capsule by exactly one tab width.
    navigation.setCurrentPage('/class');
    await tester.pumpAndSettle();
    final moved =
        tester.getRect(find.byKey(const ValueKey('liquidNavSelection')));
    expect(moved.left - selector.left, closeTo(selector.width, .5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dropdown grows from the app bar button into a panel',
      (tester) async {
    var expanded = 0;
    int? selected;
    var show = false;
    const entries = ['entry-a', 'entry-b', 'entry-c', 'entry-d'];
    // The panel anchors below the trigger, mirroring the app bar geometry the
    // caller normally gets from MediaQuery.
    const panelTop = 200.0;
    const panelRight = 0.0;
    await tester.pumpWidget(wrapper(
      StatefulBuilder(builder: (context, setState) {
        return SizedBox(
          height: 200,
          child: Align(
            alignment: Alignment.topRight,
            child: LiquidGlassDropdownMenu(
              show: show,
              itemCount: 4,
              entryLabels: entries,
              tooltip: 'more-actions',
              panelTop: panelTop,
              panelRight: panelRight,
              onExpanded: () => setState(() {
                expanded++;
                show = true;
              }),
              onDismissed: () => setState(() => show = false),
              onSelected: (index) => selected = index,
            ),
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();

    // Collapsed: only the 42dp trigger is on screen, no entries yet.
    final trigger =
        tester.getRect(find.byKey(const ValueKey('liquidDropdownTrigger')));
    expect(trigger.width, kLiquidDropdownButtonDiameter);
    expect(trigger.height, kLiquidDropdownButtonDiameter);
    expect(find.text('entry-d'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('liquidDropdownTrigger')));
    await tester.pumpAndSettle();
    expect(expanded, 1);

    // Open: every entry is laid out once, in a 200dp wide panel.
    for (final label in entries) {
      expect(find.text(label), findsOneWidget);
    }
    final item0 =
        tester.getRect(find.byKey(const ValueKey('liquidDropdownItem0')));
    expect(item0.width, closeTo(kLiquidDropdownPanelWidth - 16, 1));
    // The panel emerges at the button: its reserved shadow margin tucks under
    // the app bar row, so the first entry starts right at the button's edge.
    expect(item0.top - trigger.bottom, inInclusiveRange(-42, 8));
    // The glass lines up with the button's action, near the viewport edge and
    // fully inside it.
    final scaffoldRight = tester.getRect(find.byType(Scaffold)).right;
    expect(scaffoldRight - item0.right, inInclusiveRange(0, 20));
    expect(
        tester
            .getRect(find.byKey(const ValueKey('liquidDropdownItem3')))
            .height,
        kLiquidDropdownEntryHeight);

    await tester.tap(find.byKey(const ValueKey('liquidDropdownItem2')));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(show, isFalse,
        reason: 'the reference dismisses the panel before invoking its action');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping outside the open panel dismisses it', (tester) async {
    var show = true;
    await tester.pumpWidget(wrapper(SizedBox(
      height: 200,
      child: StatefulBuilder(builder: (context, setState) {
        return Align(
          alignment: Alignment.topRight,
          child: LiquidGlassDropdownMenu(
            show: show,
            itemCount: 2,
            entryLabels: const ['entry-a', 'entry-b'],
            tooltip: 'more-actions',
            onDismissed: () => setState(() => show = false),
            onSelected: (_) {},
          ),
        );
      }),
    )));
    await tester.pumpAndSettle();
    expect(find.text('entry-a'), findsOneWidget);

    // Tapping the page, away from the panel and its trigger, closes the menu.
    await tester.tapAt(const Offset(20, 500));
    await tester.pumpAndSettle();
    expect(show, isFalse);
    expect(find.text('entry-a'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Week selector opens the panel and pages to the week',
      (tester) async {
    final courses = ClassPageProvider();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: courses),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: wrapper(Column(children: [
        SizedBox(
          height: 60,
          child: Align(
            alignment: Alignment.topRight,
            child: WeekCountDropdownMenu(),
          ),
        ),
        // The selector drives the week pager, so the test needs one attached.
        Expanded(
          child: PageView.builder(
            controller: courses.pageController,
            itemCount: 20,
            onPageChanged: (page) => courses.updateCurrentWeekCount(page + 1),
            itemBuilder: (_, index) => SizedBox.expand(),
          ),
        ),
      ])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('第 1 周'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('liquidDropdownTrigger')));
    await tester.pumpAndSettle();
    expect(find.text('第 1 周'), findsOneWidget);
    expect(find.text('第 20 周'), findsOneWidget);

    // Entry 2 is the third week.
    await tester.tap(find.byKey(const ValueKey('liquidDropdownItem2')));
    await tester.pumpAndSettle();
    expect(courses.currentWeekCount, 3);
    expect(tester.takeException(), isNull);
  });
}
