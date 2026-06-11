import '../../../core/api/api_client.dart';
import '../state/mechanic_state.dart';

/// Authed data source for the McCoy Mechanic hub. Mirrors the marketplace
/// API pattern: wraps an [ApiClient] and unwraps `{data: ...}` envelopes.
class MechanicApi {
  MechanicApi(this._client);

  final ApiClient _client;

  Future<List<MechRequest>> list() async {
    final json = await _client.getJson('/api/v1/mechanics');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(MechRequest.fromJson).toList(growable: false);
  }

  Future<MechRequest> get(String id) async {
    final json = await _client.getJson('/api/v1/mechanics/$id');
    return MechRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<MechProtocol>> listProtocols() async {
    final json = await _client.getJson('/api/v1/mechanic-protocols');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(MechProtocol.fromJson).toList(growable: false);
  }

  Future<MechRequest> create({
    required String title,
    required String vehicleLabel,
    required String address,
    required MechUrgency urgency,
    int? budgetNgn,
  }) async {
    final json = await _client.postJson('/api/v1/mechanics', {
      'title': title,
      'vehicleLabel': vehicleLabel,
      'address': address,
      'urgency': urgency.name,
      if (budgetNgn != null) 'budgetNgn': budgetNgn,
    });
    return MechRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<MechRequest> acceptOffer(String id, String offerId) async {
    final json = await _client.postJson('/api/v1/mechanics/$id/accept-offer', {
      'offerId': offerId,
    });
    return MechRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<MechRequest> bookProtocol({
    required String protocolId,
    required String vehicleLabel,
    required String address,
  }) async {
    final json = await _client.postJson('/api/v1/mechanics/protocol-book', {
      'protocolId': protocolId,
      'vehicleLabel': vehicleLabel,
      'address': address,
    });
    return MechRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<MechRequest> advance(String id) async {
    final json =
        await _client.postJson('/api/v1/mechanics/$id/advance', const {});
    return MechRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<MechRequest> acknowledgeReport(String id) async {
    final json = await _client
        .postJson('/api/v1/mechanics/$id/acknowledge-report', const {});
    return MechRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<MechRequest> cancel(String id) async {
    final json =
        await _client.postJson('/api/v1/mechanics/$id/cancel', const {});
    return MechRequest.fromJson(json['data'] as Map<String, dynamic>);
  }
}
