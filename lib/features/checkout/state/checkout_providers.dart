import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../../cart/cart_controller.dart';
import '../data/checkout_quote_api.dart';
import '../data/checkout_quote_models.dart';
import '../data/escrow_api.dart';
import '../data/payment_api.dart';

final paymentApiProvider = Provider<PaymentApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.paymentBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return PaymentApi(client);
});

final escrowApiProvider = Provider<EscrowApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.escrowBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return EscrowApi(client);
});

/// `/checkout/quote` lives in payment-service, so it shares paymentBaseUrl.
final checkoutQuoteApiProvider = Provider<CheckoutQuoteApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.paymentBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return CheckoutQuoteApi(client);
});

/// Live quote for the current cart. Returns null when the cart is empty,
/// has mixed product types (service vs physical), or spans multiple fee
/// categories — those are all UI-blockable states.
///
/// Re-runs automatically when the cart changes (because of `ref.watch`),
/// so the receipt the customer sees on the cart sheet always reflects what
/// they'll actually pay.
final cartQuoteProvider = FutureProvider<CheckoutQuote?>((ref) async {
  final cart = ref.watch(cartControllerProvider);
  if (cart.isEmpty || cart.isMixedTypes || cart.isMixedFeeCategories) {
    return null;
  }
  final api = ref.watch(checkoutQuoteApiProvider);
  return api.quote(
    category: cart.feeCategory!,
    subtotalMinor: cart.totalNgn * 100, // NGN -> kobo
  );
});
