import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/errands_api.dart';

enum ErrandStatus {
  broadcasting,   // signal sent, awaiting bids
  bidsIn,         // 3 bids received, awaiting buyer to accept one
  assigned,       // bid accepted, funds in escrow, runner moving
  delivered,      // runner says delivered — awaiting recipient confirmation
  confirmed,      // recipient confirmed → funds released → terminal
  cancelled,      // buyer cancelled before any bid was accepted
}

ErrandStatus _errandStatusFromWire(String? raw) {
  return ErrandStatus.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => ErrandStatus.broadcasting,
  );
}

class Bid {
  const Bid({
    required this.id,
    required this.runnerName,
    required this.rating,
    required this.completed,
    required this.priceNgn,
    required this.etaMin,
    required this.hub,
  });

  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
        id: json['id'] as String,
        runnerName: json['runnerName'] as String,
        rating: (json['rating'] as num).toDouble(),
        completed: (json['completed'] as num).toInt(),
        priceNgn: (json['priceNgn'] as num).toInt(),
        etaMin: (json['etaMin'] as num).toInt(),
        hub: json['hub'] as String,
      );

  final String id;
  final String runnerName;
  final double rating;
  final int completed;
  final int priceNgn;
  final int etaMin;
  final String hub;
}

class Errand {
  Errand({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.recipientName,
    required this.recipientAddress,
    required this.maxBudgetNgn,
    required this.status,
    this.bids = const [],
    this.acceptedBidId,
    this.heldEscrowRef,
  });

  factory Errand.fromJson(Map<String, dynamic> json) {
    final rawBids = (json['bids'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return Errand(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>).cast<String>(),
      recipientName: json['recipientName'] as String,
      recipientAddress: json['recipientAddress'] as String,
      maxBudgetNgn: (json['maxBudgetNgn'] as num?)?.toInt(),
      status: _errandStatusFromWire(json['status'] as String?),
      bids: rawBids.map(Bid.fromJson).toList(growable: false),
      acceptedBidId: json['acceptedBidId'] as String?,
      heldEscrowRef: json['heldEscrowRef'] as String?,
    );
  }

  final String id;
  final DateTime createdAt;
  final List<String> items;
  final String recipientName;
  final String recipientAddress;
  final int? maxBudgetNgn;
  final ErrandStatus status;
  final List<Bid> bids;
  final String? acceptedBidId;
  final String? heldEscrowRef;

  Bid? get acceptedBid =>
      acceptedBidId == null ? null : bids.firstWhere((b) => b.id == acceptedBidId);

  Errand copyWith({
    ErrandStatus? status,
    List<Bid>? bids,
    String? acceptedBidId,
    String? heldEscrowRef,
  }) {
    return Errand(
      id: id,
      createdAt: createdAt,
      items: items,
      recipientName: recipientName,
      recipientAddress: recipientAddress,
      maxBudgetNgn: maxBudgetNgn,
      status: status ?? this.status,
      bids: bids ?? this.bids,
      acceptedBidId: acceptedBidId ?? this.acceptedBidId,
      heldEscrowRef: heldEscrowRef ?? this.heldEscrowRef,
    );
  }
}

/// Errand hub state, backed by the live vendor-service API. The screens watch a
/// `List<Errand>`; we start empty and populate after the initial fetch. Mutating
/// actions call the API and replace the affected item from the server response.
class ErrandController extends StateNotifier<List<Errand>> {
  ErrandController(this._api) : super(const []) {
    load();
  }

  final ErrandsApi _api;

  Future<void> load() async {
    final list = await _api.listErrands();
    state = list;
  }

  void _upsert(Errand errand) {
    final idx = state.indexWhere((e) => e.id == errand.id);
    if (idx < 0) {
      state = [errand, ...state];
    } else {
      final next = [...state];
      next[idx] = errand;
      state = next;
    }
  }

  /// Creates an errand on the backend. Returns its id synchronously via an
  /// optimistic placeholder so the caller can immediately open the detail sheet;
  /// the real record (status bidsIn with 3 bids) replaces it when the POST
  /// resolves.
  String createErrand({
    required List<String> items,
    required String recipientName,
    required String recipientAddress,
    int? maxBudgetNgn,
  }) {
    final tempId = 'err_pending_${DateTime.now().microsecondsSinceEpoch}';
    final placeholder = Errand(
      id: tempId,
      createdAt: DateTime.now(),
      items: items,
      recipientName: recipientName,
      recipientAddress: recipientAddress,
      maxBudgetNgn: maxBudgetNgn,
      status: ErrandStatus.broadcasting,
    );
    state = [placeholder, ...state];

    () async {
      final created = await _api.createErrand(
        items: items,
        recipientName: recipientName,
        recipientAddress: recipientAddress,
        maxBudgetNgn: maxBudgetNgn,
      );
      // Swap the placeholder for the server record (different id).
      final next = [...state];
      final idx = next.indexWhere((e) => e.id == tempId);
      if (idx >= 0) {
        next[idx] = created;
      } else {
        next.insert(0, created);
      }
      state = next;
    }();

    return tempId;
  }

  String acceptBid(String errandId, String bidId) {
    () async {
      final updated = await _api.acceptBid(errandId, bidId);
      _upsert(updated);
    }();
    return '';
  }

  void deliver(String errandId) {
    () async {
      final updated = await _api.deliver(errandId);
      _upsert(updated);
    }();
  }

  void confirmReceipt(String errandId) {
    () async {
      final updated = await _api.confirmReceipt(errandId);
      _upsert(updated);
    }();
  }

  void cancel(String errandId) {
    () async {
      final updated = await _api.cancel(errandId);
      _upsert(updated);
    }();
  }
}

final errandControllerProvider =
    StateNotifierProvider<ErrandController, List<Errand>>(
  (ref) => ErrandController(ref.watch(errandsApiProvider)),
);
