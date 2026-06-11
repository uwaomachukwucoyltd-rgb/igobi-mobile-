import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_models.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.message});
  final String? message;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);
  final IgobiUser user;
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

final authApiProvider = Provider<AuthApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  late ApiClient client;
  client = ApiClient(
    baseUrl: ApiConfig.authBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () async {
      // Use a bare Dio for the refresh call so we don't recurse through the
      // 401 interceptor. The HttpOnly refresh cookie is sent automatically by
      // Dio when withCredentials is set — for mobile, cookies are stored by
      // the OS HTTP layer when the response sets Set-Cookie.
      final bare = Dio(BaseOptions(baseUrl: ApiConfig.authBaseUrl))
        ..options.headers['Content-Type'] = 'application/json';
      try {
        final res = await bare.post<dynamic>('/api/v1/auth/refresh');
        final body = res.data;
        if (body is Map<String, dynamic>) {
          final data = body['data'] as Map<String, dynamic>?;
          final token = data?['accessToken'] as String?;
          if (token != null) {
            await storage.saveAccessToken(token);
            return token;
          }
        }
      } catch (_) {
        /* fallthrough — caller will see 401 */
      }
      return null;
    },
  );
  return AuthApi(client);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api, this._storage) : super(const AuthLoading()) {
    _bootstrap();
  }

  final AuthApi _api;
  final TokenStorage _storage;

  Future<void> _bootstrap() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      state = const AuthSignedOut();
      return;
    }
    try {
      final user = await _api.me();
      state = AuthSignedIn(user);
    } on ApiException {
      // Token invalid or refresh failed.
      await _storage.clear();
      state = const AuthSignedOut();
    } on NetworkException {
      // Offline at boot — treat as signed-out so the user can try sign-in.
      state = const AuthSignedOut(message: 'Could not reach IGOBI. Try again.');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final result = await _api.login(email: email, password: password);
      await _storage.saveAccessToken(result.accessToken);
      state = AuthSignedIn(result.user);
    } on ApiException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    } on NetworkException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _api.register(
        email: email,
        password: password,
        displayName: displayName,
        phone: phone,
      );
      await _storage.saveAccessToken(result.accessToken);
      state = AuthSignedIn(result.user);
    } on ApiException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    } on NetworkException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    }
  }

  /// Pick / clear the user's religious org. Updates the in-memory user so
  /// UI bound to the auth state reflects the change immediately.
  Future<void> setReligiousOrg(String? orgId) async {
    final updated = await _api.setReligiousOrg(orgId);
    if (state is AuthSignedIn) {
      state = AuthSignedIn(updated);
    }
  }

  Future<void> signOut() async {
    try {
      await _api.logout();
    } catch (_) {
      /* best-effort — clear locally either way */
    }
    // Also tear down the Firebase + Google session so the user gets the
    // account picker on next sign-in instead of being silently re-signed.
    try {
      await GoogleSignIn().signOut();
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {/* best-effort */}
    await _storage.clear();
    state = const AuthSignedOut();
  }

  /// Google Sign-In via Firebase. Drives:
  ///   1. Google account picker (google_sign_in)
  ///   2. Firebase credential exchange (firebase_auth)
  ///   3. Firebase ID token → our /auth/oauth/google → our JWT
  /// On cancel, state stays as it was; only real failures throw.
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User dismissed the account picker. Restore signed-out without an
        // error message so the screen returns to its normal state.
        state = const AuthSignedOut();
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final fbResult = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await fbResult.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          code: 'AUTH_OAUTH_NO_ID_TOKEN',
          message: 'Could not retrieve a Google sign-in token.',
        );
      }
      final result = await _api.exchangeGoogleIdToken(idToken);
      await _storage.saveAccessToken(result.accessToken);
      state = AuthSignedIn(result.user);
    } on fb.FirebaseAuthException catch (e) {
      state = AuthSignedOut(message: e.message ?? 'Google sign-in failed.');
      rethrow;
    } on ApiException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    } on NetworkException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    }
  }

  /// Sign in with Apple via Firebase. Required for iOS submission per
  /// App Store Review Guideline 4.8.
  ///
  /// Flow:
  ///   1. Generate a random nonce; SHA-256 hash it.
  ///   2. Apple's getAppleIDCredential is called with the *hashed* nonce —
  ///      Apple includes the hashed nonce in its signed identity token.
  ///   3. Firebase OAuthCredential is built from Apple's identity token +
  ///      the *raw* nonce; Firebase compares the hash itself.
  ///   4. Firebase ID token → our /auth/oauth/apple → our JWT.
  ///
  /// The nonce dance is what stops a leaked Apple identity token from being
  /// replayed against Firebase.
  Future<void> signInWithApple() async {
    state = const AuthLoading();
    try {
      final rawNonce = _randomNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      final fbResult =
          await fb.FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Apple only sends fullName on the FIRST sign-in. Patch the Firebase
      // user with the name so the displayName makes it into our /oauth/apple
      // call (Firebase emits it in the verified token's `name` claim).
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().join(' ').trim();
      if (fullName.isNotEmpty && (fbResult.user?.displayName ?? '').isEmpty) {
        try {
          await fbResult.user?.updateDisplayName(fullName);
        } catch (_) {/* best-effort */}
      }

      final idToken = await fbResult.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          code: 'AUTH_OAUTH_NO_ID_TOKEN',
          message: 'Could not retrieve an Apple sign-in token.',
        );
      }
      final result = await _api.exchangeAppleIdToken(idToken);
      await _storage.saveAccessToken(result.accessToken);
      state = AuthSignedIn(result.user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        state = const AuthSignedOut();
        return;
      }
      state = AuthSignedOut(message: e.message);
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      state = AuthSignedOut(message: e.message ?? 'Apple sign-in failed.');
      rethrow;
    } on ApiException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    } on NetworkException catch (e) {
      state = AuthSignedOut(message: e.message);
      rethrow;
    }
  }

  /// 32-character nonce from a cryptographically-secure RNG. Used to bind an
  /// Apple sign-in attempt to this specific app session.
  String _randomNonce([int length = 32]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rnd = Random.secure();
    return List.generate(length, (_) => charset[rnd.nextInt(charset.length)])
        .join();
  }

  /// Irreversible. Server must hard-delete or anonymise inside 30 days
  /// (Apple Guideline 5.1.1(v) + Google Play data-deletion policy).
  Future<void> deleteAccount({required String confirmation}) async {
    await _api.deleteAccount(confirmation: confirmation);
    await _storage.clear();
    state = const AuthSignedOut(message: 'Your account has been deleted.');
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authApiProvider), ref.watch(tokenStorageProvider));
});
