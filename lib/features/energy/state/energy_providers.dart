import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../data/energy_api.dart';

final energyApiProvider = Provider<EnergyApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return EnergyApi(client);
});

/// Fuel products with live per-unit pricing from the vendor-service catalog.
final energyProductsProvider = FutureProvider<List<EnergyProduct>>((ref) async {
  final api = ref.watch(energyApiProvider);
  return api.listProducts();
});
