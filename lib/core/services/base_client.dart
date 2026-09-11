import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_constants.dart';

/// Persists the Traccar session cookie to disk so a login survives app
/// restarts — Traccar has no JWT/bearer token, the cookie *is* the session.
final cookieJarProvider = Provider<CookieJar>((ref) {
  throw UnimplementedError(
    'cookieJarProvider must be overridden in main.dart with '
    'initCookieJar() before the app starts.',
  );
});

Future<PersistCookieJar> initCookieJar() async {
  final dir = await getApplicationDocumentsDirectory();
  return PersistCookieJar(storage: FileStorage('${dir.path}/.cookies/'));
}

/// Shared Dio instance for the Traccar backend — every authenticated
/// request (and the WebSocket handshake, via [cookieJarProvider]) relies
/// on the [CookieManager] interceptor below to carry the session cookie.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl:        ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout:    ApiConstants.sendTimeout,
      headers: {
        'Accept':       ApiConstants.contentTypeJson,
        'Content-Type': ApiConstants.contentTypeJson,
      },
    ),
  );
  dio.interceptors.add(CookieManager(ref.watch(cookieJarProvider)));
  return dio;
});
