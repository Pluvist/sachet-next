import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sachet/models/enums/store_item.dart';
import 'package:sachet/models/user.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/utils/storage/secure_storage_util.dart';

/// 正方教务系统的用户信息 Provider
class ZhengFangUserProvider extends ChangeNotifier {
  static final _secureStorageUtil = SecureStorageUtil();
  static User _user = User();
  static int _sessionRevision = 0;
  static int _mutationRevision = 0;
  static Future<void>? _pendingStorage;
  bool _initialized = false;
  bool _disposed = false;

  User get user => _user;
  static String get cookie => _user.cookie ?? '';
  int get sessionRevision => _sessionRevision;
  bool get isInitialized => _initialized;

  /// A saved session means the account can be restored, not that the server's
  /// session can never expire. Network requests renew it when necessary.
  bool get isLogin =>
      (_user.cookie ?? '').trim().isNotEmpty ||
      ((_user.studentID ?? '').trim().isNotEmpty &&
          (_user.password ?? '').isNotEmpty);

  // Serialize bridge operations even when the caller does not await a logout
  // or checkbox change. An older delete must not finish after a new login.
  static Future<T> _withStorage<T>(Future<T> Function() action) {
    final previous = _pendingStorage;
    final operation = previous == null
        ? Future<T>.sync(action)
        : previous.then((_) => action());
    // Release the completed tail when idle instead of retaining its Zone.
    // Both success and failure allow the next bridge operation to proceed.
    late final Future<void> tail;
    void release() {
      if (identical(_pendingStorage, tail)) _pendingStorage = null;
    }

    tail = operation.then<void>((_) => release(),
        onError: (Object _, StackTrace __) => release());
    _pendingStorage = tail;
    return operation;
  }

  static Future<void> _store(String key, String? value) => value == null
      ? _secureStorageUtil.delete(key: key)
      : _secureStorageUtil.save(key: key, value: value);

  // Called inside the storage queue. A single encrypted record prevents a
  // process exit or failed bridge write from mixing two accounts' credentials.
  static Future<User> _readStoredUser() async {
    final snapshot =
        await _secureStorageUtil.read(key: StoreItem.sessionZF.keyName);
    if (snapshot != null) {
      final decoded = jsonDecode(snapshot);
      if (decoded is! Map<String, dynamic> ||
          ['name', 'studentID', 'cookie', 'password']
              .any((key) => decoded[key] != null && decoded[key] is! String)) {
        throw const FormatException('已保存的登录信息格式无效');
      }
      return User.fromJson(decoded);
    }
    final legacy = User(
      name: await _secureStorageUtil.read(key: StoreItem.nameZF.keyName),
      studentID:
          await _secureStorageUtil.read(key: StoreItem.studentIDZF.keyName),
      cookie: await _secureStorageUtil.read(key: StoreItem.cookieZF.keyName),
      password:
          await _secureStorageUtil.read(key: StoreItem.passwordZF.keyName),
    );
    await _writeSnapshot(legacy);
    return legacy;
  }

