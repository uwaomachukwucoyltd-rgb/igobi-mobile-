import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Background isolate handler. Must be a top-level function — Flutter spawns a
/// fresh isolate to run this when the app is terminated. No widget tree, no
/// Riverpod here. Do the minimum: log, optionally pre-fetch.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler intentionally minimal — surfacing the notification is
  // handled by the OS via the `notification` field on the payload.
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
}

/// Thin wrapper around firebase_messaging. Designed to fail soft: if Firebase
/// isn't configured (no google-services.json / GoogleService-Info.plist),
/// [init] logs and returns instead of crashing the app boot. Callers should
/// treat push as a best-effort enhancement, not a required dependency.
class PushService {
  PushService._();

  static const _tokenKey = 'fcm_token';
  static const _storage = FlutterSecureStorage();
  static bool _initialized = false;

  /// Call from main() AFTER WidgetsFlutterBinding.ensureInitialized().
  /// Wraps Firebase.initializeApp in try/catch so a missing config file does
  /// not stop the app from booting — push just silently disables.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      // No options arg: Firebase loads from google-services.json (Android)
      // and GoogleService-Info.plist (iOS). flutterfire configure also
      // generates a lib/firebase_options.dart that you can pass here for
      // tighter control — see FCM_SETUP.md.
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Push disabled — Firebase not initialised: $e');
      }
    }
  }

  static bool get isAvailable => _initialized;

  /// Ask the user for notification permission. Call this AFTER sign-in, not at
  /// first launch — Apple penalises apps that ask for everything up-front, and
  /// users grant push more readily once they understand what they'll receive.
  /// Returns true if the user granted (provisional or full).
  static Future<bool> requestPermission() async {
    if (!_initialized) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Fetch the current FCM token and persist it. Returns null if push isn't
  /// available or the platform returned no token (simulator with no APNs, for
  /// example).
  static Future<String?> getAndStoreToken() async {
    if (!_initialized) return null;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _storage.write(key: _tokenKey, value: token);
    }
    return token;
  }

  /// Persisted token, if we ever fetched one.
  static Future<String?> cachedToken() => _storage.read(key: _tokenKey);

  /// Emits new tokens as the OS rotates them. Caller is responsible for
  /// re-registering with notification-service when this fires.
  static Stream<String> onTokenRefresh() {
    if (!_initialized) return const Stream.empty();
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  /// Stream of foreground notification payloads. The OS does NOT surface a
  /// banner for foreground messages on Android — render an in-app toast or
  /// snackbar when these fire. iOS shows a banner if the payload has
  /// `notification` AND you set the foreground presentation options below.
  static Stream<RemoteMessage> onForegroundMessage() {
    if (!_initialized) return const Stream.empty();
    return FirebaseMessaging.onMessage;
  }

  /// Stream of taps on a notification that opened the app (background or
  /// terminated launch). Route to the relevant in-app screen from here.
  static Stream<RemoteMessage> onMessageOpenedApp() {
    if (!_initialized) return const Stream.empty();
    return FirebaseMessaging.onMessageOpenedApp;
  }

  /// If the app was launched by tapping a notification while terminated, this
  /// returns that message. Resolves to null on a regular launch.
  static Future<RemoteMessage?> getInitialMessage() async {
    if (!_initialized) return null;
    return FirebaseMessaging.instance.getInitialMessage();
  }
}
