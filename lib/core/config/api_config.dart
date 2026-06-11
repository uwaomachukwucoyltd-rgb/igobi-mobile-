import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Base URL resolution for backend services.
///
/// Resolution order:
///   1. Explicit `--dart-define=AUTH_BASE_URL=...` (always wins — production
///      builds set this to the deployed HTTPS endpoint).
///   2. **Release mode** with no override → defaults to `_prodAuth`,
///      `_prodPayment`, `_prodEscrow`. These MUST be HTTPS.
///   3. **Debug mode** with no override → resolves to localhost on native /
///      `Uri.base.host` on web (so a phone on Wi-Fi auto-uses the LAN IP).
///
/// Build the release like:
///   flutter build appbundle --release \
///     --dart-define=AUTH_BASE_URL=https://api.igobi.app \
///     --dart-define=PAYMENT_BASE_URL=https://api.igobi.app \
///     --dart-define=ESCROW_BASE_URL=https://api.igobi.app
class ApiConfig {
  ApiConfig._();

  // Production defaults. CHANGE these to your real HTTPS host before shipping
  // a release build. Anything served over http:// will fail at runtime on
  // release builds because cleartext traffic is disabled in the platform
  // manifests.
  // Live Render service URLs (verified reachable, /health/live → 200). When
  // branded custom domains (auth.igobi.app, etc.) are later attached in Render
  // + DNS, swap these back — or override per build with --dart-define.
  static const String _prodAuth = 'https://igobi-auth.onrender.com';
  static const String _prodPayment = 'https://igobi-payment.onrender.com';
  static const String _prodEscrow = 'https://igobi-escrow.onrender.com';
  static const String _prodVendor = 'https://igobi-vendor.onrender.com';
  static const String _prodNotification = 'https://igobi-notification.onrender.com';

  static const String _authOverride =
      String.fromEnvironment('AUTH_BASE_URL');
  static const String _paymentOverride =
      String.fromEnvironment('PAYMENT_BASE_URL');
  static const String _escrowOverride =
      String.fromEnvironment('ESCROW_BASE_URL');
  static const String _vendorOverride =
      String.fromEnvironment('VENDOR_BASE_URL');
  static const String _notificationOverride =
      String.fromEnvironment('NOTIFICATION_BASE_URL');

  static String get authBaseUrl =>
      _resolve(_authOverride, _prodAuth, 3001);

  static String get paymentBaseUrl =>
      _resolve(_paymentOverride, _prodPayment, 3002);

  static String get escrowBaseUrl =>
      _resolve(_escrowOverride, _prodEscrow, 3003);

  static String get vendorBaseUrl =>
      _resolve(_vendorOverride, _prodVendor, 3004);

  static String get notificationBaseUrl =>
      _resolve(_notificationOverride, _prodNotification, 3005);

  /// True when the URLs being used are production HTTPS endpoints. Useful for
  /// gating debug-only UI (banners, demo creds).
  static bool get isProduction {
    if (_authOverride.isNotEmpty) {
      return _authOverride.startsWith('https://');
    }
    return kReleaseMode;
  }

  static String _resolve(String fromEnv, String prodDefault, int devPort) {
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kReleaseMode) {
      // Release without an override → always production HTTPS. Cleartext is
      // blocked in AndroidManifest / Info.plist, so localhost would not work
      // anyway.
      return prodDefault;
    }

    // Debug / profile build.
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:$devPort';
    }
    if (Platform.isAndroid) {
      // Android emulator routes its own loopback through 10.0.2.2.
      return 'http://10.0.2.2:$devPort';
    }
    return 'http://localhost:$devPort';
  }
}
