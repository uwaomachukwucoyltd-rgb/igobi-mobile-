import '../../../core/api/api_client.dart';
import 'checkout_quote_models.dart';

class CheckoutQuoteApi {
  CheckoutQuoteApi(this._client);
  final ApiClient _client;

  /// Quote a checkout before opening Flutterwave. Pure server-side
  /// calculation; safe to call repeatedly as the cart changes.
  Future<CheckoutQuote> quote({
    required FeeCategory category,
    required int subtotalMinor,
    bool? isLargeCylinder,
    int? transportMinor,
  }) async {
    final json = await _client.postJson('/api/v1/checkout/quote', {
      'category': feeCategoryToWire(category),
      'subtotalMinor': subtotalMinor,
      if (isLargeCylinder != null) 'isLargeCylinder': isLargeCylinder,
      if (transportMinor != null) 'transportMinor': transportMinor,
    });
    return CheckoutQuote.fromJson(json);
  }
}
