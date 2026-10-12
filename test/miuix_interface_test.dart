import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/course_card_settings.dart';
import 'package:sachet/models/nav_destination.dart';
import 'package:sachet/pages/about_page.dart';
import 'package:sachet/pages/home_page.dart';
import 'package:sachet/pages/profile_page.dart';
import 'package:sachet/pages/settings_page.dart';
import 'package:sachet/pages/settings_child_pages/advanced_settings_page.dart';
import 'package:sachet/pages/settings_child_pages/customize_settings_page.dart';
import 'package:sachet/pages/settings_child_pages/theme_settings_page.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_login_page.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/theme_provider.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/utils_widgets/miuix_components.dart';
import 'package:sachet/widgets/utils_widgets/nav_bottom.dart';

void main() {
  final pages = <String, Widget>{
    'home': const HomePage(),
    'settings': const SettingsPage(),
    'profile': const ProfilePage(openedFromHome: true),
    'about': const AboutPage(),
    'advanced': const AdvancedSettingsPage(),
    'appearance': const CustomizeSettingsPage(),
    'theme': const ThemeSettingsPage(),
    'login': const ZhengFangJwxtLoginPage(),
  };
  final previewDir = Platform.environment['SACHET_VISUAL_QA_DIR'];
  final fontFile = Platform.environment['SACHET_UI_FONT'];
  setUpAll(() async {
    if (previewDir == null || fontFile == null) return;
    final font = FontLoader('PreviewFont')
      ..addFont(Future.value(
          ByteData.sublistView(await File(fontFile).readAsBytes())));
    await font.load();
    final fallback = FontLoader('Roboto')
      ..addFont(Future.value(
          ByteData.sublistView(await File(fontFile).readAsBytes())));
    await fallback.load();
    final iconFile = Platform.environment['SACHET_ICON_FONT'];
    if (iconFile != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(
            ByteData.sublistView(await File(iconFile).readAsBytes())));
      await icons.load();
    }
  });
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    AppGlobal.courseCardSettings = CourseCardSettings();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => null);
    AppGlobal.startupPage = '/class';
    PackageInfo.setMockInitialValues(
        appName: 'Sachet Next',
        packageName: 'io.github.wyvern1723.sachet.localtest',
        version: '0.10.1-next.2',
        buildNumber: '19',
        buildSignature: 'test');
  });
  Future<void> pumpPage(WidgetTester tester, Widget page, Brightness brightness,
      double scale) async {
    tester.view.physicalSize = const Size(376, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => CourseCardSettingsProvider()),
          ChangeNotifierProvider(create: (_) => ScreenNavProvider()),
          ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
        ],
        child: MaterialApp(
            theme: applyExpressiveTheme(ThemeData(
                useMaterial3: true,
                fontFamily: previewDir != null && fontFile != null
                    ? 'PreviewFont'
                    : null,
                colorSchemeSeed: Colors.blue,
                brightness: brightness)),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                    key: const ValueKey('uiPreview'), child: child!)),
            home: previewDir != null && page is HomePage
                ? Scaffold(
                    extendBody: true,
                    body: page,
                    bottomNavigationBar: const NavBottom(
                        routeNames: ['/home', '/class'],
                        currentPageIndex: 0,
                        destinations: [
                          NavDestination(
                              label: '主页',
                              icon: Icon(Icons.apps_outlined),
                              selectedIcon: Icon(Icons.apps_outlined),
                              page: SizedBox(),
                              routeName: '/home'),
                          NavDestination(
                              label: '课程表',
                              icon: Icon(Icons.calendar_month_outlined),
                              selectedIcon: Icon(Icons.calendar_month_outlined),
                              page: SizedBox(),
                              routeName: '/class'),
                        ]))
                : page)));
    await tester.pumpAndSettle();
  }

  for (final entry in pages.entries) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
            '${entry.key} $brightness scale $scale retains a usable layout',
            (tester) async {
          await pumpPage(tester, entry.value, brightness, scale);
          expect(tester.takeException(), isNull);
          if (entry.key != 'home') {
            expect(find.byType(MiuixAppBar), findsOneWidget);
          }
          final colors =
              Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme;
          expect(colors.surface.computeLuminance(),
              brightness == Brightness.dark ? lessThan(.01) : greaterThan(.8));
          if (previewDir != null && scale == 1) {
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('uiPreview')));
              final image = await boundary.toImage(pixelRatio: 2);
              final data =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              await Directory(previewDir).create(recursive: true);
              await File('$previewDir/${entry.key}-${brightness.name}.png')
                  .writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        });
      }
    }
  }
  testWidgets(
      'Settings search opens the matching page and preserves back navigation',
      (tester) async {
    await pumpPage(tester, const SettingsPage(), Brightness.dark, 1);
    await tester.enterText(
        find.byKey(const ValueKey('miuixSettingsSearch')), '课表外观');
    await tester.pumpAndSettle();
    expect(find.text('应用主题'), findsNothing);
    final match = find.widgetWithText(MiuixListTile, '课表外观');
    expect(match, findsOneWidget);
    await tester.tap(match);
    await tester.pumpAndSettle();
    expect(find.byType(CustomizeSettingsPage), findsOneWidget);
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
