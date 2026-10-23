import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;

/// The server can answer an expired API request with an HTTP-200 login form.
/// Academic empty pages and JSON responses must not be mistaken for expiry.
bool isZhengFangLoginForm(Object? body) {
  if (body is! String || !body.toLowerCase().contains('<form')) return false;
  final document = html.parse(body);
  return document.querySelectorAll('form').any((form) =>
      form.querySelector('input#yhm, input[name="yhm"]') != null &&
      form.querySelector('input#mm, input[name="mm"]') != null);
}

/// Keep redirects visible to the shared session-recovery path. Dio does not
/// retain Set-Cookie automatically when it follows a login redirect itself.
Dio createZhengFangDio([BaseOptions? options]) {
  final dio = Dio(options ?? BaseOptions());
  dio.options.followRedirects = false;
  dio.options.validateStatus = (_) => true;
  dio.options.connectTimeout ??= const Duration(seconds: 10);
  dio.options.sendTimeout ??= const Duration(seconds: 10);
  dio.options.receiveTimeout ??= const Duration(seconds: 15);
  dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
    // dart:io handles gzip, but these fetchers used to advertise br/zstd too.
    request.headers
        .removeWhere((name, _) => name.toLowerCase() == 'accept-encoding');
    request.headers['Accept-Encoding'] = 'gzip';
    handler.next(request);
  }, onResponse: (response, handler) {
    if (response.statusCode == 401 ||
        (response.statusCode == 200 && isZhengFangLoginForm(response.data))) {
      // Existing fetchers already surface status 901 as an expired session.
      response.statusCode = 901;
    }
    handler.next(response);
  }));
  return dio;
}
