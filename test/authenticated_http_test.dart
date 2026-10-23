import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/models/user.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/authenticated_http.dart';
import 'package:sachet/services/zhengfang_jwxt/auto_login_retry.dart';

const loginHtml = '''<!doctype html><html><body>
<form id="fm1" action="login_slogin.html">
<input name="yhm" id="yhm"><input name="mm" id="mm" type="password">
</form></body></html>''';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions options) respond;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

class _User extends ZhengFangUserProvider {
  final current = User(studentID: 'test-account', cookie: 'expired');
  @override
  User get user => current;
  @override
  bool get isLogin => true;
  @override
  int get sessionRevision => 1;
  @override
  Future<void> init() async {}
  @override
  Future<void> setCookie(String cookie, {int? expectedSessionRevision}) async {
    current.cookie = cookie;
  }
}

void main() {
  test('Only real login forms are classified as expiry', () {
    expect(isZhengFangLoginForm(loginHtml), true);
    for (final ordinary in [
      '',
      '<html><body>暂无数据</body></html>',
      '<form><input name="course"></form>',
      '<form><input name="yhm"></form>',
      '<p>请访问 login_slogin.html 获取帮助</p>',
      {'rows': []},
    ]) {
      expect(isZhengFangLoginForm(ordinary), false);
    }
  });

  test('HTTP-200 login HTML becomes expiry and triggers one shared recovery',
      () async {
    final user = _User();
    var logins = 0;
    final cookies = <String>[];
    final dio = createZhengFangDio();
    dio.httpClientAdapter = _Adapter((options) {
      final cookie = options.headers['Cookie'] as String;
      cookies.add(cookie);
      return ResponseBody.fromString(
        cookie == 'expired' ? loginHtml : '{"rows":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: [
            cookie == 'expired' ? 'text/html' : 'application/json'
          ]
        },
      );
    });
    final result = await withAutoLoginRetry(
        initialCookie: 'expired',
        zhengFangUserProvider: user,
        recovery: ZhengFangSessionRecovery(
            readPassword: () async => 'test-password',
            login: (_, __) async {
              logins++;
              return 'fresh';
            }),
        action: (cookie) async {
          final response = await dio.get('https://jw.xtu.edu.cn/jwglxt/test',
              options: Options(headers: {'Cookie': cookie}));
          if (response.statusCode != 200) {
            throw 'Http status code = ${response.statusCode}';
          }
          return response.data;
        });
    expect(result, {'rows': []});
    expect(cookies, ['expired', 'fresh']);
    expect(logins, 1);
    dio.close();
    user.dispose();
  });

  test('Redirects stay visible and unsupported compression is not requested',
      () async {
    final dio = createZhengFangDio();
    dio.httpClientAdapter = _Adapter((options) {
      expect(options.followRedirects, false);
      expect(options.headers['Accept-Encoding'], 'gzip');
      return ResponseBody.fromString('', 302, headers: {
        'location': ['/jwglxt/xtgl/login_slogin.html']
      });
    });
    final response = await dio.get('https://jw.xtu.edu.cn/jwglxt/test',
        options:
            Options(headers: {'Accept-Encoding': 'gzip, deflate, br, zstd'}));
    expect(response.statusCode, 302);
    expect(dio.options.connectTimeout, isNotNull);
    expect(dio.options.receiveTimeout, isNotNull);
    dio.close();
  });

  test('Permission errors stay distinct from an expired session', () async {
    final dio = createZhengFangDio();
    dio.httpClientAdapter =
        _Adapter((_) => ResponseBody.fromString('forbidden', 403));
    expect(
        (await dio.get('https://jw.xtu.edu.cn/jwglxt/test')).statusCode, 403);
    dio.close();
  });
}
