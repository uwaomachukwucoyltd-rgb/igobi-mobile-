import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../data/marketplace_api.dart';
import '../marketplace_data.dart';

final marketplaceApiProvider = Provider<MarketplaceApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return MarketplaceApi(client);
});

/// All ACTIVE vendors, ranked verified-first by trust score. Used by the
/// marketplace home carousel.
final featuredVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final api = ref.watch(marketplaceApiProvider);
  return api.listVendors(verifiedOnly: true, limit: 20);
});

/// All in-stock products. The marketplace screen does its own client-side
/// category + search filtering on this list.
final trendingProductsProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.watch(marketplaceApiProvider);
  return api.listProducts(limit: 100);
});

/// Single vendor by id or slug. Used by vendor_detail_screen.
final vendorByIdProvider =
    FutureProvider.family<Vendor, String>((ref, idOrSlug) async {
  final api = ref.watch(marketplaceApiProvider);
  return api.getVendor(idOrSlug);
});

/// Products for a vendor. Used by vendor_detail_screen.
final productsByVendorProvider =
    FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  final api = ref.watch(marketplaceApiProvider);
  return api.listProducts(vendorId: vendorId, limit: 100);
});
