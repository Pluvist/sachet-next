import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/profile_page.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/homepage_widgets/card_widget.dart';
import 'package:sachet/widgets/utils_widgets/page_heading.dart';

void main() {
  final design =
      jsonDecode(File('assets/json/HomeDesign.json').readAsStringSync())
          as Map<String, dynamic>;

  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    AppGlobal.startupPage = '/class';
  });

  Future<void> pumpHome(WidgetTester tester, double width, double scale,
      {double pixelRatio = 1}) async {
    tester.view.physicalSize = Size(width * pixelRatio, 900 * pixelRatio);
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScreenNavProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        theme: applyExpressiveTheme(ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
        )),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: const HomePage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Miuix homepage retains course cards and all service links',
      (tester) async {
    await pumpHome(tester, 376, 1);
    final appBar = tester.getRect(find.byType(AppBar));
    final title = tester.getRect(find.byType(PageHeading));
    expect(appBar.height, (design['headingHeight'] as num).toDouble());
    expect(title.left, greaterThanOrEqualTo(20));
    expect(title.bottom, lessThanOrEqualTo(appBar.bottom));
    final titleText = tester.widget<Text>(find.descendant(
      of: find.byType(PageHeading),
      matching: find.byType(Text),
    ));
    expect(
        titleText.style!.fontSize, (design['headingSize'] as num).toDouble());
    expect(titleText.style!.fontFamily, isNot('Anthropic Serif'));
    expect(titleText.data, 'Xachet');
    final heroFinder = find.byKey(const ValueKey('homeHeroCard'));
    final status = find.byKey(const ValueKey('homeCourseStatusCard'));
    final next = find.byKey(const ValueKey('homeNextCourseCard'));
    final statusBounds = tester.getRect(status);
    final nextBounds = tester.getRect(next);
    final heroBounds = tester.getRect(heroFinder);
    expect(statusBounds.top, nextBounds.top);
    expect(statusBounds.bottom, heroBounds.bottom);
    expect(nextBounds.left, heroBounds.left);
    expect(nextBounds.right, heroBounds.right);
    expect(nextBounds.bottom, lessThan(heroBounds.top));
    expect(statusBounds.right, lessThan(nextBounds.left));
    expect(find.descendant(of: status, matching: find.byType(InkWell)),
        findsNothing);
    expect(
        tester
            .widget<InkWell>(
                find.descendant(of: heroFinder, matching: find.byType(InkWell)))
            .onTap,
        isNotNull);
    final cards = find.byType(CardWidget);
    expect(cards, findsNWidgets(9));
    for (final title in ['馆藏检索', '大物实验', '校园网认证']) {
      final card = find.ancestor(
          of: find.text(title), matching: find.byType(CardWidget));
      expect(card, findsOneWidget);
      expect(tester.widget<CardWidget>(card).link, isNotNull);
      final tap = tester.widget<InkWell>(
          find.descendant(of: card, matching: find.byType(InkWell)));
      expect(tap.onTap, isNotNull);
      expect(tap.onLongPress, isNotNull);
    }
    for (final title in ['湘大校历', '湘大新闻', '湘大邮箱']) {
      expect(
          find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
          findsOneWidget);
      expect(
          find.ancestor(
              of: find.text(title), matching: find.byType(CardWidget)),
          findsNothing);
    }
    final first = tester.getRect(cards.at(0));
    final second = tester.getRect(cards.at(1));
    expect(first.left, statusBounds.left);
    expect(second.right, heroBounds.right);
    final last = tester.getRect(cards.last);
    expect(last.left, statusBounds.left);
    expect(last.right, heroBounds.right);
    final fourth = tester.getRect(cards.at(2));
    expect(second.left - first.right, (design['gap'] as num).toDouble());
    expect(fourth.top - first.bottom, (design['gap'] as num).toDouble());
    expect(first.top, greaterThan(heroBounds.bottom));
    final colors = Theme.of(tester.element(cards.first)).colorScheme;
    expect(colors.surface, const Color(0xfff5f5f5));
    expect(colors.brightness, Brightness.light);
    expect(colors.primary, isNot(const Color(0xff8bd0ed)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home and profile share Miuix heading typography',
      (tester) async {
    await pumpHome(tester, 376, 1);
    final homeText = tester.widget<Text>(find.descendant(
        of: find.byType(PageHeading), matching: find.byType(Text)));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScreenNavProvider()),
        ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
      ],
      child: MaterialApp(
        theme: applyExpressiveTheme(ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
        )),
        home: const ProfilePage(),
      ),
    ));
    await tester.pumpAndSettle();
    final profileBounds = tester.getRect(find.byType(PageHeading));
    final profileBar = tester.getRect(find.byType(AppBar));
    final profileText = tester.widget<Text>(find.descendant(
        of: find.byType(PageHeading), matching: find.byType(Text)));
    expect(profileBounds.left, greaterThanOrEqualTo(20));
    expect(profileBounds.bottom, lessThanOrEqualTo(profileBar.bottom));
    expect(profileBar.height, (design['headingHeight'] as num).toDouble());
    expect(profileText.data, '我');
    expect(profileText.style!.fontSize, homeText.style!.fontSize);
    expect(profileText.style!.fontFamily, homeText.style!.fontFamily);
    expect(profileText.style!.fontFamilyFallback,
        homeText.style!.fontFamilyFallback);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1216 / 3.5, 360.0]) {
    testWidgets('Phone shortcuts retain two columns at logical width $width',
        (tester) async {
      await pumpHome(tester, width, 1, pixelRatio: 3.5);
      final cards = find.byType(CardWidget);
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      final third = tester.getRect(cards.at(2));
      expect(first.top, second.top);
      expect(first.width, closeTo(second.width, 0.01));
      expect(second.left, greaterThan(first.right));
      expect(third.top, greaterThan(first.bottom));
      expect(cards, findsNWidgets(9));
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Narrow large-text homepage remains scrollable without overflow',
      (tester) async {
    await pumpHome(tester, 320, 2);
    final cards = find.byType(CardWidget);
    final first = tester.getRect(cards.at(0));
    final second = tester.getRect(cards.at(1));
    expect(second.left, first.left);
    expect(second.top, greaterThan(first.bottom));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('旧教务系统'));
    await tester.pumpAndSettle();
    expect(find.text('旧教务系统').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
