import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/pages/intro_screen/agreement_page.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_login_page.dart';
import 'package:sachet/providers/login_page_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/expressive_theme.dart';
import 'package:sachet/widgets/intro_widgets/provision_page.dart';

void main() {
  setUp(() {
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => null);
  });
  Future<void> pump(WidgetTester tester, Widget page,
      {double scale = 1}) async {
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ZhengFangUserProvider()),
        ],
        child: MaterialApp(
            theme: applyExpressiveTheme(ThemeData()),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: page)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Local notices can be read without accepting or completing onboarding',
      (tester) async {
    await pump(tester, const AgreementPage());
    expect(
        tester
            .widget<ProvisionButton>(
                find.byKey(const ValueKey('agreementContinue')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const ValueKey('usageNoticeLink')));
    await tester.pumpAndSettle();
    expect(find.byType(NoticeDetailsPage), findsOneWidget);
    expect(find.text('使用协议'), findsOneWidget);
    expect(AppGlobal.appSettings.hasReadDisclaimer, isNot(true));
    await tester.tap(find.text('阅读完毕'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ProvisionCheck>(
                find.byKey(const ValueKey('agreementConsent')))
            .value,
        false);
    await tester.tap(find.byKey(const ValueKey('agreementConsent')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('privacyNoticeLink')));
    await tester.pumpAndSettle();
    expect(find.text('隐私说明'), findsOneWidget);
    await tester.tap(find.text('阅读完毕'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ProvisionCheck>(
                find.byKey(const ValueKey('agreementConsent')))
            .value,
        true);
    expect(AppGlobal.appSettings.hasReadDisclaimer, isNot(true));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Redesigned login validates locally, retains visibility, remember and alternate methods',
      (tester) async {
    await pump(tester, const ZhengFangJwxtLoginPage(onboarding: true));
    final passwordField = tester.widget<TextField>(find.descendant(
        of: find.byKey(const ValueKey('loginPasswordField')),
        matching: find.byType(TextField)));
    expect(passwordField.decoration?.hintText, '默认密码为 Xtu@身份证后六位');
    expect(
        tester
            .element(find.byType(ZhengFangJwxtLoginPageView))
            .read<LoginPageProvider>()
            .isRememberPassword,
        isTrue);
    await tester.tap(find.byKey(const ValueKey('provisionLogin')));
    await tester.pumpAndSettle();
    expect(find.text('请填入您的学号'), findsOneWidget);
    expect(find.text('请填入您的密码'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('loginUsernameField')), '123');
    await tester.enterText(
        find.byKey(const ValueKey('loginPasswordField')), 'fake-test-password');
    await tester.tap(find.byKey(const ValueKey('provisionLogin')));
    await tester.pumpAndSettle();
    expect(find.text('学号不是12位'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('显示密码'));
    await tester.tap(find.byTooltip('显示密码'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('隐藏密码'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('loginRemember')));
    await tester.tap(find.byKey(const ValueKey('loginRemember')));
    await tester.pumpAndSettle();
    expect(
        tester
            .element(find.byType(ZhengFangJwxtLoginPageView))
            .read<LoginPageProvider>()
            .isRememberPassword,
        false);
    await tester.ensureVisible(find.byKey(const ValueKey('otherLoginMethods')));
    await tester.tap(find.byKey(const ValueKey('otherLoginMethods')));
    await tester.pumpAndSettle();
    for (final label in ['手动登录', '从信息门户登录', '使用 Cookie 登录']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Login action stays above keyboard with large text on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await pump(tester, const ZhengFangJwxtLoginPage(onboarding: true),
        scale: 2);
    await tester
        .ensureVisible(find.byKey(const ValueKey('loginPasswordField')));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('provisionLogin'))).bottom,
        lessThanOrEqualTo(450));
    expect(find.byKey(const ValueKey('onboardLoginSkip')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
