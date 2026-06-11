import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/auth_refresh.dart';
import '../config/api_config.dart';
import '../../features/auth/state/auth_controller.dart';
import 'notification_api.dart';
import 'push_service.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.notificationBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return NotificationApi(client);
});

/// Side-effect controller: after the user signs in for the first time this
/// session, ask for notification permission, fetch the FCM token, and
/// register it with notification-service. Also subscribes to token-refresh
/// so OS-initiated rotations re-register automatically.
///
/// Safe to call multiple times — `_registered` short-circuits the second
/// call within the same session. Sign-out resets the flag.
class DeviceRegistrationController {
  DeviceRegistrationController(this._api);

  final NotificationApi _api;
  bool _registered = false;
  StreamSubscription<String>? _refreshSub;

  Future<void> registerOnSignIn() async {
    if (_registered) return;
    _registered = true;

    if (!PushService.isAvailable) return;

    final granted = await PushService.requestPermission();
    if (!granted) return;

    final token = await PushService.getAndStoreToken();
    if (token == null) return;

    await _postToken(token);

    _refreshSub?.cancel();
    _refreshSub = PushService.onTokenRefresh().listen(_postToken);
  }

  Future<void> _postToken(String token) async {
    try {
      await _api.registerDevice(platform: _platform(), token: token);
    } catch (e) {
      if (kDebugMode) debugPrint('Device registration failed: $e');
    }
  }

  Future<void> reset() async {
    _registered = false;
    await _refreshSub?.cancel();
    _refreshSub = null;
  }

  String _platform() {
    if (kIsWeb) return 'WEB';
    if (defaultTargetPlatform == TargetPlatform.android) return 'ANDROID';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'IOS';
    return 'WEB';
  }
}

final deviceRegistrationProvider = Provider<DeviceRegistrationController>((ref) {
  final api = ref.watch(notificationApiProvider);
  return DeviceRegistrationController(api);
});
