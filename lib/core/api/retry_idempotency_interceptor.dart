import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Two concerns in one interceptor because they belong together:
///
/// 1. **Idempotency-Key** on every non-GET request. Generated per *logical*
///    operation so a retry under network jitter doesn't create a duplicate
///    payment, double-list a product, or fan out two pushes. The header is
///    only set when the caller didn't already supply one — callers can pin
///    their own key (e.g. derived from a cart hash) when they want to.
///
/// 2. **Exponential backoff + jitter retry** on transient failures:
///       - DioExceptionType.connectionError / connectionTimeout / receiveTimeout
///       - HTTP 502 / 503 / 504
///       - HTTP 500 (only when method is GET — POSTs need the idempotency key
///         AND a server that honours it before we can safely retry a 500.)
///    Retries are bounded ([maxRetries]) and capped ([maxBackoff]) so we
///    never re-hit a struggling backend in a tight loop.
///
/// Wire into your Dio instance once at construction:
///   dio.interceptors.add(RetryIdempotencyInterceptor(dio: dio));
class RetryIdempotencyInterceptor extends Interceptor {
  RetryIdempotencyInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseBackoff = const Duration(milliseconds: 200),
    this.maxBackoff = const Duration(seconds: 4),
  });

  final Dio dio;
  final int maxRetries;
  final Duration baseBackoff;
  final Duration maxBackoff;

  static const _retryCountKey = 'x-igobi-retry-count';
  static const _idempotencyHeader = 'Idempotency-Key';

  final Random _rand = Random.secure();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    if (method != 'GET' && !options.headers.containsKey(_idempotencyHeader)) {
      options.headers[_idempotencyHeader] = _newKey();
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_retryCountKey] as int? ?? 0);
    if (attempt >= maxRetries || !_isRetryable(err)) {
      return handler.next(err);
    }

    final delay = _backoff(attempt);
    await Future<void>.delayed(delay);

    final next = err.requestOptions;
    next.extra[_retryCountKey] = attempt + 1;

    try {
      final response = await dio.fetch<dynamic>(next);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _isRetryable(DioException err) {
    final type = err.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final status = err.response?.statusCode;
    final method = err.requestOptions.method.toUpperCase();
    if (status == null) return false;
    if (status == 502 || status == 503 || status == 504) return true;
    // 500 is only retry-safe when the request is naturally idempotent OR the
    // server honours the Idempotency-Key we injected. We let GET retry on
    // 500 (read-only by spec) but hold off on POSTs to avoid duplicating
    // state when an unaware backend processes them twice.
    if (status == 500 && method == 'GET') return true;
    return false;
  }

  Duration _backoff(int attempt) {
    final exp = baseBackoff * (1 << attempt); // 200, 400, 800, ...
    final cap = exp > maxBackoff ? maxBackoff : exp;
    // Full jitter — proven to spread retries better than equal/decorrelated
    // for our scale. See AWS Architecture Blog "Exponential Backoff And
    // Jitter".
    final jitterMs = _rand.nextInt(cap.inMilliseconds + 1);
    return Duration(milliseconds: jitterMs);
  }

  String _newKey() {
    // RFC 4122 v4-ish — sufficient for an idempotency header. We don't need
    // crypto-grade because the server treats the key as opaque and pairs it
    // with the user's session.
    final bytes = List<int>.generate(16, (_) => _rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