  static Future<void> _writeSnapshot(User user) => _secureStorageUtil.save(
      key: StoreItem.sessionZF.keyName, value: jsonEncode(user.toJson()));

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 从 SecureStorage 获取储存的 学号和密码
  Future<void>? _initialization;
  Future<void> init() {
    if (_initialized) return Future<void>.value();
    return _initialization ??=
        _initialize().catchError((Object error, StackTrace stack) {
      _initialization = null; // A temporary storage failure can be retried.
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _initialize() async {
    final startedAt = _mutationRevision;
    // 如果还没有删除过强智教务系统的用户信息，则删除强智教务系统的用户信息
    if (AppGlobal.appSettings.isDeleteQZJwxtUserInfo != true) {
      // Optional retirement of the older system must not prevent restoration
      // of a saved ZhengFang session when preferences are temporarily unwritable.
      try {
        await deleteQiangZhiUserInfo();
        AppGlobal.appSettings.isDeleteQZJwxtUserInfo = true;
        await AppGlobal.persistAppSettings();
      } catch (_) {
        AppGlobal.appSettings.isDeleteQZJwxtUserInfo = false;
      }
    }

    final restored = await _withStorage(_readStoredUser);
    if (startedAt != _mutationRevision) {
      // Login/logout/renewal happened while storage was being read. That newer
      // state is authoritative; do not restore an older captured snapshot.
      if (!_initialized) await _initialize();
      return;
    }
    final hasSavedAccount = (restored.studentID ?? '').trim().isNotEmpty &&
        (restored.password ?? '').isNotEmpty;
    final next = (restored.cookie ?? '').trim().isEmpty && !hasSavedAccount
        ? User()
        : restored;
    if (_user.studentID != next.studentID || _user.cookie != next.cookie) {
      _sessionRevision++;
    }
    _user = next;
    _initialized = true;
    _notify();
  }

  /// Publish login only after its identity and remembered credential are saved.
  /// Existing cookie/web callers can omit the password options.
  Future<void> setUser(User newUser,
      {String? password, bool? rememberPassword}) async {
    if ((newUser.cookie ?? '').trim().isEmpty) {
      throw ArgumentError('登录会话不能为空');
    }
    if (rememberPassword == true && password == null) {
      throw ArgumentError('记住密码时必须提供密码');
    }
    final previous = _user;
    final revision = ++_sessionRevision;
    _mutationRevision++;
    final next = User(
        name: newUser.name,
        studentID: newUser.studentID,
        cookie: newUser.cookie,
        password: rememberPassword == true ? password : null);
    final changedAccount =
        previous.studentID != next.studentID || (next.studentID ?? '').isEmpty;
    _user = next;
    _initialized = true;
    try {
      await _withStorage(() async {
        User saved;
        try {
          saved = await _readStoredUser();
        } on FormatException {
          // A fresh explicit login can replace a damaged snapshot. Never use
          // mixed legacy fields to silently recover that damaged account.
          saved = User();
        }
        if (rememberPassword == true) {
          await _store(StoreItem.passwordZF.keyName, password);
        } else if (rememberPassword == false || changedAccount) {
          await _secureStorageUtil.delete(key: StoreItem.passwordZF.keyName);
        }
        await _store(StoreItem.nameZF.keyName, next.name);
        await _store(StoreItem.studentIDZF.keyName, next.studentID);
        // Cookie is the last persisted field: the notification below must not
        // trigger background refresh before its remembered password is ready.
        await _store(StoreItem.cookieZF.keyName, next.cookie);
        await _writeSnapshot(User(
          name: next.name,
          studentID: next.studentID,
          cookie: next.cookie,
          password: rememberPassword == true
              ? password
              : (rememberPassword == false || changedAccount
                  ? null
                  : saved.password),
        ));
      });
    } catch (_) {
      if (_sessionRevision == revision) {
        _sessionRevision++;
        _mutationRevision++;
        _user = previous;
        _notify();
      }
      rethrow;
    }
    if (_sessionRevision == revision) _notify();
  }

  /// 设置 cookie
  Future<void> setCookie(String newCookie,
      {int? expectedSessionRevision}) async {
    if (newCookie.trim().isEmpty) throw ArgumentError('登录会话不能为空');
    final revision = expectedSessionRevision ?? _sessionRevision;
    if (revision != _sessionRevision || !isLogin) {
      throw StateError('登录账号已变化');
    }
    _mutationRevision++;
    await _withStorage(() async {
      if (revision != _sessionRevision || !isLogin) {
        throw StateError('登录账号已变化');
      }
      final saved = await _readStoredUser();
      await _secureStorageUtil.save(
          key: StoreItem.cookieZF.keyName, value: newCookie);
      saved.cookie = newCookie;
      await _writeSnapshot(saved);
      if (revision == _sessionRevision) _user.cookie = newCookie;
    });
    if (revision == _sessionRevision) _notify();
  }

  /// 读取密码
  static Future<String?> readPassword() async {
    return _withStorage(() async => (await _readStoredUser()).password);
  }

  /// 保存密码
  static Future<void> savePassword(String password) async {
    final revision = _sessionRevision;
    _mutationRevision++;
    await _withStorage(() async {
      final saved = await _readStoredUser();
      await _secureStorageUtil.save(
        key: StoreItem.passwordZF.keyName,
        value: password,
      );
      saved.password = password;
      await _writeSnapshot(saved);
      if (revision == _sessionRevision) _user.password = password;
    });
  }

  /// 删除密码
  static Future<void> deletePassword() {
    _mutationRevision++;
    _user.password = null;
    return _withStorage(() async {
      final saved = await _readStoredUser();
      saved.password = null;
      await _writeSnapshot(saved);
      await _secureStorageUtil.delete(key: StoreItem.passwordZF.keyName);
    });
  }

  /// 删除用户信息
  Future<void> deleteUser() {
    _sessionRevision++;
    _mutationRevision++;
    _user = User();
    _initialized = true;
    _notify();
    return _withStorage(() async {
      // Keep a tombstone so leftover legacy keys cannot restore a logged-out
      // account after a process exit in the middle of cleanup.
      await _writeSnapshot(User());
      for (final item in [
        StoreItem.nameZF,
        StoreItem.studentIDZF,
        StoreItem.passwordZF,
        StoreItem.cookieZF
      ]) {
        await _secureStorageUtil.delete(key: item.keyName);
      }
    });
  }

  /// 删除旧教务系统（强智教务系统）的用户信息
  static Future<void> deleteQiangZhiUserInfo() async {
    await _withStorage(() async {
      await _secureStorageUtil.delete(key: StoreItem.nameQZ.keyName);
      await _secureStorageUtil.delete(key: StoreItem.studentIDQZ.keyName);
      await _secureStorageUtil.delete(key: StoreItem.passwordQZ.keyName);
      await _secureStorageUtil.delete(key: StoreItem.cookieQZ.keyName);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
