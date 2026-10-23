import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import '../authenticated_http.dart';

import 'package:sachet/utils/transform.dart';

import 'encrypt.dart';

class ZhengFangLoginService {
  final Dio _dio;
  ZhengFangLoginService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
                validateStatus: (_) => true,
                connectTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15)));

  static final _baseUri = Uri.parse('https://jw.xtu.edu.cn/jwglxt/xtgl/');
  final Map<String, String> _cookies = {};
  String _csrftoken = '';
  String get cookie =>
      _cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');

  Future login({
    required String username, // 用户名（学号）
    required String password,
  }) async {
    // A new attempt must not reuse a failed attempt's session or routing cookie.
    _cookies.clear();
    _csrftoken = '';
    // 01. 初始化请求，获取 cookie 和 csrftoken
    await _firstContact();

    // 02. 从服务器获取公钥
    final publicKey = await _fetchPublicKey();

    // 03. 对用户输入的密码用从服务器获取的公钥执行加密
    final encryptedPassword = RSAEncryptor.encryptPassword(
        password, publicKey['modulus']!, publicKey['exponent']!);

    // 04. 发起登录 POST 请求
    await _loginRequest(
      csrftoken: _csrftoken,
      yhm: username,
      mm: encryptedPassword,
    );
  }

  /// 初始化请求，获取 cookie 和 csrftoken
  Future _firstContact() async {
    try {
      var uri = _baseUri;
      late Response<String> response;
      // Capture cookies on every hop; Dio's automatic redirects do not maintain
      // a cookie jar, and a session may be issued before the final login page.
      for (var redirects = 0;; redirects++) {
        response = await _dio.get<String>(uri.toString(),
            options: Options(
              followRedirects: false,
              validateStatus: (_) => true,
              responseType: ResponseType.plain,
              headers: {'Cookie': cookie},
            ));
        _updateCookies(response);
        if (!_isRedirect(response.statusCode)) break;
        if (redirects >= 5) throw '登录页面重定向次数过多';
        uri = _redirectUri(response, uri);
      }

      if (response.statusCode != 200) {
        throw 'Http status code = ${response.statusCode}';
      }

      final csrftoken = _extractCsrfToken(response.data ?? '');
      if (csrftoken == null || csrftoken.isEmpty) {
        throw 'csrftoken is null';
      }
      _csrftoken = csrftoken;

      if (!_cookies.containsKey('JSESSIONID')) {
        throw '无法从 Set-Cookie 中提取 JSESSIONID';
      }
    } on DioException catch (e) {
      String? errorTypeText = dioExceptionTypeToText[e.type];
      throw Exception('初始化网络请求失败: $errorTypeText');
    } catch (e) {
      throw Exception('初始化请求失败: $e');
    }
  }

  /// 从 HTML 中提取 csrftoken
  String? _extractCsrfToken(String html) {
    final document = parse(encoding: '', html);
    String? csrftoken =
        document.getElementById('csrftoken')?.attributes['value'];
    return csrftoken;
  }

  /// 从服务器获取 rsa 公钥
  Future _fetchPublicKey() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    try {
      Response response = await _dio.get(
        'https://jw.xtu.edu.cn/jwglxt/xtgl/login_getPublicKey.html',
        queryParameters: {
          'time': timestamp,
          // '_': timestamp - 700,
        },
        options: Options(
            followRedirects: false,
            validateStatus: (_) => true,
            headers: {
              'Host': 'jw.xtu.edu.cn',
              'User-Agent':
                  'Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0',
              'Accept': 'application/json, text/javascript, */*; q=0.01',
              'Accept-Language': 'en-US,en;q=0.5',
              'X-Requested-With': 'XMLHttpRequest',
              'Connection': 'keep-alive',
              'Referer': 'https://jw.xtu.edu.cn/jwglxt/xtgl/login_slogin.html',
              'Cookie': cookie,
              'Upgrade-Insecure-Requests': '1',
              'Pragma': 'no-cache',
              'Cache-Control': 'no-cache',
            }),
      );
      _updateCookies(response);
      if (response.statusCode != 200) {
        throw 'Http status code = ${response.statusCode}';
      }

      // 正确返回的JSON格式为: {"modulus": "...", "exponent": "..."}
      if (response.data is! Map) {
        throw '格式无效';
      }

      String? modulus = response.data['modulus'];
      String? exponent = response.data['exponent'];
      if (modulus == null ||
          modulus.isEmpty ||
          exponent == null ||
          exponent.isEmpty) {
        throw '格式错误';
      }

      return response.data;
    } on DioException catch (e) {
      String? errorTypeText = dioExceptionTypeToText[e.type];
      throw Exception('获取公钥失败: $errorTypeText');
    } catch (e) {
      throw Exception('获取公钥失败: $e');
    }
  }

  /// 发起登录 POST 请求
  Future _loginRequest({
    required String csrftoken,
    required String yhm, // 用户名
    required String mm,
  }) async {
    try {
      final response = await _dio.post(
        'https://jw.xtu.edu.cn/jwglxt/xtgl/login_slogin.html',
        data: {
          'csrftoken': csrftoken,
          'language': 'zh_CN',
          'ydType': '',
          'yhm': yhm,
          'mm': [mm, mm]
        },
        options: Options(
            followRedirects: false,
            validateStatus: (_) => true,
            responseType: ResponseType.plain,
            headers: {
              'Host': 'jw.xtu.edu.cn',
              'User-Agent':
                  'Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.5',
              'Content-Type': 'application/x-www-form-urlencoded',
              'Origin': 'https://jw.xtu.edu.cn',
              'Connection': 'keep-alive',
              'Referer': 'https://jw.xtu.edu.cn/jwglxt/xtgl/login_slogin.html',
              'Cookie': cookie,
              'Upgrade-Insecure-Requests': '1',
              'Priority': 'u=0, i',
              'Pragma': 'no-cache',
              'Cache-Control': 'no-cache',
            }),
      );
      _updateCookies(response);
      if (response.statusCode == 200) {
        final errorMessage = _extractErrorMessage(response.data ?? '');
        if (errorMessage != null && errorMessage.isNotEmpty) {
          throw errorMessage;
        }
        // Some deployments return the landing page or a script with HTTP 200.
        // No error text alone is not proof of a successful authentication.
      } else if (response.statusCode == 302 || response.statusCode == 303) {
        final destination = _redirectUri(response, response.requestOptions.uri);
        if (_isLoginOrErrorPage(destination)) {
          throw '登录未成功，请检查账号密码或使用网页登录';
        }
        _requireSessionCookie();
        if (destination.path == '/jwglxt/xtgl/index_initMenu.html' ||
            destination.path == '/jwglxt/xtgl/lxtgl/index_initMenu.html') {
          return;
        }
        // An internal landing route may differ between server deployments.
        // Verify a protected resource instead of hard-coding every route.
      } else {
        throw 'Http status code = ${response.statusCode}';
      }
      _requireSessionCookie();
      await _verifyAuthenticatedSession();
    } on DioException catch (e) {
      String? errorTypeText = dioExceptionTypeToText[e.type];
      throw Exception('登录失败: $errorTypeText');
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }

  void _requireSessionCookie() {
    if (!_cookies.containsKey('JSESSIONID')) {
      throw '登录响应未保留有效的 JSESSIONID';
    }
  }

  bool _isLoginOrErrorPage(Uri uri) {
    final file = uri.path.split('/').last.split(';').first.toLowerCase();
    return file == 'login_slogin.html' ||
        file == 'login_login.html' ||
        file == 'login.html' ||
        file == 'error.html';
  }

  Future<void> _verifyAuthenticatedSession() async {
    var uri = _baseUri
        .resolve('index_cxYhxxIndex.html?xt=jw&localeKey=zh_CN&gnmkdm=index');
    for (var redirects = 0;; redirects++) {
      // Only GET the protected profile. Never replay the password POST or send
      // cookies to an untrusted redirect destination during verification.
      final response = await _dio.get<String>(uri.toString(),
          options: Options(
            followRedirects: false,
            validateStatus: (_) => true,
            responseType: ResponseType.plain,
            headers: {
              'Cookie': cookie,
              'Accept': 'text/html, */*; q=0.01',
              'X-Requested-With': 'XMLHttpRequest',
              'Referer': _baseUri.resolve('index_initMenu.html').toString(),
            },
          ));
      _updateCookies(response);
      _requireSessionCookie();
      if (_isRedirect(response.statusCode)) {
        if (redirects >= 5) throw '登录状态验证重定向次数过多';
        uri = _redirectUri(response, uri);
        if (_isLoginOrErrorPage(uri)) {
          throw '登录状态未生效，请检查账号密码或使用网页登录';
        }
        continue;
      }
      if (response.statusCode != 200) {
        throw '登录状态验证失败（HTTP ${response.statusCode}），请重试';
      }
      final body = response.data ?? '';
      final profile = parse(body).querySelector('.media-heading');
      if (isZhengFangLoginForm(body) ||
          profile == null ||
          profile.text.trim().isEmpty) {
        throw '未能确认登录状态，请重试或使用网页登录';
      }
      return;
    }
  }

  bool _isRedirect(int? statusCode) =>
      const [301, 302, 303, 307, 308].contains(statusCode);

  Uri _redirectUri(Response response, Uri origin) {
    final location = response.headers.value('Location');
    if (location == null || location.trim().isEmpty) {
      throw '登录响应未包含重定向地址';
    }
    final destination = origin.resolve(location);
    if (destination.scheme != _baseUri.scheme ||
        destination.host != _baseUri.host ||
        destination.port != _baseUri.port ||
        destination.userInfo.isNotEmpty ||
        !destination.path.startsWith('/jwglxt/')) {
      throw '登录响应包含无效的重定向地址';
    }
    return destination;
  }

  void _updateCookies(Response response) {
    for (final setCookie in response.headers['Set-Cookie'] ?? <String>[]) {
      final parts = setCookie.split(';');
      final pair = parts.first.trim();
      final separator = pair.indexOf('=');
      if (separator < 1) continue;
      final name = pair.substring(0, separator).trim();
      if (name != 'JSESSIONID' && name != 'route') continue;
      final value = pair.substring(separator + 1).trim();
      final deleted = parts.skip(1).any((part) {
        final attribute = part.trim().split('=');
        return attribute.length == 2 &&
            attribute.first.toLowerCase() == 'max-age' &&
            (int.tryParse(attribute.last) ?? 1) <= 0;
      });
      if (value.isEmpty || deleted) {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
  }

  /// 从 html 提取显示的错误信息（e.g. "用户名或密码不正确，请重新输入！"）
  String? _extractErrorMessage(String html) {
    var document = parse(encoding: '', html);
    final element = document.getElementById('tips');
    if (element == null) {
      return null;
    }

    final String result = element.text.trim();
    return result;
  }
}
