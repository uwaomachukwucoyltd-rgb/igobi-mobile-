import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/artisan_jobs_api.dart';

enum Urgency {
  routine,    // within 24-48 h
  urgent,     // same-day
  emergency,  // within 1 hour
}

Urgency urgencyFromWire(String? raw) => Urgency.values.firstWhere(
      (u) => u.name == raw,
      orElse: () => Urgency.routine,
    );

extension UrgencyX on Urgency {
  String get label {
    switch (this) {
      case Urgency.routine:
        return 'Routine';
      case Urgency.urgent:
        return 'Urgent';
      case Urgency.emergency:
        return 'Emergency';
    }
  }

  String get note {
    switch (this) {
      case Urgency.routine:
        return 'Within 24–48 h';
      case Urgency.urgent:
        return 'Same-day';
      case Urgency.emergency:
        return 'Arrive within 1 h';
    }
  }
}

enum JobStatus {
  broadcasting,
  bidsIn,
  dispatched,    // artisan accepted, en route
  onSite,        // artisan at address
  completed,     // artisan says done — awaiting buyer confirmation
  confirmed,     // buyer confirms → escrow released
  cancelled,
}

JobStatus _jobStatusFromWire(String? raw) => JobStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => JobStatus.broadcasting,
    );

class ArtisanBid {
  const ArtisanBid({
    required this.id,
    required this.artisanName,
    required this.specialty,
    required this.rating,
    required this.completed,
    required this.priceNgn,
    required this.etaMin,
    required this.lga,
  });

  factory ArtisanBid.fromJson(Map<String, dynamic> json) => ArtisanBid(
        id: json['id'] as String,
        artisanName: json['artisanName'] as String,
        specialty: json['specialty'] as String,
        rating: (json['rating'] as num).toDouble(),
        completed: (json['completed'] as num).toInt(),
        priceNgn: (json['priceNgn'] as num).toInt(),
        etaMin: (json['etaMin'] as num).toInt(),
        lga: json['lga'] as String,
      );

  final String id;
  final String artisanName;
  final String specialty;
  final double rating;
  final int completed;
  final int priceNgn;
  final int etaMin;
  final String lga;
}

class ArtisanJob {
  ArtisanJob({
    required this.id,
    required this.createdAt,
    required this.serviceTitle,
    required this.description,
    required this.address,
    required this.urgency,
    required this.budgetNgn,
    required this.status,
    this.bids = const [],
    this.acceptedBidId,
    this.heldEscrowRef,
  });

