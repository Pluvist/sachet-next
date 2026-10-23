import 'package:flutter/foundation.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';

import 'login/zhengfang_login_service.dart';

bool isZhengFangSessionExpired(Object error) {
  final errorStr = error.toString();
  return errorStr.contains('Http status code = 302') ||
      errorStr.contains('Http status code = 901');
}

final _sharedRecovery = ZhengFangSessionRecovery();

/// All authenticated features share one login for an expired account session.
/// Dependencies can be supplied for deterministic tests without real logins.
class ZhengFangSessionRecovery {
  ZhengFangSessionRecovery({
    Future<String?> Function()? readPassword,
    Future<String> Function(String username, String password)? login,
  })  : _readPassword = readPassword ?? ZhengFangUserProvider.readPassword,
        _login = login ?? _loginWithPassword;

  final Future<String?> Function() _readPassword;
  final Future<String> Function(String username, String password) _login;
  final _pending = <(ZhengFangUserProvider, int), Future<String>>{};

  static Future<String> _loginWithPassword(
      String username, String password) async {
    final service = ZhengFangLoginService();
    await service.login(username: username, password: password);
    return service.cookie;
  }

  Future<String> recover({
    required ZhengFangUserProvider provider,
    required String account,
    required int revision,
    required String failedCookie,
  }) async {
    void checkCurrent() {
      if (!provider.isLogin ||
          provider.user.studentID != account ||
          provider.sessionRevision != revision) {
        throw StateError('登录账号已变化');
      }
    }

    checkCurrent();
    if ((provider.user.cookie ?? '').isNotEmpty &&
        provider.user.cookie != failedCookie) {
      return provider.user.cookie!;
    }

    final key = (provider, revision);
    final pending = _pending[key];
    if (pending != null) return pending;

    Future<String> login() async {
      final password = await _readPassword();
      checkCurrent();
      // A request may finish recovering while the saved password is read.
      if ((provider.user.cookie ?? '').isNotEmpty &&
          provider.user.cookie != failedCookie) {
        return provider.user.cookie!;
      }
      if (password == null || password.isEmpty) {
        throw StateError('未保存教务系统密码');
      }
      final cookie = await _login(account, password);
      checkCurrent();
      if (cookie.isEmpty) throw StateError('登录未返回有效 Cookie');
      if (provider.user.cookie != failedCookie) {
        return provider.user.cookie!;
      }
      await provider.setCookie(cookie, expectedSessionRevision: revision);
      checkCurrent();
      return provider.user.cookie!;
    }

    final recovery = login();
    _pending[key] = recovery;
    try {
      return await recovery;
    } finally {
      if (identical(_pending[key], recovery)) _pending.remove(key);
    }
  }
}

/// Retry one expired request after a shared silent login or Cookie rotation.
Future<T> withAutoLoginRetry<T>({
  required String initialCookie,
  required ZhengFangUserProvider? zhengFangUserProvider,
  bool Function(Object error) isSessionExpired = isZhengFangSessionExpired,
  required Future<T> Function(String activeCookie) action,
  @visibleForTesting ZhengFangSessionRecovery? recovery,
}) async {
  final provider = zhengFangUserProvider;
  await provider?.init();
  final requestedAccount = provider?.user.studentID;
  final requestedRevision = provider?.sessionRevision;
  final activeCookie = provider != null && provider.isLogin
      ? provider.user.cookie ?? initialCookie
      : initialCookie;

  void checkCurrent() {
    if (provider != null &&
        requestedAccount != null &&
        (!provider.isLogin ||
            provider.user.studentID != requestedAccount ||
            provider.sessionRevision != requestedRevision)) {
      throw StateError('登录账号已变化');
    }
  }

  try {
    final result = await action(activeCookie);
    checkCurrent();
    return result;
  } catch (e) {
    if (!isSessionExpired(e)) rethrow;
    if (provider == null ||
        requestedAccount == null ||
        requestedAccount.trim().isEmpty) rethrow;
    String newCookie;
    try {
      newCookie = await (recovery ?? _sharedRecovery).recover(
        provider: provider,
        account: requestedAccount,
        revision: requestedRevision!,
        failedCookie: activeCookie,
      );
      checkCurrent();
    } catch (_) {
      // Preserve the request's expiry error for existing UI error handling.
      throw e;
    }
    final result = await action(newCookie);
    checkCurrent();
    return result;
  }
}
