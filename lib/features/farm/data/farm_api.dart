import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../state/farm_state.dart';

/// Direct-to-farm sourcing nodes + per-node inventory, served by vendor-service.
class FarmApi {
  FarmApi(this._client);

  final ApiClient _client;

  Future<List<FarmNode>> fetchNodes() async {
    final json = await _client.getJson('/api/v1/farm/nodes');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FarmNode.fromJson).toList(growable: false);
  }

  Future<List<FarmProduct>> fetchInventory(String nodeId) async {
    final json = await _client.getJson('/api/v1/farm/nodes/$nodeId/inventory');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FarmProduct.fromJson).toList(growable: false);
  }
}

final farmApiProvider = Provider<FarmApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return FarmApi(client);
});

/// All verified farm clusters. Used by the Farm Harvest list screen.
final farmNodesProvider = FutureProvider<List<FarmNode>>((ref) async {
  final api = ref.watch(farmApiProvider);
  return api.fetchNodes();
});

/// Batch-tracked produce for one cluster. Used by the farm detail screen.
final farmInventoryProvider =
    FutureProvider.family<List<FarmProduct>, String>((ref, nodeId) async {
  final api = ref.watch(farmApiProvider);
  return api.fetchInventory(nodeId);
});
