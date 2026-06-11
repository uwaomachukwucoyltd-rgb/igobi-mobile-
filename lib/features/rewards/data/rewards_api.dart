import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';

// =====================================================================
// Models
// =====================================================================

class LoyaltyInfo {
  const LoyaltyInfo({required this.points, required this.tier});

  factory LoyaltyInfo.fromJson(Map<String, dynamic> json) {
    return LoyaltyInfo(
      points: (json['points'] as num?)?.toInt() ?? 0,
      tier: (json['tier'] ?? 'BRONZE').toString(),
    );
  }

  final int points;
  final String tier;
}

class ReferralEntry {
  const ReferralEntry({
    required this.label,
    required this.rewardedMinor,
    this.createdAt,
    this.status,
  });

  factory ReferralEntry.fromJson(Map<String, dynamic> json) {
    // Backend shape is loose; pick the most likely fields with fallbacks.
    final label = (json['refereeEmail'] ??
            json['email'] ??
            json['refereeName'] ??
            json['name'] ??
            json['code'] ??
            'Referral')
        .toString();
    return ReferralEntry(
      label: label,
      rewardedMinor: (json['rewardedMinor'] as num?)?.toInt() ??
          (json['rewardMinor'] as num?)?.toInt() ??
          0,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal(),
      status: json['status']?.toString(),
    );
  }

  final String label;
  final int rewardedMinor;
  final DateTime? createdAt;
  final String? status;

  double get rewarded => rewardedMinor / 100.0;
}

class ReferralInfo {
  const ReferralInfo({
    required this.referrals,
    required this.totalRewardedMinor,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    final list = (json['referrals'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return ReferralInfo(
      referrals: list.map(ReferralEntry.fromJson).toList(growable: false),
      totalRewardedMinor: (json['totalRewardedMinor'] as num?)?.toInt() ?? 0,
    );
  }

  final List<ReferralEntry> referrals;
  final int totalRewardedMinor;

  double get totalRewarded => totalRewardedMinor / 100.0;
}

class RedeemResult {
  const RedeemResult({required this.ok, required this.message});

  factory RedeemResult.fromJson(Map<String, dynamic> json) {
    return RedeemResult(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }

  final bool ok;
  final String message;
}

// =====================================================================
// API
// =====================================================================

class RewardsApi {
  RewardsApi(this._client);

  final ApiClient _client;

  Future<String> getReferralCode() async {
    final json = await _client.getJson('/api/v1/rewards/referral-code');
    final data = json['data'] as Map<String, dynamic>;
    return (data['code'] ?? '').toString();
  }

  Future<RedeemResult> redeemReferral(String code) async {
    final json = await _client.postJson('/api/v1/rewards/redeem-referral', {
      'code': code,
    });
    final data = json['data'] as Map<String, dynamic>;
    return RedeemResult.fromJson(data);
  }

  Future<LoyaltyInfo> getLoyalty() async {
    final json = await _client.getJson('/api/v1/rewards/loyalty');
    final data = json['data'] as Map<String, dynamic>;
    return LoyaltyInfo.fromJson(data);
  }

  Future<ReferralInfo> getReferrals() async {
    final json = await _client.getJson('/api/v1/rewards/referrals');
    final data = json['data'] as Map<String, dynamic>;
    return ReferralInfo.fromJson(data);
  }
}

// =====================================================================
// Providers
// =====================================================================

final rewardsApiProvider = Provider<RewardsApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.paymentBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return RewardsApi(client);
});

final referralCodeProvider = FutureProvider<String>((ref) async {
  final api = ref.watch(rewardsApiProvider);
  return api.getReferralCode();
});

final loyaltyProvider = FutureProvider<LoyaltyInfo>((ref) async {
  final api = ref.watch(rewardsApiProvider);
  return api.getLoyalty();
});

final referralsProvider = FutureProvider<ReferralInfo>((ref) async {
  final api = ref.watch(rewardsApiProvider);
  return api.getReferrals();
});
