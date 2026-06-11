import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../data/mechanic_api.dart';

/// McCoy Mechanic — two settlement paths:
///   1. Protocol Registry  → fixed-rate services (computerized scan, oil change…)
///   2. Diagnostic Broadcast → geofenced bid with urgency tiers
///
/// Settlement: Proof-of-Service. Mechanic uploads Diagnostic Report →
/// buyer acknowledges → escrow releases (minus 10% McCoy Service Fee).

enum MechUrgency { routine, urgent, emergency }

extension MechUrgencyX on MechUrgency {
  String get label {
    switch (this) {
      case MechUrgency.routine:
        return 'Routine';
      case MechUrgency.urgent:
        return 'Urgent';
      case MechUrgency.emergency:
        return 'Emergency';
    }
  }

  String get window {
    switch (this) {
      case MechUrgency.routine:
        return 'Within 24 h';
      case MechUrgency.urgent:
        return 'Same-day · 2-hour window';
      case MechUrgency.emergency:
        return 'Geofence dispatch · arrive within 45 min';
    }
  }

  double get feeMultiplier => switch (this) {
        MechUrgency.routine => 1.0,
        MechUrgency.urgent => 1.15,
        MechUrgency.emergency => 1.35,
      };
}

MechUrgency _urgencyFromName(String name) =>
    MechUrgency.values.firstWhere((u) => u.name == name,
        orElse: () => MechUrgency.routine);

enum MechStatus {
  broadcasting,
  offersIn,
  enRoute, // mechanic accepted, heading to vehicle
  onSite,
  reportUploaded, // diagnostic report submitted, awaiting buyer ack
  released, // buyer acknowledged → escrow released
  cancelled,
}

extension MechStatusX on MechStatus {
  String get label {
    switch (this) {
      case MechStatus.broadcasting:
        return 'Broadcasting';
      case MechStatus.offersIn:
        return 'Offers in';
      case MechStatus.enRoute:
        return 'En route';
      case MechStatus.onSite:
        return 'On site';
      case MechStatus.reportUploaded:
        return 'Report uploaded';
      case MechStatus.released:
        return 'Closed';
      case MechStatus.cancelled:
        return 'Cancelled';
    }
  }
}

MechStatus _mechStatusFromName(String name) =>
    MechStatus.values.firstWhere((s) => s.name == name,
        orElse: () => MechStatus.broadcasting);

class MechOffer {
  const MechOffer({
    required this.id,
    required this.mechanicName,
    required this.node,
    required this.rating,
    required this.completed,
    required this.priceNgn,
    required this.etaMin,
    required this.specialty,
    required this.distanceKm,
  });

  factory MechOffer.fromJson(Map<String, dynamic> json) {
    return MechOffer(
      id: json['id'] as String,
      mechanicName: json['mechanicName'] as String,
      node: json['node'] as String,
      rating: (json['rating'] as num).toDouble(),
      completed: (json['completed'] as num).toInt(),
      priceNgn: (json['priceNgn'] as num).toInt(),
      etaMin: (json['etaMin'] as num).toInt(),
      specialty: json['specialty'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
    );
  }

  final String id;
  final String mechanicName;
  final String node;
  final double rating;
  final int completed;
  final int priceNgn;
  final int etaMin;
  final String specialty;
  final double distanceKm;
}

class DiagnosticReport {
  const DiagnosticReport({
    required this.summary,
    required this.findings,
    required this.recommendations,
    required this.photosCount,
    required this.uploadedAt,
  });

