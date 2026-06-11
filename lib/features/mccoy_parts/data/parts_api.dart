import '../../../core/api/api_client.dart';
import '../state/parts_state.dart';

/// Authed data source for the McCoy Auto Parts hub. Mirrors the marketplace
/// API pattern: wraps an [ApiClient] and unwraps `{data: ...}` envelopes.
class PartsApi {
  PartsApi(this._client);

  final ApiClient _client;

  Future<List<PartRequest>> list() async {
    final json = await _client.getJson('/api/v1/parts');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(PartRequest.fromJson).toList(growable: false);
  }

  Future<PartRequest> get(String id) async {
    final json = await _client.getJson('/api/v1/parts/$id');
    return PartRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PartRequest> create({
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String partName,
    required String notes,
    required String deliverTo,
    int? budgetNgn,
  }) async {
    final json = await _client.postJson('/api/v1/parts', {
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'partName': partName,
      'notes': notes,
      'deliverTo': deliverTo,
      if (budgetNgn != null) 'budgetNgn': budgetNgn,
    });
    return PartRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PartRequest> acceptBid(String id, String bidId) async {
    final json = await _client.postJson('/api/v1/parts/$id/accept-bid', {
      'bidId': bidId,
    });
    return PartRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PartRequest> verifyFitment(String id) async {
    final json =
        await _client.postJson('/api/v1/parts/$id/verify-fitment', const {});
    return PartRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PartRequest> confirmReceipt(String id) async {
    final json =
        await _client.postJson('/api/v1/parts/$id/confirm-receipt', const {});
    return PartRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PartRequest> cancel(String id) async {
    final json = await _client.postJson('/api/v1/parts/$id/cancel', const {});
    return PartRequest.fromJson(json['data'] as Map<String, dynamic>);
  }
}
