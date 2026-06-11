import '../../../core/api/api_client.dart';
import 'auth_models.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  Future<AuthResult> register({
    required String email,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    final body = await _client.postJson('/api/v1/auth/register', {
      'email': email,
      'password': password,
      if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return AuthResult.fromJson(body);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final body = await _client.postJson('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(body);
  }

  /// Exchange a Firebase Google ID token for our access + refresh tokens.
  /// Called by AuthController.signInWithGoogle after Firebase Auth gives us
  /// the ID token.
  Future<AuthResult> exchangeGoogleIdToken(String idToken) async {
    final body = await _client.postJson('/api/v1/auth/oauth/google', {
      'idToken': idToken,
    });
    return AuthResult.fromJson(body);
  }

  /// Apple equivalent. Mirrors the Google flow.
  Future<AuthResult> exchangeAppleIdToken(String idToken) async {
    final body = await _client.postJson('/api/v1/auth/oauth/apple', {
      'idToken': idToken,
    });
    return AuthResult.fromJson(body);
  }

  Future<String?> refresh() async {
    final body = await _client.postJson('/api/v1/auth/refresh', const {});
    final data = body['data'] as Map<String, dynamic>?;
    return data?['accessToken'] as String?;
  }

  Future<void> logout() => _client.postVoid('/api/v1/auth/logout');

  Future<IgobiUser> me() async {
    final body = await _client.getJson('/api/v1/users/me');
    final data = body['data'] as Map<String, dynamic>;
    return IgobiUser.fromJson(data);
  }

  /// Set / clear the user's selected religious organisation. Pass null to
  /// clear. Server validates the org id against vendor-service.
  Future<IgobiUser> setReligiousOrg(String? orgId) async {
    final body = await _client.postJson(
      '/api/v1/users/me/religious-org',
      {'orgId': orgId},
    );
    final data = body['data'] as Map<String, dynamic>;
    return IgobiUser.fromJson(data);
  }

  /// Apple Guideline 5.1.1(v) — irreversible account deletion. The backend
  /// must hard-delete or anonymise within 30 days.
  Future<void> deleteAccount({required String confirmation}) async {
    await _client.postJson('/api/v1/auth/account/delete', {
      'confirmation': confirmation,
    });
  }
}
