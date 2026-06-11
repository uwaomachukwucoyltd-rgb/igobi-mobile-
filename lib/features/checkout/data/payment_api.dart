import '../../../core/api/api_client.dart';
import 'payment_models.dart';

class PaymentApi {
  PaymentApi(this._client);

  final ApiClient _client;

  Future<PaymentResponse> create({
    required int amountMinor,
    required String currency,
    required String customerEmail,
    String? description,
    String? callbackUrl,
    String? idempotencyKey,
    /// Free-form metadata stored on the Payment row. payment-service reads
    /// `metadata.productType` and `metadata.vendorId` from here to decide
    /// whether to credit the vendor's wallet on SUCCESS.
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'gateway': 'FLUTTERWAVE',
      'amountMinor': amountMinor,
      'currency': currency,
      'customerEmail': customerEmail,
      if (description != null) 'description': description,
      if (callbackUrl != null) 'callbackUrl': callbackUrl,
      if (metadata != null) 'metadata': metadata,
    };
    final json = await _client.postJson(
      '/api/v1/payments',
      body,
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
    return PaymentResponse.fromJson(json);
  }

  /// Creates an Order on payment-service AND auto-initialises a Payment for
  /// it. Use this for PHYSICAL-product carts so the order appears on the
  /// vendor's Orders screen the instant payment lands. Returns a response
  /// shaped like a Payment (so existing checkout-webview flow keeps working),
  /// with `id` set to the payment id and `authorizationUrl` to the gateway
  /// redirect.
  Future<PaymentResponse> createOrder({
    required String vendorId,
    required List<Map<String, dynamic>> items, // [{productId, name, qty, unitPriceMinor}]
    String? description,
    String? callbackUrl,
    Map<String, dynamic>? deliveryAddress,
  }) async {
    final body = <String, dynamic>{
      'vendorId': vendorId,
      'gateway': 'FLUTTERWAVE',
      'currency': 'NGN',
      'items': items,
      if (description != null) 'description': description,
      if (callbackUrl != null) 'callbackUrl': callbackUrl,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
    };
    final json = await _client.postJson('/api/v1/orders', body);
    // payment-service returns { data: OrderResponse } where OrderResponse has
    // paymentId + paymentAuthorizationUrl. Reshape to PaymentResponse for the
    // existing checkout flow.
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return PaymentResponse.fromJson({
      'data': {
        'id': data['paymentId'] ?? data['id'],
        'reference': data['paymentReference'] ?? '',
        'gateway': 'FLUTTERWAVE',
        'status': 'PENDING',
        'amountMinor': data['totalMinor'],
        'currency': data['currency'] ?? 'NGN',
        'authorizationUrl': data['paymentAuthorizationUrl'],
        'createdAt': data['createdAt'],
      },
    });
  }

  Future<PaymentResponse> verify(String paymentId) async {
    final json = await _client.postJson('/api/v1/payments/$paymentId/verify', const {});
    return PaymentResponse.fromJson(json);
  }

  /// Caller's own payments, newest first. Used by the mobile Orders screen
  /// to render physical-product purchases alongside service escrows.
  Future<List<PaymentResponse>> listMine({int limit = 50}) async {
    final json = await _client.getJson('/api/v1/payments?limit=$limit');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data
        .map((m) => PaymentResponse.fromJson({'data': m}))
        .toList(growable: false);
  }
}
