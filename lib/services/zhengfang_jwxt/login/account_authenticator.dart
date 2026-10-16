import 'package:flutter/foundation.dart';
import 'package:sachet/models/user.dart';
import 'get_name.dart';
import 'zhengfang_login_service.dart';

/// Authentication is separate from navigation; a valid session is persisted by
/// the login page before returning to its caller, without confirmation dialogs.
class AccountAuthenticator {
  const AccountAuthenticator();
  Future<User> passwordLogin(String username, String password) async {
    final service = ZhengFangLoginService();
    await service.login(username: username, password: password);
    String name = '';
    try {
      name = await getNameZF(service.cookie);
    } catch (error) {
      if (kDebugMode) debugPrint('Account name unavailable: $error');
    }
    return User(cookie: service.cookie, name: name, studentID: username);
  }

  Future<User> cookieLogin(String cookie) async =>
      User(cookie: cookie, name: await getNameZF(cookie), studentID: '');
}
