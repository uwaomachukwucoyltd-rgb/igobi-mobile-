/// Server error envelope translated into a Dart exception. The service contract
/// (see docs/api/conventions.md) guarantees `code` + `message`.
class ApiException implements Exception {
  ApiException({required this.code, required this.message, this.status});

  final String code;
  final String message;
  final int? status;

  @override
  String toString() => 'ApiException($code): $message';
}

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}
