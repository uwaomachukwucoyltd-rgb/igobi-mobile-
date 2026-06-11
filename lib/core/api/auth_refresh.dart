import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';

/// Silent JWT refresh. Every ApiClient that wants 401-recovery passes
/// `refreshAccessToken(storage)` as its `onUnauthorized` callback. Concurrent
/// callers are serialised so 10 parallel 401s trigger ONE refresh call and
/// all share the same result. If the refresh itself fails we clear local
/// tokens — the caller's 401 then propagates and the auth controller can
/// route to /welcome.
Future<String?> refreshAccessToken(TokenStorage storage) {
  // If a refresh is already in flight, piggyback on it.
  if (_inflight != null) return _inflight!.future;

  final completer = Completer<String?>();
  _inflight = completer;

  _doRefresh(storage).then((token) {
    completer.complete(token);
  }).catchError((Object e, StackTrace st) {
    completer.complete(null);
  }).whenComplete(() {
    _inflight = null;
  });

  return completer.future;
}

Completer<String?>? _inflight;

Future<String?> _doRefresh(TokenStorage storage) async {
  // Use a bare Dio so we don't recurse through the 401 interceptor.
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.authBaseUrl,
    headers: {'Content-Type': 'application/json'},
    // 4xx becomes a normal response so we can inspect it; 5xx still throws.
    validateStatus: (s) => s != null && s < 500,
  ));

  final res = await dio.post<dynamic>('/api/v1/auth/refresh').catchError(
    (Object e, StackTrace st) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
      statusCode: 0,
    ),
  );

  if (res.statusCode != null && res.statusCode! >= 400) {
    // Refresh itself failed → wipe local session.
    await storage.clear();
    return null;
  }

  final body = res.data;
  if (body is Map<String, dynamic>) {
    final data = body['data'] as Map<String, dynamic>?;
    final token = data?['accessToken'] as String?;
    if (token != null && token.isNotEmpty) {
      await storage.saveAccessToken(token);
      return token;
    }
  }
  await storage.clear();
  return null;
}
