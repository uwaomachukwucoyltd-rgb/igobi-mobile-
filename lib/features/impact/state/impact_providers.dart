import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../data/impact_api.dart';

final impactApiProvider = Provider<ImpactApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  // Ledger endpoints live in payment-service.
  final client = ApiClient(
    baseUrl: ApiConfig.paymentBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return ImpactApi(client);
});

final impactSummaryProvider = FutureProvider<ImpactSummary>((ref) async {
  return ref.watch(impactApiProvider).mySummary();
});

final impactDonationsProvider = FutureProvider<List<ImpactDonation>>((ref) async {
  return ref.watch(impactApiProvider).recentDonations();
});
