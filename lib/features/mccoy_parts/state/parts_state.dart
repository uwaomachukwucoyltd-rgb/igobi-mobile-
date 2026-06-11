import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../data/parts_api.dart';

/// McCoy Auto Parts — Broadcast & Bid protocol with mandatory Fitment
/// Verification by a McCoy Mechanic Node before escrow releases.
///
/// Lifecycle: BROADCASTING → BIDS_IN → AWARDED (escrow locked) →
/// AWAITING_FITMENT (part delivered, verifier scheduled) →
/// FITMENT_VERIFIED (escrow released) → CONFIRMED
///
/// CANCELLED can occur from BROADCASTING / BIDS_IN.
enum PartStatus {
  broadcasting,
  bidsIn,
  awarded,
  awaitingFitment,
  fitmentVerified,
  confirmed,
  cancelled,
}

extension PartStatusX on PartStatus {
  String get label {
    switch (this) {
      case PartStatus.broadcasting:
        return 'Broadcasting';
      case PartStatus.bidsIn:
        return 'Bids in';
      case PartStatus.awarded:
        return 'Awarded · escrow locked';
      case PartStatus.awaitingFitment:
        return 'Awaiting fitment verification';
      case PartStatus.fitmentVerified:
        return 'Fitment verified';
      case PartStatus.confirmed:
        return 'Confirmed';
      case PartStatus.cancelled:
        return 'Cancelled';
    }
  }
}

PartStatus _partStatusFromName(String name) =>
    PartStatus.values.firstWhere((s) => s.name == name,
        orElse: () => PartStatus.broadcasting);

class PartBid {
  const PartBid({
    required this.id,
    required this.dealerName,
    required this.dealerNode,
    required this.rating,
    required this.fulfilled,
    required this.priceNgn,
    required this.etaHours,
    required this.condition, // 'OEM', 'Aftermarket', 'Refurbished'
    required this.warrantyDays,
    required this.lga,
  });

  factory PartBid.fromJson(Map<String, dynamic> json) {
    return PartBid(
      id: json['id'] as String,
      dealerName: json['dealerName'] as String,
      dealerNode: json['dealerNode'] as String,
      rating: (json['rating'] as num).toDouble(),
      fulfilled: (json['fulfilled'] as num).toInt(),
      priceNgn: (json['priceNgn'] as num).toInt(),
      etaHours: (json['etaHours'] as num).toInt(),
      condition: json['condition'] as String,
      warrantyDays: (json['warrantyDays'] as num).toInt(),
      lga: json['lga'] as String,
    );
  }

  final String id;
  final String dealerName;
  final String dealerNode; // e.g. "Ladipo Node · Sector 4"
  final double rating;
  final int fulfilled;
  final int priceNgn;
  final int etaHours;
  final String condition;
  final int warrantyDays;
  final String lga;
}

class PartRequest {
  PartRequest({
    required this.id,
    required this.createdAt,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.partName,
    required this.notes,
    required this.deliverTo,
    required this.budgetNgn,
    required this.status,
    this.bids = const [],
    this.acceptedBidId,
    this.heldEscrowRef,
    this.verifierName,
  });

  factory PartRequest.fromJson(Map<String, dynamic> json) {
    final rawBids = (json['bids'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return PartRequest(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      vehicleMake: json['vehicleMake'] as String,
      vehicleModel: json['vehicleModel'] as String,
      vehicleYear: (json['vehicleYear'] as num).toInt(),
      partName: json['partName'] as String,
      notes: json['notes'] as String? ?? '',
      deliverTo: json['deliverTo'] as String,
      budgetNgn: (json['budgetNgn'] as num?)?.toInt(),
      status: _partStatusFromName(json['status'] as String),
      bids: rawBids.map(PartBid.fromJson).toList(growable: false),
      acceptedBidId: json['acceptedBidId'] as String?,
      heldEscrowRef: json['heldEscrowRef'] as String?,
      verifierName: json['verifierName'] as String?,
    );
  }

  final String id;
  final DateTime createdAt;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String partName;
  final String notes;
  final String deliverTo;
  final int? budgetNgn;
  final PartStatus status;
  final List<PartBid> bids;
  final String? acceptedBidId;
  final String? heldEscrowRef;
  final String? verifierName;

  PartBid? get acceptedBid =>
      acceptedBidId == null ? null : bids.firstWhere((b) => b.id == acceptedBidId);

  String get vehicleLabel => '$vehicleYear $vehicleMake $vehicleModel';
}

/// Authed data source for the parts hub. Mirrors marketplaceApiProvider.
final partsApiProvider = Provider<PartsApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return PartsApi(client);
});

class PartsController extends StateNotifier<List<PartRequest>> {
  PartsController(this._api) : super(const []) {
    load();
  }

  final PartsApi _api;

  Future<void> load() async {
    final items = await _api.list();
    state = items;
  }

  void _replace(PartRequest updated) {
    final idx = state.indexWhere((r) => r.id == updated.id);
    if (idx < 0) {
      state = [updated, ...state];
      return;
    }
    final next = [...state];
    next[idx] = updated;
    state = next;
  }

  Future<String> createBroadcast({
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String partName,
    required String notes,
    required String deliverTo,
    int? budgetNgn,
  }) async {
    final created = await _api.create(
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
      partName: partName,
      notes: notes,
      deliverTo: deliverTo,
      budgetNgn: budgetNgn,
    );
    _replace(created);
    return created.id;
  }

  Future<String> acceptBid(String requestId, String bidId) async {
    final updated = await _api.acceptBid(requestId, bidId);
    _replace(updated);
    return updated.heldEscrowRef ?? '';
  }

  /// Verifier confirms fitment is correct → escrow releases.
  Future<void> verifyFitment(String requestId) async {
    _replace(await _api.verifyFitment(requestId));
  }

  Future<void> confirmReceipt(String requestId) async {
    _replace(await _api.confirmReceipt(requestId));
  }

  Future<void> cancel(String requestId) async {
    _replace(await _api.cancel(requestId));
  }
}

final partsControllerProvider =
    StateNotifierProvider<PartsController, List<PartRequest>>(
  (ref) => PartsController(ref.watch(partsApiProvider)),
);
