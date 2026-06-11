import '../../../core/api/api_client.dart';
import 'escrow_models.dart';

class EscrowApi {
  EscrowApi(this._client);

  final ApiClient _client;

  Future<EscrowResponse> create({
    required String vendorId,
    required int amountMinor,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final json = await _client.postJson('/api/v1/escrows', {
      'vendorId': vendorId,
      'amountMinor': amountMinor,
      'currency': currency,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
    });
    return EscrowResponse.fromJson(json);
  }

  Future<EscrowResponse> fund({
    required String escrowId,
    required String paymentId,
    required String paymentReference,
  }) async {
    final json = await _client.postJson('/api/v1/escrows/$escrowId/fund', {
      'paymentId': paymentId,
      'paymentReference': paymentReference,
    });
    return EscrowResponse.fromJson(json);
  }

  /// Caller's escrows (as buyer or vendor), newest first. Used by the mobile
  /// Orders screen for service-flow line items.
  Future<List<EscrowResponse>> listMine() async {
    final json = await _client.getJson('/api/v1/escrows');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data
        .map((m) => EscrowResponse.fromJson({'data': m}))
        .toList(growable: false);
  }
}
