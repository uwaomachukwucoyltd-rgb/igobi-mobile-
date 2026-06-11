import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../state/fmcg_state.dart';

/// Online brand-direct FMCG storefronts + their catalogues, from vendor-service.
class FmcgApi {
  FmcgApi(this._client);

  final ApiClient _client;

  Future<List<FMCGVendor>> fetchNodes() async {
    final json = await _client.getJson('/api/v1/fmcg/vendors');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FMCGVendor.fromJson).toList(growable: false);
  }

  Future<List<FMCGItem>> fetchInventory(String vendorId) async {
    final json =
        await _client.getJson('/api/v1/fmcg/vendors/$vendorId/items');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(FMCGItem.fromJson).toList(growable: false);
  }
}

final fmcgApiProvider = Provider<FmcgApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return FmcgApi(client);
});

/// All verified FMCG brand storefronts. Used by the FMCG list screen.
final fmcgVendorsProvider = FutureProvider<List<FMCGVendor>>((ref) async {
  final api = ref.watch(fmcgApiProvider);
  return api.fetchNodes();
});

/// Catalogue items for one brand. Used by the FMCG detail screen.
final fmcgInventoryProvider =
    FutureProvider.family<List<FMCGItem>, String>((ref, vendorId) async {
  final api = ref.watch(fmcgApiProvider);
  return api.fetchInventory(vendorId);
});
