import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/models/app_settings.dart';
import 'package:sachet/models/user.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/auto_login_retry.dart';
import 'package:sachet/utils/app_global.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final stored = <String, String?>{};
  Future<void> Function(String key)? beforeRead;
  Future<void> Function(String key, String? value)? beforeWrite;
  Future<void> Function(String key)? beforeDelete;

  User account(String id, [String? cookie]) =>
      User(name: 'Test $id', studentID: id, cookie: cookie ?? 'session-$id');
  ZhengFangUserProvider provider() {
    final user = ZhengFangUserProvider();
    addTearDown(user.dispose);
    return user;
  }

  void seedLegacy(String id) {
    stored.addAll({
      'nameZF': 'Test $id',
      'studentIDZF': id,
      'cookieZF': 'session-$id',
      'passwordZF': 'test-password-$id',
    });
  }

  setUp(() async {
    beforeRead = null;
    beforeWrite = null;
    beforeDelete = null;
    stored.clear();
    AppGlobal.appSettings = AppSettings.fromJson({
      ...defaultAppSettingsConfig,
      'isDeleteQZJwxtUserInfo': true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map;
      final key = args['key'] as String;
      switch (call.method) {
        case 'read':
          final snapshot = stored[key];
          await beforeRead?.call(key);
          return snapshot;
        case 'write':
          final value = args['value'] as String?;
          await beforeWrite?.call(key, value);
          stored[key] = value;
          return null;
        case 'delete':
          await beforeDelete?.call(key);
          stored.remove(key);
          return null;
      }
      return null;
    });
    final reset = ZhengFangUserProvider();
    await reset.deleteUser();
    reset.dispose();
    stored.clear();
  });

  test('Cold start migrates legacy identity and remembered password together',
      () async {
    seedLegacy('a');
    final user = provider();
    await user.init();
    expect(user.isInitialized, true);
    expect(user.isLogin, true);
    expect(user.user.studentID, 'a');
    expect(ZhengFangUserProvider.cookie, 'session-a');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-a');
    final snapshot = jsonDecode(stored['sessionZF']!) as Map;
    expect(snapshot['studentID'], 'a');
    expect(snapshot['cookie'], 'session-a');
    expect(snapshot['password'], 'test-password-a');
  });

  test('Saved credentials remain recoverable if a legacy Cookie is missing',
      () async {
    seedLegacy('a');
    stored.remove('cookieZF');
    final user = provider();
    await user.init();
    expect(user.isLogin, true);
    expect(user.user.studentID, 'a');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-a');
  });

  test('Temporary secure-storage read failure permits a later restoration',
      () async {
    seedLegacy('a');
    var fail = true;
    beforeRead = (key) async {
      if (key == 'sessionZF' && fail) {
        fail = false;
        throw PlatformException(code: 'test-storage-unavailable');
      }
    };
    final user = provider();
    await expectLater(user.init(), throwsA(isA<PlatformException>()));
    await user.init();
    expect(user.user.studentID, 'a');
    expect(user.isInitialized, true);
  });

  test('Late restoration cannot overwrite a newer explicit login', () async {
    seedLegacy('a');
    final started = Completer<void>();
    final release = Completer<void>();
    beforeRead = (key) async {
      if (key == 'cookieZF') {
        started.complete();
        await release.future;
      }
    };
    final user = provider();
    final restoring = user.init();
    await started.future;
    final login = user.setUser(account('b'),
        password: 'test-password-b', rememberPassword: true);
    beforeRead = null;
    release.complete();
    await Future.wait([restoring, login]);
    expect(user.user.studentID, 'b');
    expect(ZhengFangUserProvider.cookie, 'session-b');
    final restarted = provider();
    await restarted.init();
    expect(restarted.user.studentID, 'b');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-b');
  });

  test('A slow logout cannot erase a subsequent login', () async {
    final user = provider();
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    final started = Completer<void>();
    final release = Completer<void>();
    beforeWrite = (key, value) async {
      if (key == 'sessionZF' && (jsonDecode(value!) as Map)['cookie'] == null) {
        started.complete();
        await release.future;
      }
    };
    final logout = user.deleteUser();
    await started.future;
    final login = user.setUser(account('b'),
        password: 'test-password-b', rememberPassword: true);
    beforeWrite = null;
    release.complete();
    await Future.wait([logout, login]);
    final restarted = provider();
    await restarted.init();
    expect(restarted.user.studentID, 'b');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-b');
  });

  test('Same Cookie still persists a changed identity and password', () async {
    final user = provider();
    await user.setUser(account('a', 'unchanged'),
        password: 'test-password-a', rememberPassword: true);
    await user.setUser(account('b', 'unchanged'),
        password: 'test-password-b', rememberPassword: true);
    final restarted = provider();
    await restarted.init();
    expect(restarted.user.studentID, 'b');
    expect(stored['studentIDZF'], 'b');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-b');
  });

  test('Remembering the same password again writes it after deletion',
      () async {
    final user = provider();
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    await ZhengFangUserProvider.deletePassword();
    expect(await ZhengFangUserProvider.readPassword(), isNull);
    await ZhengFangUserProvider.savePassword('test-password-a');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-a');
    expect(stored['passwordZF'], 'test-password-a');
  });

  test('Listeners see a remembered password only after the whole login commits',
      () async {
    final user = provider();
    var notifications = 0;
    user.addListener(() {
      notifications++;
      expect((jsonDecode(stored['sessionZF']!) as Map)['password'],
          'test-password-a');
    });
    final started = Completer<void>();
    final release = Completer<void>();
    beforeWrite = (key, value) async {
      if (key == 'sessionZF' && (jsonDecode(value!) as Map)['cookie'] != null) {
        started.complete();
        await release.future;
      }
    };
    final login = user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    await started.future;
    expect(notifications, 0);
    release.complete();
    await login;
    expect(notifications, 1);
  });

  test('Failed account save restores the previous coherent snapshot on restart',
      () async {
    final user = provider();
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    beforeWrite = (key, value) async {
      if (key == 'sessionZF' &&
          (jsonDecode(value!) as Map)['studentID'] == 'b') {
        throw PlatformException(code: 'test-write-failure');
      }
    };
    await expectLater(
        user.setUser(account('b'),
            password: 'test-password-b', rememberPassword: true),
        throwsA(isA<PlatformException>()));
    expect(user.user.studentID, 'a');
    expect(stored['cookieZF'], 'session-b'); // Interrupted legacy mirror.
    beforeWrite = null;
    final restarted = provider();
    await restarted.init();
    expect(restarted.user.studentID, 'a');
    expect(ZhengFangUserProvider.cookie, 'session-a');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-a');
  });

  test('Logout tombstone prevents leftover legacy fields from signing back in',
      () async {
    final user = provider();
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    beforeDelete =
        (_) async => throw PlatformException(code: 'test-cleanup-failure');
    await expectLater(user.deleteUser(), throwsA(isA<PlatformException>()));
    expect(stored['cookieZF'], 'session-a');
    beforeDelete = null;
    final restarted = provider();
    await restarted.init();
    expect(restarted.isLogin, false);
    expect(await ZhengFangUserProvider.readPassword(), isNull);
  });

  test('A queued old-session renewal is rejected after account replacement',
      () async {
    final user = provider();
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    final revision = user.sessionRevision;
    await user.setUser(account('b'),
        password: 'test-password-b', rememberPassword: true);
    await expectLater(
        user.setCookie('obsolete', expectedSessionRevision: revision),
        throwsStateError);
    expect(ZhengFangUserProvider.cookie, 'session-b');
  });

  test('Explicit login can replace a damaged encrypted snapshot', () async {
    stored['sessionZF'] = '{invalid';
    final user = provider();
    await expectLater(user.init(), throwsFormatException);
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    final restarted = provider();
    await restarted.init();
    expect(restarted.user.studentID, 'a');
  });

  test(
      'Cold requests restore, share renewal, and persist it for the next start',
      () async {
    seedLegacy('a');
    final user = provider();
    final readStarted = Completer<void>();
    final releaseRead = Completer<void>();
    var firstRead = true;
    beforeRead = (key) async {
      if (key == 'sessionZF' && firstRead) {
        firstRead = false;
        readStarted.complete();
        await releaseRead.future;
      }
    };
    var logins = 0;
    final loginStarted = Completer<void>();
    final loginResult = Completer<String>();
    final recovery = ZhengFangSessionRecovery(login: (username, password) {
      expect(username, 'a');
      expect(password, 'test-password-a');
      logins++;
      loginStarted.complete();
      return loginResult.future;
    });
    final attemptedCookies = <String>[];
    final requests = List.generate(
        3,
        (_) => withAutoLoginRetry(
            initialCookie: 'stale-before-restoration',
            zhengFangUserProvider: user,
            recovery: recovery,
            action: (cookie) async {
              attemptedCookies.add(cookie);
              if (cookie != 'renewed-session-a') {
                throw 'Http status code = 901';
              }
              return 'course-data';
            }));
    await readStarted.future;
    expect(attemptedCookies, isEmpty);
    releaseRead.complete();
    await loginStarted.future;
    await Future<void>.delayed(Duration.zero);
    loginResult.complete('renewed-session-a');
    expect(await Future.wait(requests), List.filled(3, 'course-data'));
    expect(logins, 1);
    expect(attemptedCookies.where((c) => c == 'session-a'), hasLength(3));
    expect(attemptedCookies, isNot(contains('stale-before-restoration')));

    final restarted = provider();
    await restarted.init();
    expect(restarted.user.cookie, 'renewed-session-a');
    expect(await ZhengFangUserProvider.readPassword(), 'test-password-a');
  });

  test('Choosing not to remember removes the password across restarts',
      () async {
    final user = provider();
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    await user.setUser(account('a', 'new-session-a'),
        password: 'test-password-a', rememberPassword: false);
    final restarted = provider();
    await restarted.init();
    expect(restarted.user.cookie, 'new-session-a');
    expect(await ZhengFangUserProvider.readPassword(), isNull);
    expect(stored['passwordZF'], isNull);
  });

  test(
      'Cookie login into a different account does not inherit a saved password',
      () async {
    final user = provider();
    await user.setUser(account('a'),
        password: 'test-password-a', rememberPassword: true);
    await user.setUser(account('b'));
    final restarted = provider();
    await restarted.init();
    expect(restarted.user.studentID, 'b');
    expect(await ZhengFangUserProvider.readPassword(), isNull);
  });
}
