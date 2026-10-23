import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/models/user.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/auto_login_retry.dart';

class _UserProvider extends ZhengFangUserProvider {
  User currentUser = User(studentID: 'student-a', cookie: 'expired');
  int revision = 1;
  int cookieWrites = 0;
  Future<void>? initialization;

  @override
  User get user => currentUser;
  @override
  bool get isLogin => currentUser.cookie != null;
  @override
  int get sessionRevision => revision;
  @override
  Future<void> init() async => initialization;
  @override
  Future<void> setCookie(String cookie, {int? expectedSessionRevision}) async {
    if (expectedSessionRevision != null &&
        expectedSessionRevision != revision) {
      throw StateError('登录账号已变化');
    }
    cookieWrites++;
    currentUser.cookie = cookie;
  }

  void signInAgain({String account = 'student-a'}) {
    revision++;
    currentUser = User(studentID: account, cookie: 'manual-login');
  }

  void logout() {
    revision++;
    currentUser = User();
  }
}

const _expired302 = '获取数据失败: Http status code = 302';
const _expired901 = '获取数据失败: Http status code = 901';

void main() {
  test('Request waits for restoration and uses the restored Cookie', () async {
    final user = _UserProvider()..currentUser = User();
    final initialized = Completer<void>();
    user.initialization = initialized.future;
    final seen = <String>[];
    final request = withAutoLoginRetry(
      initialCookie: '',
      zhengFangUserProvider: user,
      action: (cookie) async {
        seen.add(cookie);
        return cookie;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
    user.currentUser = User(studentID: 'student-a', cookie: 'restored');
    initialized.complete();
    expect(await request, 'restored');
    expect(seen, ['restored']);
  });

  test('Concurrent 302 and 901 failures share one login and Cookie write',
      () async {
    final user = _UserProvider();
    final loginStarted = Completer<void>();
    final loginResult = Completer<String>();
    int logins = 0;
    final recovery = ZhengFangSessionRecovery(
      readPassword: () async => 'saved-password',
      login: (account, password) {
        logins++;
        expect(account, 'student-a');
        expect(password, 'saved-password');
        loginStarted.complete();
        return loginResult.future;
      },
    );
    Future<String> request(String failure) => withAutoLoginRetry(
          initialCookie: 'expired',
          zhengFangUserProvider: user,
          recovery: recovery,
          action: (cookie) async {
            if (cookie == 'expired') throw failure;
            return cookie;
          },
        );
    final first = request(_expired302);
    final second = request(_expired901);
    await loginStarted.future;
    expect(logins, 1);
    loginResult.complete('fresh');
    expect(await Future.wait([first, second]), ['fresh', 'fresh']);
    expect(logins, 1);
    expect(user.cookieWrites, 1);
  });

  test('Late expiry reuses a Cookie already recovered by another request',
      () async {
    final user = _UserProvider();
    final oldRequest = Completer<String>();
    int logins = 0;
    final recovery = ZhengFangSessionRecovery(
      readPassword: () async => 'saved',
      login: (_, __) async {
        logins++;
        return 'fresh';
      },
    );
    final seen = <String>[];
    final late = withAutoLoginRetry(
      initialCookie: 'expired',
      zhengFangUserProvider: user,
      recovery: recovery,
      action: (cookie) {
        seen.add(cookie);
        return cookie == 'expired' ? oldRequest.future : Future.value(cookie);
      },
    );
    await Future<void>.delayed(Duration.zero);
    await user.setCookie('fresh');
    oldRequest.completeError(_expired901);
    expect(await late, 'fresh');
    expect(seen, ['expired', 'fresh']);
    expect(logins, 0);
  });

  test('Cookie updated during password read prevents a redundant login',
      () async {
    final user = _UserProvider();
    final password = Completer<String?>();
    final passwordRead = Completer<void>();
    int logins = 0;
    final recovery = ZhengFangSessionRecovery(
      readPassword: () {
        passwordRead.complete();
        return password.future;
      },
      login: (_, __) async {
        logins++;
        return 'redundant';
      },
    );
    final request = withAutoLoginRetry(
      initialCookie: 'expired',
      zhengFangUserProvider: user,
      recovery: recovery,
      action: (cookie) async {
        if (cookie == 'expired') throw _expired302;
        return cookie;
      },
    );
    await passwordRead.future;
    await user.setCookie('fresh');
    password.complete('saved');
    expect(await request, 'fresh');
    expect(logins, 0);
  });

  for (final change in ['logout', 'other account', 'same account']) {
    test('$change during login discards recovery and does not retry', () async {
      final user = _UserProvider();
      final loginStarted = Completer<void>();
      final loginResult = Completer<String>();
      final recovery = ZhengFangSessionRecovery(
        readPassword: () async => 'saved',
        login: (_, __) {
          loginStarted.complete();
          return loginResult.future;
        },
      );
      int actions = 0;
      final request = withAutoLoginRetry(
        initialCookie: 'expired',
        zhengFangUserProvider: user,
        recovery: recovery,
        action: (_) async {
          actions++;
          throw _expired901;
        },
      );
      final failed = expectLater(request, throwsA(_expired901));
      await loginStarted.future;
      if (change == 'logout') {
        user.logout();
      } else {
        user.signInAgain(
            account: change == 'same account' ? 'student-a' : 'student-b');
      }
      loginResult.complete('obsolete');
      await failed;
      expect(user.cookieWrites, 0);
      expect(actions, 1);
      expect(user.user.cookie, isNot('obsolete'));
    });
  }

  test('Account changes during password read prevent the network login',
      () async {
    final user = _UserProvider();
    final password = Completer<String?>();
    final passwordRead = Completer<void>();
    int logins = 0;
    final recovery = ZhengFangSessionRecovery(
      readPassword: () {
        passwordRead.complete();
        return password.future;
      },
      login: (_, __) async {
        logins++;
        return 'obsolete';
      },
    );
    final request = withAutoLoginRetry(
      initialCookie: 'expired',
      zhengFangUserProvider: user,
      recovery: recovery,
      action: (_) async => throw _expired302,
    );
    final failed = expectLater(request, throwsA(_expired302));
    await passwordRead.future;
    user.signInAgain(account: 'student-b');
    password.complete('saved');
    await failed;
    expect(logins, 0);
    expect(user.cookieWrites, 0);
  });

  test('A failed recovery is cleared so a later request can recover', () async {
    final user = _UserProvider();
    int logins = 0;
    final recovery = ZhengFangSessionRecovery(
      readPassword: () async => 'saved',
      login: (_, __) async {
        if (++logins == 1) throw StateError('offline');
        return 'fresh';
      },
    );
    Future<String> request() => withAutoLoginRetry(
          initialCookie: 'expired',
          zhengFangUserProvider: user,
          recovery: recovery,
          action: (cookie) async {
            if (cookie == 'expired') throw _expired901;
            return cookie;
          },
        );
    await expectLater(request(), throwsA(_expired901));
    expect(await request(), 'fresh');
    expect(logins, 2);
    expect(user.cookieWrites, 1);
  });

  test('An unremembered password preserves the expiry error without login',
      () async {
    int logins = 0;
    final recovery = ZhengFangSessionRecovery(
      readPassword: () async => null,
      login: (_, __) async {
        logins++;
        return 'fresh';
      },
    );
    await expectLater(
      withAutoLoginRetry(
        initialCookie: 'expired',
        zhengFangUserProvider: _UserProvider(),
        recovery: recovery,
        action: (_) async => throw _expired302,
      ),
      throwsA(_expired302),
    );
    expect(logins, 0);
  });

  test('Ordinary network failure never attempts a login', () async {
    int passwordReads = 0;
    final failure = StateError('offline');
    final recovery = ZhengFangSessionRecovery(
      readPassword: () async {
        passwordReads++;
        return 'saved';
      },
    );
    await expectLater(
      withAutoLoginRetry(
        initialCookie: 'expired',
        zhengFangUserProvider: _UserProvider(),
        recovery: recovery,
        action: (_) async => throw failure,
      ),
      throwsA(same(failure)),
    );
    expect(passwordReads, 0);
  });

  test('A retried request that is still expired does not loop', () async {
    int actions = 0, logins = 0;
    final recovery = ZhengFangSessionRecovery(
      readPassword: () async => 'saved',
      login: (_, __) async {
        logins++;
        return 'fresh';
      },
    );
    await expectLater(
      withAutoLoginRetry(
        initialCookie: 'expired',
        zhengFangUserProvider: _UserProvider(),
        recovery: recovery,
        action: (_) async {
          actions++;
          throw _expired901;
        },
      ),
      throwsA(_expired901),
    );
    expect([actions, logins], [2, 1]);
  });

  test('Successful response from a previous same-account login is discarded',
      () async {
    final user = _UserProvider();
    final response = Completer<String>();
    final request = withAutoLoginRetry(
      initialCookie: 'expired',
      zhengFangUserProvider: user,
      action: (_) => response.future,
    );
    final failed = expectLater(request, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    user.signInAgain();
    response.complete('old-account-data');
    await failed;
  });
}
