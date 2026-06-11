import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../state/errand_state.dart';

/// Thin data layer for the community / errands hub. Talks to vendor-service
/// under /api/v1/errands with the authed [ApiClient].
class ErrandsApi {
  ErrandsApi(this._client);

  final ApiClient _client;

  Future<List<Errand>> listErrands() async {
    final json = await _client.getJson('/api/v1/errands');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Errand.fromJson).toList(growable: false);
  }

  Future<Errand> getErrand(String id) async {
    final json = await _client.getJson('/api/v1/errands/$id');
    return Errand.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Errand> createErrand({
    required List<String> items,
    required String recipientName,
    required String recipientAddress,
    int? maxBudgetNgn,
  }) async {
    final json = await _client.postJson('/api/v1/errands', {
      'items': items,
      'recipientName': recipientName,
      'recipientAddress': recipientAddress,
      if (maxBudgetNgn != null) 'maxBudgetNgn': maxBudgetNgn,
    });
    return Errand.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Errand> acceptBid(String errandId, String bidId) =>
      _mutate('/api/v1/errands/$errandId/accept-bid', errandId, {'bidId': bidId});

  Future<Errand> deliver(String errandId) =>
      _mutate('/api/v1/errands/$errandId/deliver', errandId, const {});

  Future<Errand> confirmReceipt(String errandId) =>
      _mutate('/api/v1/errands/$errandId/confirm-receipt', errandId, const {});

  Future<Errand> cancel(String errandId) =>
      _mutate('/api/v1/errands/$errandId/cancel', errandId, const {});

  /// POSTs an action, then returns the updated errand. If the endpoint echoes a
  /// full errand in `data` we use it directly; otherwise we re-fetch by id.
  Future<Errand> _mutate(
    String path,
    String errandId,
    Map<String, dynamic> body,
  ) async {
    final json = await _client.postJson(path, body);
    final data = json['data'];
    if (data is Map<String, dynamic> && data['status'] != null) {
      return Errand.fromJson(data);
    }
    return getErrand(errandId);
  }
}

final errandsApiProvider = Provider<ErrandsApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return ErrandsApi(client);
});