  factory DiagnosticReport.fromJson(Map<String, dynamic> json) {
    return DiagnosticReport(
      summary: json['summary'] as String,
      findings: (json['findings'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      recommendations: (json['recommendations'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      photosCount: (json['photosCount'] as num).toInt(),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  final String summary;
  final List<String> findings;
  final List<String> recommendations;
  final int photosCount;
  final DateTime uploadedAt;
}

class MechRequest {
  MechRequest({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.vehicleLabel,
    required this.address,
    required this.urgency,
    required this.budgetNgn,
    required this.status,
    required this.isFixedRate,
    this.offers = const [],
    this.acceptedOfferId,
    this.heldEscrowRef,
    this.report,
  });

  factory MechRequest.fromJson(Map<String, dynamic> json) {
    final rawOffers = (json['offers'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final rawReport = json['report'] as Map<String, dynamic>?;
    return MechRequest(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String,
      vehicleLabel: json['vehicleLabel'] as String,
      address: json['address'] as String,
      urgency: _urgencyFromName(json['urgency'] as String),
      budgetNgn: (json['budgetNgn'] as num?)?.toInt(),
      status: _mechStatusFromName(json['status'] as String),
      isFixedRate: json['isFixedRate'] as bool? ?? false,
      offers: rawOffers.map(MechOffer.fromJson).toList(growable: false),
      acceptedOfferId: json['acceptedOfferId'] as String?,
      heldEscrowRef: json['heldEscrowRef'] as String?,
      report: rawReport == null ? null : DiagnosticReport.fromJson(rawReport),
    );
  }

  final String id;
  final DateTime createdAt;
  final String title;
  final String vehicleLabel;
  final String address;
  final MechUrgency urgency;
  final int? budgetNgn;
  final MechStatus status;
  final bool isFixedRate;
  final List<MechOffer> offers;
  final String? acceptedOfferId;
  final String? heldEscrowRef;
  final DiagnosticReport? report;

  MechOffer? get acceptedOffer => acceptedOfferId == null
      ? null
      : offers.firstWhere((o) => o.id == acceptedOfferId);

  /// 10% McCoy Service Fee. Computed client-side from the accepted offer.
  int? get mccoyFeeNgn {
    final price = acceptedOffer?.priceNgn ?? budgetNgn;
    if (price == null) return null;
    return (price * 0.10).round();
  }

  int? get mechanicPayoutNgn {
    final price = acceptedOffer?.priceNgn ?? budgetNgn;
    if (price == null) return null;
    return price - (mccoyFeeNgn ?? 0);
  }
}

/// Protocol Registry — fixed-rate services. Tap → instant escrow, scheduling.
class MechProtocol {
  const MechProtocol({
    required this.id,
    required this.title,
    required this.icon,
    required this.priceNgn,
    required this.etaWindow,
    required this.summary,
  });

  factory MechProtocol.fromJson(Map<String, dynamic> json) {
    return MechProtocol(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: (json['icon'] as num).toInt(),
      priceNgn: (json['priceNgn'] as num).toInt(),
      etaWindow: json['etaWindow'] as String,
      summary: json['summary'] as String,
    );
  }

  final String id;
  final String title;
  final int icon; // material icon codepoint
  final int priceNgn;
  final String etaWindow;
  final String summary;
}

/// Authed data source for the mechanic hub. Mirrors marketplaceApiProvider.
final mechanicApiProvider = Provider<MechanicApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return MechanicApi(client);
});

/// Fixed-rate protocol registry, served from the backend.
final mechProtocolsProvider = FutureProvider<List<MechProtocol>>((ref) async {
  return ref.watch(mechanicApiProvider).listProtocols();
});

class MechanicController extends StateNotifier<List<MechRequest>> {
  MechanicController(this._api) : super(const []) {
    load();
  }

  final MechanicApi _api;

  Future<void> load() async {
    state = await _api.list();
  }

  void _replace(MechRequest updated) {
    final idx = state.indexWhere((r) => r.id == updated.id);
    if (idx < 0) {
      state = [updated, ...state];
      return;
    }
    final next = [...state];
    next[idx] = updated;
    state = next;
  }

  /// Drive enRoute → onSite → reportUploaded via the backend /advance endpoint.
  Future<void> _runToReport(String requestId) async {
    var current = state.firstWhere((r) => r.id == requestId,
        orElse: () => throw StateError('request not found'));
    while (current.status == MechStatus.enRoute ||
        current.status == MechStatus.onSite) {
      current = await _api.advance(requestId);
      _replace(current);
    }
  }

  /// Diagnostic Broadcast — open call for offers.
  Future<String> createBroadcast({
    required String title,
    required String vehicleLabel,
    required String address,
    required MechUrgency urgency,
    int? budgetNgn,
  }) async {
    final created = await _api.create(
      title: title,
      vehicleLabel: vehicleLabel,
      address: address,
      urgency: urgency,
      budgetNgn: budgetNgn,
    );
    _replace(created);
    return created.id;
  }

  Future<String> acceptOffer(String requestId, String offerId) async {
    final updated = await _api.acceptOffer(requestId, offerId);
    _replace(updated);
    await _runToReport(requestId);
    return updated.heldEscrowRef ?? '';
  }

  /// Protocol Registry — instant booking, fixed rate.
  Future<String> bookProtocol(MechProtocol protocol,
      {required String vehicleLabel, required String address}) async {
    final created = await _api.bookProtocol(
      protocolId: protocol.id,
      vehicleLabel: vehicleLabel,
      address: address,
    );
    _replace(created);
    await _runToReport(created.id);
    return created.id;
  }

  /// Buyer acknowledges report → escrow releases (minus McCoy fee).
  Future<void> acknowledgeReport(String requestId) async {
    _replace(await _api.acknowledgeReport(requestId));
  }

  Future<void> cancel(String requestId) async {
    _replace(await _api.cancel(requestId));
  }
}

final mechanicControllerProvider =
    StateNotifierProvider<MechanicController, List<MechRequest>>(
  (ref) => MechanicController(ref.watch(mechanicApiProvider)),
);
