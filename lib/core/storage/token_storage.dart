import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access token is kept in secure storage (Keychain / Keystore). The refresh
/// token lives in an HttpOnly cookie set by auth-service — we never see it.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'igobi.auth.accessToken';

  Future<void> saveAccessToken(String token) => _storage.write(key: _accessKey, value: token);
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<void> clear() => _storage.delete(key: _accessKey);
}
