import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';

// =====================================================================
// Models
// =====================================================================

class WalletBalance {
  const WalletBalance({required this.balanceMinor, required this.currency});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balanceMinor: (json['balanceMinor'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'NGN').toString(),
    );
  }

  final int balanceMinor;
  final String currency;

  /// Major-unit value (NGN) for display.
  double get balance => balanceMinor / 100.0;
}

class WalletTxn {
  const WalletTxn({
    required this.amountMinor,
    required this.type,
    required this.description,
    required this.balanceAfterMinor,
    required this.createdAt,
    this.refId,
  });

  factory WalletTxn.fromJson(Map<String, dynamic> json) {
    return WalletTxn(
      amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      balanceAfterMinor: (json['balanceAfterMinor'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
              DateTime.now(),
      refId: json['refId']?.toString(),
    );
  }

  final int amountMinor;
  final String type;
  final String description;
  final int balanceAfterMinor;
  final DateTime createdAt;
  final String? refId;

  double get amount => amountMinor / 100.0;
  double get balanceAfter => balanceAfterMinor / 100.0;

  /// Credits (TOPUP, REFUND, REWARD…) move money in; everything else is a debit.
  bool get isCredit => amountMinor >= 0;
}

class WalletTxnPage {
  const WalletTxnPage({required this.items, required this.total});
  final List<WalletTxn> items;
  final int total;
}

// =====================================================================
// API
// =====================================================================

class WalletApi {
  WalletApi(this._client);

  final ApiClient _client;

  Future<WalletBalance> getBalance() async {
    final json = await _client.getJson('/api/v1/wallet');
    final data = json['data'] as Map<String, dynamic>;
    return WalletBalance.fromJson(data);
  }

  Future<WalletTxnPage> getTransactions({int limit = 50, int skip = 0}) async {
    final json =
        await _client.getJson('/api/v1/wallet/transactions?limit=$limit&skip=$skip');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return WalletTxnPage(
      items: data.map(WalletTxn.fromJson).toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? data.length,
    );
  }

  /// Credits the wallet. For now this is the top-up path (type TOPUP).
  Future<void> topUp({required int amountMinor, String? description}) async {
    await _client.postJson('/api/v1/wallet/credit', {
      'amountMinor': amountMinor,
      'type': 'TOPUP',
      'description': description ?? 'Wallet top-up',
    });
  }
}

// =====================================================================
// Providers
// =====================================================================

final walletApiProvider = Provider<WalletApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.paymentBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return WalletApi(client);
});

final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  final api = ref.watch(walletApiProvider);
  return api.getBalance();
});

final walletTransactionsProvider =
    FutureProvider<WalletTxnPage>((ref) async {
  final api = ref.watch(walletApiProvider);
  return api.getTransactions(limit: 50);
});
