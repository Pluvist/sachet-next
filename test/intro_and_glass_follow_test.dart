import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/pages/intro_screen/intro_screen.dart';
import 'package:sachet/pages/intro_screen/agreement_page.dart';
import 'package:sachet/widgets/intro_widgets/provision_page.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_login_page.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/utils_widgets/nexio_bottom_tabs.dart';

class _Settings extends SettingsProvider {
  int completed = 0;
  @override
  void setStartupPage(String page) {
    AppGlobal.appSettings.startupPage = page;
  }

  @override
  void setHasReadDisclaimer() {
    completed++;
    AppGlobal.appSettings.hasReadDisclaimer = true;
  }
}

class _Account extends ZhengFangUserProvider {
  bool logged = false;
  @override
  bool get isLogin => logged;
}

void main() {
  testWidgets('Original glow program loads with all fifty uniform values',
      (tester) async {
    await tester.runAsync(() async {
      final program = await ui.FragmentProgram.fromAsset(
          'assets/shaders/hyperceiler_glow.frag');
      final shader = program.fragmentShader();
      for (var i = 0; i < 50; i++) {
        shader.setFloat(i, 0);
      }
      shader.dispose();
    });
  });
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    AppGlobal.homeEntrancePending = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => null);
  });
  Future<_Settings> intro(
      WidgetTester tester, Brightness brightness, double scale) async {
    final settings = _Settings();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScreenNavProvider()),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ZhengFangUserProvider>(
              create: (_) => _Account()),
        ],
        child: MaterialApp(
            theme: applyExpressiveTheme(ThemeData(brightness: brightness)),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: child!),
            routes: {'/navBarView': (_) => const Scaffold(body: Text('主界面'))},
            home: const IntroScreen())));
    await tester.pumpAndSettle();
    return settings;
  }

  Future<void> agreeAndContinue(WidgetTester tester) async {
    expect(find.byType(AgreementPage), findsOneWidget);
    final button = find.byKey(const ValueKey('agreementContinue'));
    expect(tester.widget<ProvisionButton>(button).onPressed, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('agreementConsent')));
    await tester.tap(find.byKey(const ValueKey('agreementConsent')));
    await tester.pumpAndSettle();
    expect(tester.widget<ProvisionButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'Agreement and account onboarding precede completion $brightness $scale',
          (tester) async {
        final settings = await intro(tester, brightness, scale);
        expect(find.text('Sachet Next'), findsOneWidget);
        expect(find.text('登录账号'), findsNothing);
        expect(find.text('主题颜色'), findsNothing);
        expect(find.byType(PageView), findsNothing);
        expect(settings.completed, 0);
        await tester.ensureVisible(find.byKey(const ValueKey('introNext')));
        await tester.tap(find.byKey(const ValueKey('introNext')));
        await tester.pumpAndSettle();
        await agreeAndContinue(tester);
        expect(find.byType(ZhengFangJwxtLoginPage), findsOneWidget);
        expect(settings.completed, 0);
        Navigator.of(tester.element(find.byType(ZhengFangJwxtLoginPage)))
            .pop(true);
        await tester.pumpAndSettle();
        expect(find.text('设置完成'), findsOneWidget);
        expect(settings.completed, 0);
        await tester.ensureVisible(find.byKey(const ValueKey('introFinish')));
        await tester.tap(find.byKey(const ValueKey('introFinish')));
        await tester.pumpAndSettle();
        expect(find.text('主界面'), findsOneWidget);
        expect(settings.completed, 1);
        expect(AppGlobal.startupPage, '/home');
        expect(ScreenNavProvider.currentPage, '/home');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Aborting account login keeps onboarding incomplete',
      (tester) async {
    final settings = await intro(tester, Brightness.light, 1);
    await tester.ensureVisible(find.byKey(const ValueKey('introNext')));
    await tester.tap(find.byKey(const ValueKey('introNext')));
    await tester.pumpAndSettle();
    await agreeAndContinue(tester);
    expect(find.byType(ZhengFangJwxtLoginPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(AgreementPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(IntroScreen), findsOneWidget);
    expect(settings.completed, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Existing login cannot bypass the consent page by backing out',
      (tester) async {
    final settings = await intro(tester, Brightness.dark, 1);
    final account = tester
        .element(find.byType(IntroScreen))
        .read<ZhengFangUserProvider>() as _Account;
    account.logged = true;
    await tester.ensureVisible(find.byKey(const ValueKey('introNext')));
    await tester.tap(find.byKey(const ValueKey('introNext')));
    await tester.pumpAndSettle();
    expect(find.byType(AgreementPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('introFinish')), findsNothing);
    expect(settings.completed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip account login still visits completion before entering home',
      (tester) async {
    final settings = await intro(tester, Brightness.light, 1);
    await tester.ensureVisible(find.byKey(const ValueKey('introNext')));
    await tester.tap(find.byKey(const ValueKey('introNext')));
    await tester.pumpAndSettle();
    await agreeAndContinue(tester);
    await tester.tap(find.byKey(const ValueKey('onboardLoginSkip')));
    await tester.pumpAndSettle();
    expect(find.text('设置完成'), findsOneWidget);
    expect(settings.completed, 0);
    expect(find.text('主界面'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('introFinish')));
    await tester.tap(find.byKey(const ValueKey('introFinish')));
    await tester.pumpAndSettle();
    expect(settings.completed, 1);
    expect(AppGlobal.startupPage, '/home');
    expect(ScreenNavProvider.currentPage, '/home');
    expect(find.text('主界面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Dragging follows the finger in one frame without rebuilding fixed glass',
      (tester) async {
    int commits = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 200,
                    child: NexioBottomTabs(
                        selected: 0,
                        onSelected: (_) => commits++,
                        children: const [Text('主页'), Text('课程表')]))))));
    await tester.pumpAndSettle();
    final fixed =
        tester.widget(find.byKey(const ValueKey('nexioFixedBackdrop')));
    final labels =
        tester.widget(find.byKey(const ValueKey('nexioFixedLabels')));
    final start =
        tester.getRect(find.byKey(const ValueKey('liquidNavSelection')));
    final gesture = await tester.startGesture(start.center);
    await gesture.moveBy(const Offset(48, 0));
    await tester.pump();
    final moved =
        tester.getRect(find.byKey(const ValueKey('liquidNavSelection')));
    expect(moved.left - start.left, closeTo(48, .01));
    expect(
        identical(fixed,
            tester.widget(find.byKey(const ValueKey('nexioFixedBackdrop')))),
        isTrue);
    expect(
        identical(labels,
            tester.widget(find.byKey(const ValueKey('nexioFixedLabels')))),
        isTrue);
    expect(commits, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(commits, 1);
    expect(tester.takeException(), isNull);
  });
}
