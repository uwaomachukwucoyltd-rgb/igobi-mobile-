import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'retry_idempotency_interceptor.dart';

typedef RefreshAccessToken = Future<String?> Function();

/// Wraps Dio with three concerns:
///   1. Injects the bearer access token on every request.
///   2. On 401, calls [onUnauthorized] once (e.g. /auth/refresh) and retries.
///   3. Normalises server error envelopes into [ApiException].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    this.onUnauthorized,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
            sendTimeout: const Duration(seconds: 8),
            headers: {'Content-Type': 'application/json'},
            // Treat 4xx as resolved so we can transform into ApiException ourselves;
            // 5xx propagates as DioException for the network layer to surface.
            validateStatus: (status) => status != null && status < 500,
          ),
        ) {
    // Order matters. Auth runs FIRST so refreshed tokens are attached before
    // retries fire; retry runs SECOND so it sees the auth-injected headers
    // and re-issues with the same token.
    dio.interceptors.add(_AuthInterceptor(this));
    dio.interceptors.add(RetryIdempotencyInterceptor(dio: dio));
  }

  final String baseUrl;
  final TokenStorage tokenStorage;
  final RefreshAccessToken? onUnauthorized;
  final Dio dio;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final res = await _safe(() => dio.post<dynamic>(path, data: body, options: Options(headers: headers)));
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _safe(() => dio.get<dynamic>(path));
    return _unwrap(res);
  }

  Future<void> postVoid(String path) async {
    final res = await _safe(() => dio.post<dynamic>(path));
    if (res.statusCode != null && res.statusCode! >= 400) _throwFromBody(res.data, res.statusCode);
  }

  Future<void> deleteVoid(String path) async {
    final res = await _safe(() => dio.delete<dynamic>(path));
    if (res.statusCode != null && res.statusCode! >= 400) {
      _throwFromBody(res.data, res.statusCode);
    }
  }

  Future<Response<dynamic>> _safe(Future<Response<dynamic>> Function() send) async {
    try {
      return await send();
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  Map<String, dynamic> _unwrap(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    final body = res.data;
    if (status >= 400) _throwFromBody(body, status);
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('Unexpected response shape');
  }

  Never _throwFromBody(dynamic body, int? status) {
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final err = body['error'] as Map<String, dynamic>;
      throw ApiException(
        code: (err['code'] ?? 'UNKNOWN').toString(),
        message: (err['message'] ?? 'Unknown error').toString(),
        status: status,
      );
    }
    if (body is Map<String, dynamic> && body['message'] is String) {
      // NestJS default error shape: { statusCode, message, error }
      throw ApiException(
        code: status == 401 ? 'AUTH_INVALID_TOKEN' : 'HTTP_$status',
        message: body['message'] as String,
        status: status,
      );
    }
    throw ApiException(code: 'HTTP_$status', message: 'Request failed.', status: status);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.client);
  final ApiClient client;

  bool _refreshing = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await client.tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 401 && !_refreshing && client.onUnauthorized != null) {
      _refreshing = true;
      try {
        final fresh = await client.onUnauthorized!.call();
        if (fresh != null && fresh.isNotEmpty) {
          response.requestOptions.headers['Authorization'] = 'Bearer $fresh';
          final retry = await client.dio.fetch<dynamic>(response.requestOptions);
          handler.resolve(retry);
          return;
        }
      } catch (_) {
        /* fall through to original 401 */
      } finally {
        _refreshing = false;
      }
    }
    handler.next(response);
  }
}
