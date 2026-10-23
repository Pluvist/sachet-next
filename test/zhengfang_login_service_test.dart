import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/services/zhengfang_jwxt/login/zhengfang_login_service.dart';

const _loginPage = '<input id="csrftoken" value="fake-csrf">';
const _menu = '/jwglxt/xtgl/index_initMenu.html?jsdm=';
const _initialCookies = <String>[
  'route=fake-route; Path=/',
  'JSESSIONID=fake-initial; Path=/jwglxt; HttpOnly',
];

ResponseBody _html(String html,
        {int status = 200, List<String>? cookies, String? location}) =>
    ResponseBody.fromString(html, status, headers: {
      Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      if (cookies != null) 'set-cookie': cookies,
      if (location != null) 'location': [location],
    });

ResponseBody _publicKey({List<String>? cookies}) => ResponseBody.fromString(
      jsonEncode({
        // Synthetic public key material; these tests perform no network I/O.
        'modulus': base64Encode(List.filled(128, 255)),
        'exponent': 'AQAB',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (cookies != null) 'set-cookie': cookies,
      },
    );

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  final List<ResponseBody> responses;
  final List<RequestOptions> requests = [];
  final List<String> bodies = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    bodies.add(requestStream == null
        ? ''
        : utf8.decode(await requestStream.expand((bytes) => bytes).toList()));
    if (responses.isEmpty) fail('Unexpected request: ${options.uri.path}');
    return responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;
  late ZhengFangLoginService service;

  void prepare(List<ResponseBody> responses) {
    adapter = _FakeAdapter(responses);
    service = ZhengFangLoginService(dio: Dio()..httpClientAdapter = adapter);
  }

  Future<void> login() async =>
      service.login(username: 'fake-student', password: 'fake-password');

  group('ZhengFangLoginService transport', () {
    test('password login retains route and captures the rotated session',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: _menu, cookies: [
          'rememberMe=deleteMe; Max-Age=0; Path=/jwglxt',
          'JSESSIONID=fake-authenticated; Path=/jwglxt; HttpOnly',
        ]),
      ]);

      await login();

      expect(service.cookie, 'route=fake-route; JSESSIONID=fake-authenticated');
      expect(adapter.requests, hasLength(3));
      expect(adapter.requests.last.followRedirects, isFalse);
      expect(adapter.requests.last.method, 'POST');
      final form = Uri.splitQueryString(adapter.bodies.last);
      expect(form['csrftoken'], 'fake-csrf');
      expect(form['yhm'], 'fake-student');
      expect(adapter.bodies.last, isNot(contains('fake-password')));
      expect(adapter.responses, isEmpty);
    });

    test('cookies from bootstrap redirects are sent to the login page',
        () async {
      prepare([
        _html('',
            status: 302,
            location: 'login_slogin.html',
            cookies: _initialCookies),
        _html(_loginPage),
        _publicKey(),
        _html('', status: 302, location: _menu),
      ]);

      await login();

      expect(adapter.requests[1].uri.path, '/jwglxt/xtgl/login_slogin.html');
      expect(adapter.requests[1].headers['Cookie'],
          'route=fake-route; JSESSIONID=fake-initial');
      expect(service.cookie, 'route=fake-route; JSESSIONID=fake-initial');
    });

    test('public key and login responses can independently rotate cookies',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(cookies: [
          'JSESSIONID=fake-key-session; Path=/jwglxt',
          'route=fake-key-route; Path=/',
        ]),
        _html('', status: 302, location: _menu, cookies: [
          'route=fake-final-route; Path=/',
        ]),
      ]);

      await login();

      expect(adapter.requests.last.headers['Cookie'],
          'route=fake-key-route; JSESSIONID=fake-key-session');
      expect(service.cookie,
          'route=fake-final-route; JSESSIONID=fake-key-session');
    });

    for (final destination in [
      'index_index.html',
      'index_initMenu.html;jsessionid=fake-url-session?jsdm=',
      '/jwglxt/xtgl/login_success.html',
    ]) {
      test(
          'verifies the session after an alternative landing route: $destination',
          () async {
        prepare([
          _html(_loginPage, cookies: _initialCookies),
          _publicKey(),
          _html('', status: 302, location: destination),
          _html('<h4 class="media-heading">测试学生&nbsp;学生</h4>', cookies: [
            'JSESSIONID=fake-verified; Path=/jwglxt',
          ]),
        ]);
        await login();
        expect(adapter.requests, hasLength(4));
        expect(adapter.requests.last.method, 'GET');
        expect(adapter.requests.last.uri.path,
            '/jwglxt/xtgl/index_cxYhxxIndex.html');
        expect(service.cookie, contains('JSESSIONID=fake-verified'));
      });
    }

    test('HTTP 200 script landing is confirmed against the protected profile',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('<script>location.href="index_index.html";</script>'),
        _html('<h4 class="media-heading">测试学生&nbsp;学生</h4>'),
      ]);
      await login();
      expect(adapter.requests, hasLength(4));
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    });

    test('HTTP 200 without an error message is not accepted as proof of login',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('<html>Intermediate page</html>'),
        _html('', status: 302, location: 'login_slogin.html'),
      ]);
      await expectLater(
          login(), throwsA(predicate((e) => e.toString().contains('登录状态未生效'))));
      expect(adapter.requests, hasLength(4));
    });

    test(
        'alternative landing route is rejected if the protected profile is empty',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: 'index_index.html'),
        _html('<html>Maintenance</html>'),
      ]);
      await expectLater(login(),
          throwsA(predicate((e) => e.toString().contains('未能确认登录状态'))));
    });

    test('login form in the profile cannot masquerade as an authenticated page',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: 'index_index.html'),
        _html('<h4 class="media-heading">欢迎</h4>'
            '<form><input name="yhm"><input name="mm"></form>'),
      ]);
      await expectLater(login(), throwsException);
    });

    test('profile redirects cannot leak cookies outside the academic server',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: 'index_index.html'),
        _html('',
            status: 302, location: 'https://example.invalid/jwglxt/profile'),
      ]);
      await expectLater(login(), throwsException);
      expect(adapter.requests, hasLength(4));
    });

    test(
        'profile verification follows an internal redirect with rotated cookies',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: 'index_index.html'),
        _html('',
            status: 307,
            location: 'index_cxYhxxIndex.html?xt=jw',
            cookies: ['route=fake-profile-route; Path=/']),
        _html('<h4 class="media-heading">测试学生</h4>'),
      ]);
      await login();
      expect(adapter.requests, hasLength(5));
      expect(adapter.requests.last.method, 'GET');
      expect(adapter.requests.last.headers['Cookie'],
          contains('route=fake-profile-route'));
    });

    test('profile verification cannot accept a deleted session', () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: 'index_index.html'),
        _html('<h4 class="media-heading">测试学生</h4>', cookies: [
          'JSESSIONID=deleted; Max-Age=0; Path=/jwglxt',
        ]),
      ]);
      await expectLater(login(),
          throwsA(predicate((e) => e.toString().contains('有效的 JSESSIONID'))));
    });

    test('profile outage does not retry the password POST', () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: 'index_index.html'),
        _html('Unavailable', status: 503),
      ]);
      await expectLater(login(),
          throwsA(predicate((e) => e.toString().contains('HTTP 503'))));
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    });

    test('route cookie is optional and an unchanged session remains valid',
        () async {
      prepare([
        _html(_loginPage, cookies: ['JSESSIONID=fake-session; Path=/jwglxt']),
        _publicKey(),
        _html('', status: 303, location: 'lxtgl/index_initMenu.html'),
      ]);

      await login();

      expect(service.cookie, 'JSESSIONID=fake-session');
      expect(
          adapter.requests.last.headers['Cookie'], 'JSESSIONID=fake-session');
    });

    test('cookie deletion removes the route instead of persisting an old value',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: _menu, cookies: [
          'route=deleted; Max-Age=0; Path=/',
        ]),
      ]);

      await login();

      expect(service.cookie, 'JSESSIONID=fake-initial');
    });

    test('deleted session cookie cannot be accepted as a successful login',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: _menu, cookies: [
          'JSESSIONID=deleted; Max-Age=0; Path=/jwglxt',
        ]),
      ]);

      await expectLater(login(),
          throwsA(predicate((e) => e.toString().contains('有效的 JSESSIONID'))));
    });

    for (final destination in [
      'login_slogin.html',
      '/jwglxt/xtgl/error.html',
      'https://example.invalid/jwglxt/xtgl/index_initMenu.html',
      'http://jw.xtu.edu.cn/jwglxt/xtgl/index_initMenu.html',
    ]) {
      test('rejects a login redirect to $destination', () async {
        prepare([
          _html(_loginPage, cookies: _initialCookies),
          _publicKey(),
          _html('', status: 302, location: destination),
        ]);

        await expectLater(login(), throwsException);
        expect(adapter.requests, hasLength(3));
      });
    }

    test('missing login redirect location is rejected', () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302),
      ]);

      await expectLater(login(),
          throwsA(predicate((e) => e.toString().contains('未包含重定向地址'))));
    });

    test('displays the server credential error and leaves no silent success',
        () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('<div id="tips">用户名或密码不正确，请重新输入！</div>'),
      ]);

      await expectLater(login(),
          throwsA(predicate((e) => e.toString().contains('用户名或密码不正确'))));
    });

    test('missing csrf reports a login-page failure before posting credentials',
        () async {
      prepare([_html('<html>Maintenance</html>', cookies: _initialCookies)]);

      await expectLater(
          login(),
          throwsA(
              predicate((e) => e.toString().contains('csrftoken is null'))));
      expect(adapter.requests, hasLength(1));
    });

    test('bootstrap redirects cannot send session cookies to another host',
        () async {
      prepare([
        _html('',
            status: 302,
            location: 'https://example.invalid/jwglxt/xtgl/login_slogin.html',
            cookies: _initialCookies),
      ]);

      await expectLater(login(), throwsException);
      expect(adapter.requests, hasLength(1));
    });

    test('a second attempt does not inherit old cookies or csrf', () async {
      prepare([
        _html(_loginPage, cookies: _initialCookies),
        _publicKey(),
        _html('', status: 302, location: _menu),
        _html(_loginPage),
      ]);
      await login();

      await expectLater(login(),
          throwsA(predicate((e) => e.toString().contains('提取 JSESSIONID'))));

      expect(adapter.requests[3].headers['Cookie'], isEmpty);
      expect(service.cookie, isEmpty);
    });
  });
}