  factory ArtisanJob.fromJson(Map<String, dynamic> json) {
    final rawBids = (json['bids'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return ArtisanJob(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      serviceTitle: json['serviceTitle'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      urgency: urgencyFromWire(json['urgency'] as String?),
      budgetNgn: (json['budgetNgn'] as num?)?.toInt(),
      status: _jobStatusFromWire(json['status'] as String?),
      bids: rawBids.map(ArtisanBid.fromJson).toList(growable: false),
      acceptedBidId: json['acceptedBidId'] as String?,
      heldEscrowRef: json['heldEscrowRef'] as String?,
    );
  }

  final String id;
  final DateTime createdAt;
  final String serviceTitle;
  final String description;
  final String address;
  final Urgency urgency;
  final int? budgetNgn;
  final JobStatus status;
  final List<ArtisanBid> bids;
  final String? acceptedBidId;
  final String? heldEscrowRef;

  ArtisanBid? get acceptedBid =>
      acceptedBidId == null ? null : bids.firstWhere((b) => b.id == acceptedBidId);

  ArtisanJob copyWith({
    JobStatus? status,
    List<ArtisanBid>? bids,
    String? acceptedBidId,
    String? heldEscrowRef,
  }) {
    return ArtisanJob(
      id: id,
      createdAt: createdAt,
      serviceTitle: serviceTitle,
      description: description,
      address: address,
      urgency: urgency,
      budgetNgn: budgetNgn,
      status: status ?? this.status,
      bids: bids ?? this.bids,
      acceptedBidId: acceptedBidId ?? this.acceptedBidId,
      heldEscrowRef: heldEscrowRef ?? this.heldEscrowRef,
    );
  }
}

/// Pre-negotiated, fixed-rate express services. Tap → instantly creates a job
/// in DISPATCHED state with the price locked in escrow. No bidding round.
class DirectService {
  const DirectService({
    required this.id,
    required this.title,
    required this.icon,
    required this.priceNgn,
    required this.etaWindow,
    required this.summary,
  });

  factory DirectService.fromJson(Map<String, dynamic> json) => DirectService(
        id: json['id'] as String,
        title: json['title'] as String,
        icon: (json['icon'] as num).toInt(),
        priceNgn: (json['priceNgn'] as num).toInt(),
        etaWindow: json['etaWindow'] as String,
        summary: json['summary'] as String,
      );

  final String id;
  final String title;
  final int icon; // material icon codepoint
  final int priceNgn;
  final String etaWindow;
  final String summary;
}

/// Local fallback list shown while the live registry loads. Material icon
/// codepoints chosen to avoid pulling a Material import here.
const directServices = <DirectService>[
  DirectService(
    id: 'reg_pipe',
    title: 'Fix a burst pipe',
    icon: 0xe35e, // plumbing
    priceNgn: 8000,
    etaWindow: '60–90 min',
    summary: 'Standard pipe leak repair, parts inclusive (up to 1m run).',
  ),
  DirectService(
    id: 'reg_socket',
    title: 'Replace electrical socket',
    icon: 0xe1d8, // electrical_services
    priceNgn: 3500,
    etaWindow: '45 min',
    summary: 'Single-gang socket swap, parts inclusive.',
  ),
  DirectService(
    id: 'reg_ac',
    title: 'AC servicing',
    icon: 0xef39, // ac_unit
    priceNgn: 12000,
    etaWindow: '2 h',
    summary: 'Filter clean, gas check, condenser flush.',
  ),
  DirectService(
    id: 'reg_locksmith',
    title: 'Locksmith · main door',
    icon: 0xe898, // lock
    priceNgn: 9500,
    etaWindow: '60 min',
    summary: 'Standard cylinder replacement and re-keying.',
  ),
];

/// Live direct-registry services from the backend. Falls back to the bundled
/// [directServices] list while loading or on error so the carousel never blanks.
final directServicesProvider = FutureProvider<List<DirectService>>((ref) async {
  final api = ref.watch(artisanJobsApiProvider);
  return api.listDirectServices();
});

/// Artisan hub state, backed by the live vendor-service API. Screens watch a
/// `List<ArtisanJob>`; we start empty and populate after the initial fetch.
class ArtisanController extends StateNotifier<List<ArtisanJob>> {
  ArtisanController(this._api) : super(const []) {
    load();
  }

  final ArtisanJobsApi _api;

  Future<void> load() async {
    final list = await _api.listJobs();
    state = list;
  }

  void _upsert(ArtisanJob job) {
    final idx = state.indexWhere((j) => j.id == job.id);
    if (idx < 0) {
      state = [job, ...state];
    } else {
      final next = [...state];
      next[idx] = job;
      state = next;
    }
  }

  /// Standard broadcast → bid flow. Returns an id synchronously (optimistic
  /// placeholder) so the caller can open the detail sheet; the server record
  /// (status bidsIn + 3 bids) replaces it when the POST resolves.
  String createBroadcast({
    required String serviceTitle,
    required String description,
    required String address,
    required Urgency urgency,
    int? budgetNgn,
  }) {
    final tempId = 'job_pending_${DateTime.now().microsecondsSinceEpoch}';
    state = [
      ArtisanJob(
        id: tempId,
        createdAt: DateTime.now(),
        serviceTitle: serviceTitle,
        description: description,
        address: address,
        urgency: urgency,
        budgetNgn: budgetNgn,
        status: JobStatus.broadcasting,
      ),
      ...state,
    ];

    () async {
      final created = await _api.createBroadcast(
        serviceTitle: serviceTitle,
        description: description,
        address: address,
        urgency: urgency,
        budgetNgn: budgetNgn,
      );
      final next = [...state];
      final idx = next.indexWhere((j) => j.id == tempId);
      if (idx >= 0) {
        next[idx] = created;
      } else {
        next.insert(0, created);
      }
      state = next;
    }();

    return tempId;
  }

  /// Direct Registry — instant booking, no bidding round (server returns the
  /// job already DISPATCHED).
  String bookDirect(DirectService service, String address) {
    final tempId = 'job_pending_${DateTime.now().microsecondsSinceEpoch}';
    state = [
      ArtisanJob(
        id: tempId,
        createdAt: DateTime.now(),
        serviceTitle: service.title,
        description: service.summary,
        address: address,
        urgency: Urgency.urgent,
        budgetNgn: service.priceNgn,
        status: JobStatus.dispatched,
      ),
      ...state,
    ];

    () async {
      final created = await _api.bookDirect(
        serviceId: service.id,
        address: address,
      );
      final next = [...state];
      final idx = next.indexWhere((j) => j.id == tempId);
      if (idx >= 0) {
        next[idx] = created;
      } else {
        next.insert(0, created);
      }
      state = next;
    }();

    return tempId;
  }

  String acceptBid(String jobId, String bidId) {
    () async {
      final updated = await _api.acceptBid(jobId, bidId);
      _upsert(updated);
    }();
    return '';
  }

  void advance(String jobId) {
    () async {
      final updated = await _api.advance(jobId);
      _upsert(updated);
    }();
  }

  void confirmReceipt(String jobId) {
    () async {
      final updated = await _api.confirm(jobId);
      _upsert(updated);
    }();
  }

  void cancel(String jobId) {
    () async {
      final updated = await _api.cancel(jobId);
      _upsert(updated);
    }();
  }
}

final artisanControllerProvider =
    StateNotifierProvider<ArtisanController, List<ArtisanJob>>(
  (ref) => ArtisanController(ref.watch(artisanJobsApiProvider)),
);
