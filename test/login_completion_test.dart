import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/user.dart';
import 'package:sachet/pages/utilspages/zhengfang_jwxt_login_page.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/login/account_authenticator.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/widgets/intro_widgets/provision_page.dart';

class _Authenticator extends AccountAuthenticator {
  final pending = Completer<User>();
  int calls = 0;
  @override
  Future<User> passwordLogin(String username, String password) {
    expect(username, '202600000001');
    expect(password, 'test-only-password');
    calls++;
    return pending.future;
  }

  @override
  Future<User> cookieLogin(String cookie) {
    expect(cookie, 'JSESSIONID=test-cookie');
    calls++;
    return pending.future;
  }
}

void main() {
  final stored = <String, String?>{};
  setUp(() {
    stored.clear();
    AppGlobal.appSettings = AppSettings.fromJson(defaultAppSettingsConfig);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (call) async {
      final args = call.arguments as Map;
      final key = args['key'] as String?;
      if (call.method == 'write') stored[key!] = args['value'] as String?;
      if (call.method == 'delete') stored.remove(key);
      if (call.method == 'read') return stored[key];
      return null;
    });
  });
  Future<void> open(
      WidgetTester tester, _Authenticator auth, VoidCallback complete) async {
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ZhengFangUserProvider(),
        child: MaterialApp(
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                  builder: (_) => ZhengFangJwxtLoginPage(
                                      onboarding: true, authenticator: auth)));
                          if (result == true) complete();
                        },
                        child: const Text('Caller')))))));
    await tester.tap(find.text('Caller'));
    await tester.pumpAndSettle();
  }

  for (final cookie in [false, true]) {
    testWidgets(
        'Saves session and returns true without progress/success prompts, cookie=$cookie',
        (tester) async {
      final auth = _Authenticator();
      var returned = false;
      await open(tester, auth, () {
        expect(
            stored['cookieZF'], cookie ? 'cookie-session' : 'password-session');
        if (!cookie) expect(stored['passwordZF'], 'test-only-password');
        returned = true;
      });
      if (cookie) {
        await tester
            .ensureVisible(find.byKey(const ValueKey('otherLoginMethods')));
        await tester.tap(find.byKey(const ValueKey('otherLoginMethods')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('使用 Cookie 登录'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.descendant(
                of: find.byType(AlertDialog), matching: find.byType(TextField)),
            ' JSESSIONID=test-cookie ');
        await tester.tap(find.text('确认'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      } else {
        await tester.enterText(
            find.byKey(const ValueKey('loginUsernameField')), '202600000001');
        await tester.enterText(find.byKey(const ValueKey('loginPasswordField')),
            'test-only-password');
        await tester.tap(find.byKey(const ValueKey('provisionLogin')));
        await tester.pump();
      }
      expect(auth.calls, 1);
      expect(returned, false);
      expect(find.textContaining('正在登录'), findsNothing);
      expect(find.textContaining('登录成功'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(
          tester
              .widget<ProvisionButton>(
                  find.byKey(const ValueKey('provisionLogin')))
              .onPressed,
          isNull);
      auth.pending.complete(User(
          cookie: cookie ? 'cookie-session' : 'password-session',
          name: '测试',
          studentID: '202600000001'));
      await tester.pumpAndSettle();
      expect(returned, true);
      expect(find.text('Caller'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Failed login stays on form and re-enables retry',
      (tester) async {
    final auth = _Authenticator();
    var returned = false;
    await open(tester, auth, () => returned = true);
    await tester.enterText(
        find.byKey(const ValueKey('loginUsernameField')), '202600000001');
    await tester.enterText(
        find.byKey(const ValueKey('loginPasswordField')), 'test-only-password');
    await tester.tap(find.byKey(const ValueKey('provisionLogin')));
    await tester.pump();
    auth.pending.completeError(Exception('测试网络失败'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('测试网络失败'), findsOneWidget);
    expect(returned, false);
    expect(
        tester
            .widget<ProvisionButton>(
                find.byKey(const ValueKey('provisionLogin')))
            .onPressed,
        isNotNull);
    expect(stored.containsKey('cookieZF'), false);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
