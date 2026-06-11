import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../state/store_state.dart';

/// Physical convenience-store nodes + their per-store inventory, from
/// vendor-service. A buyer inside a store only sees that store's stock.
class StoreApi {
  StoreApi(this._client);

  final ApiClient _client;

  Future<List<StoreNode>> fetchNodes() async {
    final json = await _client.getJson('/api/v1/convenience/stores');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(StoreNode.fromJson).toList(growable: false);
  }

  Future<List<StoreProduct>> fetchInventory(String storeId) async {
    final json = await _client
        .getJson('/api/v1/convenience/stores/$storeId/inventory');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(StoreProduct.fromJson).toList(growable: false);
  }
}

final storeApiProvider = Provider<StoreApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return StoreApi(client);
});

/// All verified convenience-store nodes. Used by the Convenience list screen.
final storeNodesProvider = FutureProvider<List<StoreNode>>((ref) async {
  final api = ref.watch(storeApiProvider);
  return api.fetchNodes();
});

/// Inventory for one store. Used by the store detail screen.
final storeInventoryProvider =
    FutureProvider.family<List<StoreProduct>, String>((ref, storeId) async {
  final api = ref.watch(storeApiProvider);
  return api.fetchInventory(storeId);
});
