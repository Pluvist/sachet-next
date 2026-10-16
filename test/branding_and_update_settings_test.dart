import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/pages/about_page.dart';
import 'package:sachet/pages/settings_child_pages/advanced_settings_page.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/theme_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';

void main() {
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson({
      ...defaultAppSettingsConfig,
      // Existing installations can still contain the old preference.
      'isAutoCheckUpdate': true,
    });
    PackageInfo.setMockInitialValues(
        appName: 'Sachet Next',
        packageName: 'com.pluvist.sachet.next.localtest',
        version: '0.10.1',
        buildNumber: '17',
        buildSignature: 'test');
  });

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
            theme: applyExpressiveTheme(ThemeData(useMaterial3: true)),
            home: page)));
    await tester.pumpAndSettle();
  }

  testWidgets('About credits distinguish current author and upstream',
      (tester) async {
    await pumpPage(tester, const AboutPage());
    expect(find.text('Sachet Next'), findsOneWidget);
    expect(find.text('Pluvist'), findsOneWidget);
    expect(find.textContaining('基于开源上游项目 Sachet 二次修改'), findsOneWidget);
    expect(find.text('wyvern1723'), findsOneWidget);
    expect(find.text('上游 Sachet 源代码'), findsOneWidget);
    expect(find.text('检查更新'), findsNothing);
    expect(find.text('最新版下载'), findsNothing);
    await tester.ensureVisible(find.text('关于应用'));
    await tester.tap(find.text('关于应用'));
    await tester.pumpAndSettle();
    expect(find.text('Sachet Next'), findsNWidgets(2));
    expect(find.textContaining('上游版权：©2025 wyvern1723'), findsOneWidget);
    expect(find.textContaining('MIT 许可证'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Advanced settings omit updates even with a legacy enabled flag',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pumpPage(tester, const AdvancedSettingsPage());
    expect(find.text('页面过渡', skipOffstage: false), findsNothing);
    expect(find.text('预测性返回', skipOffstage: false), findsNothing);
    await tester.scrollUntilVisible(find.text('删除缓存数据'), 250,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('自动检查更新', skipOffstage: false), findsNothing);
    expect(find.text('首选更新渠道', skipOffstage: false), findsNothing);
    expect(find.text('显示所有检查更新结果', skipOffstage: false), findsNothing);
    expect(find.text('在外部浏览器打开链接'), findsOneWidget);
    expect(find.text('删除缓存数据'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
