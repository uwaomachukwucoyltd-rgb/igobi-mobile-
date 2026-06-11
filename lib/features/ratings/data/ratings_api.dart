import '../../../core/api/api_client.dart';

class RatingsApi {
  RatingsApi(this._client);

  final ApiClient _client;

  Future<RatingResponse> rate({
    required String vendorId,
    required int stars,
    String? complaint,
    String? orderRef,
  }) async {
    final json = await _client.postJson('/api/v1/vendors/$vendorId/ratings', {
      'stars': stars,
      if (complaint != null && complaint.isNotEmpty) 'complaint': complaint,
      if (orderRef != null) 'orderRef': orderRef,
    });
    return RatingResponse.fromJson(json);
  }

  Future<List<RatingResponse>> listForVendor(String vendorId) async {
    final json = await _client.getJson('/api/v1/vendors/$vendorId/ratings');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(RatingResponse.fromMap).toList(growable: false);
  }

  Future<RatingResponse> resolve(String ratingId) async {
    final json = await _client.postJson('/api/v1/ratings/$ratingId/resolve', const {});
    return RatingResponse.fromJson(json);
  }
}

class RatingResponse {
  RatingResponse({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.stars,
    required this.complaint,
    required this.resolvedAt,
    required this.createdAt,
    required this.orderRef,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) =>
      RatingResponse.fromMap(json['data'] as Map<String, dynamic>);

  factory RatingResponse.fromMap(Map<String, dynamic> data) => RatingResponse(
        id: data['id'] as String,
        vendorId: data['vendorId'] as String,
        customerId: data['customerId'] as String,
        stars: data['stars'] as int,
        complaint: data['complaint'] as String?,
        resolvedAt: data['resolvedAt'] as String?,
        createdAt: data['createdAt'] as String,
        orderRef: data['orderRef'] as String?,
      );

  final String id;
  final String vendorId;
  final String customerId;
  final int stars;
  final String? complaint;
  final String? resolvedAt;
  final String createdAt;
  final String? orderRef;

  bool get isUnresolvedComplaint =>
      stars <= 2 && (complaint?.isNotEmpty ?? false) && resolvedAt == null;
}
