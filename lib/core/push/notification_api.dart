import '../api/api_client.dart';

class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  Future<void> registerDevice({
    required String platform, // 'ANDROID' | 'IOS' | 'WEB'
    required String token,
    String? appVersion,
  }) async {
    await _client.postJson('/api/v1/devices', {
      'platform': platform,
      'token': token,
      if (appVersion != null) 'appVersion': appVersion,
    });
  }

  Future<void> unregisterDevice(String token) async {
    await _client.deleteVoid('/api/v1/devices/${Uri.encodeComponent(token)}');
  }
}
