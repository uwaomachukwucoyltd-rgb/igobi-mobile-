import '../../../core/api/api_client.dart';

class ReligiousOrgsApi {
  ReligiousOrgsApi(this._client);
  final ApiClient _client;

  Future<List<ReligiousOrg>> search({
    String? query,
    String? type,
    int limit = 40,
  }) async {
    final params = <String>[
      'limit=$limit',
      'verifiedOnly=false',
      if (query != null && query.trim().isNotEmpty)
        'q=${Uri.encodeQueryComponent(query.trim())}',
      if (type != null) 'type=${Uri.encodeQueryComponent(type)}',
    ];
    final json = await _client.getJson('/api/v1/religious-orgs?${params.join('&')}');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(ReligiousOrg.fromJson).toList(growable: false);
  }

  Future<ReligiousOrg> getByAnyKey(String key) async {
    final json = await _client.getJson('/api/v1/religious-orgs/${Uri.encodeComponent(key)}');
    final data = json['data'] as Map<String, dynamic>;
    return ReligiousOrg.fromJson(data);
  }
}

class ReligiousOrg {
  const ReligiousOrg({
    required this.id,
    required this.slug,
    required this.code,
    required this.name,
    required this.type,
    required this.location,
    required this.about,
    required this.logoUrl,
    required this.verified,
    required this.followerCount,
    required this.lifetimeReceivedNgn,
  });

  factory ReligiousOrg.fromJson(Map<String, dynamic> json) => ReligiousOrg(
        id: json['id'] as String,
        slug: json['slug'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        location: json['location'] as String,
        about: json['about'] as String?,
        logoUrl: json['logoUrl'] as String?,
        verified: (json['verified'] as bool?) ?? false,
        followerCount: (json['followerCount'] as int?) ?? 0,
        lifetimeReceivedNgn: _ngnFromMinorString(json['lifetimeReceivedMinor'] as String?),
      );

  final String id;
  final String slug;
  final String code;
  final String name;
  final String type;
  final String location;
  final String? about;
  final String? logoUrl;
  final bool verified;
  final int followerCount;
  final int lifetimeReceivedNgn;
}

int _ngnFromMinorString(String? raw) {
  if (raw == null || raw.isEmpty) return 0;
  return (BigInt.parse(raw) ~/ BigInt.from(100)).toInt();
}
