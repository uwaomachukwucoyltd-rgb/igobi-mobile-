import '../../../core/api/api_client.dart';

class ImpactApi {
  ImpactApi(this._client);
  final ApiClient _client;

  Future<ImpactSummary> mySummary() async {
    final body = await _client.getJson('/api/v1/ledger/my-impact');
    final data = body['data'] as Map<String, dynamic>;
    return ImpactSummary(
      totalNgn: _ngnFromMinor(data['totalMinor'] as String),
      count: data['count'] as int,
    );
  }

  /// Latest donation rows produced by this customer's purchases. Used to
  /// render the per-transaction history under the running total.
  Future<List<ImpactDonation>> recentDonations({int limit = 20}) async {
    final body = await _client.getJson(
      '/api/v1/ledger/me?as=customer&stakeholder=DONATION&limit=$limit',
    );
    final data = (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(ImpactDonation.fromJson).toList(growable: false);
  }
}

class ImpactSummary {
  const ImpactSummary({required this.totalNgn, required this.count});
  final int totalNgn;
  final int count;
}

class ImpactDonation {
  const ImpactDonation({
    required this.id,
    required this.amountNgn,
    required this.lineLabel,
    required this.recipientId,
    required this.createdAt,
  });

  factory ImpactDonation.fromJson(Map<String, dynamic> json) => ImpactDonation(
        id: json['id'] as String,
        amountNgn: _ngnFromMinor(json['amountMinor'] as String),
        lineLabel: json['lineLabel'] as String,
        recipientId: json['recipientId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final int amountNgn;
  final String lineLabel;
  final String? recipientId;
  final DateTime createdAt;
}

int _ngnFromMinor(String raw) =>
    (BigInt.parse(raw) ~/ BigInt.from(100)).toInt();
