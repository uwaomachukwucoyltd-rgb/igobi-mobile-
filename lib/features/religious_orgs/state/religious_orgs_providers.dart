import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../data/religious_orgs_api.dart';

final religiousOrgsApiProvider = Provider<ReligiousOrgsApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return ReligiousOrgsApi(client);
});

/// Free-text search results. Family on the query string; null/empty returns
/// the default top-of-list (verified, then highest follower count).
final religiousOrgsSearchProvider =
    FutureProvider.family<List<ReligiousOrg>, String>((ref, query) async {
  final api = ref.watch(religiousOrgsApiProvider);
  return api.search(query: query.isEmpty ? null : query, limit: 40);
});

/// Single org by id — used to render the user's currently-selected org in
/// the profile without re-fetching the full list.
final religiousOrgByIdProvider =
    FutureProvider.family<ReligiousOrg, String>((ref, id) async {
  final api = ref.watch(religiousOrgsApiProvider);
  return api.getByAnyKey(id);
});
