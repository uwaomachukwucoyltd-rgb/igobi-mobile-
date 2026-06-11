import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../artisan/state/job_state.dart';
import '../community/state/errand_state.dart';
import '../mccoy_mechanic/state/mechanic_state.dart';
import '../mccoy_parts/state/parts_state.dart';

/// One pulsing dot on the Live Node Feed radar.
///
/// A "signal" is any active broadcast across the buyer-initiated modules
/// (Community / Artisan / McCoy Parts / McCoy Mechanic) that has not yet been
/// awarded — i.e. status is BROADCASTING or BIDS_IN/OFFERS_IN.

enum SignalModule { errand, artisan, parts, mechanic }

extension SignalModuleX on SignalModule {
  String get label {
    switch (this) {
      case SignalModule.errand:
        return 'Community';
      case SignalModule.artisan:
        return 'Artisan';
      case SignalModule.parts:
        return 'McCoy Parts';
      case SignalModule.mechanic:
        return 'McCoy Mechanic';
    }
  }

  String get prefix {
    switch (this) {
      case SignalModule.errand:
        return 'COM';
      case SignalModule.artisan:
        return 'ART';
      case SignalModule.parts:
        return 'PRT';
      case SignalModule.mechanic:
        return 'MCH';
    }
  }
}

enum SignalPhase { broadcasting, bidding }

extension SignalPhaseX on SignalPhase {
  String get label {
    switch (this) {
      case SignalPhase.broadcasting:
        return 'BROADCASTING';
      case SignalPhase.bidding:
        return 'BIDDING';
    }
  }
}

enum SignalUrgency { standard, urgent, emergency }

class LiveSignal {
  const LiveSignal({
    required this.id,
    required this.signalCode,
    required this.module,
    required this.title,
    required this.snippet,
    required this.lga,
    required this.createdAt,
    required this.phase,
    required this.urgency,
    required this.relativeX,
    required this.relativeY,
  });

  final String id;
  final String signalCode; // e.g. "COM-9F4A"
  final SignalModule module;
  final String title;
  final String snippet;
  final String lga;
  final DateTime createdAt;
  final SignalPhase phase;
  final SignalUrgency urgency;
  final double relativeX; // 0..1 within radar grid
  final double relativeY; // 0..1 within radar grid
}

/// Map id → deterministic position in the [0,1] radar grid, biased away from
/// the centre so a freshly seeded list doesn't pile up at (0.5, 0.5).
({double x, double y}) _plot(String id) {
  // FNV-1a-ish 32-bit folding hash on the id codepoints.
  var h = 2166136261;
  for (final c in id.codeUnits) {
    h = (h ^ c) & 0xFFFFFFFF;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  final xRaw = ((h >> 16) & 0xFFFF) / 0xFFFF;
  final yRaw = (h & 0xFFFF) / 0xFFFF;
  // Squeeze into [0.08, 0.92] so dots never sit on the edge.
  return (
    x: 0.08 + xRaw * 0.84,
    y: 0.08 + yRaw * 0.84,
  );
}

String _code(SignalModule module, String id) {
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return '${module.prefix}-${h.toRadixString(16).padLeft(4, '0').toUpperCase().substring(0, 4)}';
}

SignalPhase _phase(bool broadcasting) =>
    broadcasting ? SignalPhase.broadcasting : SignalPhase.bidding;

SignalUrgency _mapArtisan(Urgency u) {
  return switch (u) {
    Urgency.routine => SignalUrgency.standard,
    Urgency.urgent => SignalUrgency.urgent,
    Urgency.emergency => SignalUrgency.emergency,
  };
}

SignalUrgency _mapMech(MechUrgency u) {
  return switch (u) {
    MechUrgency.routine => SignalUrgency.standard,
    MechUrgency.urgent => SignalUrgency.urgent,
    MechUrgency.emergency => SignalUrgency.emergency,
  };
}

final liveSignalsProvider = Provider<List<LiveSignal>>((ref) {
  final errands = ref.watch(errandControllerProvider);
  final jobs = ref.watch(artisanControllerProvider);
  final parts = ref.watch(partsControllerProvider);
  final mechs = ref.watch(mechanicControllerProvider);

  final out = <LiveSignal>[];

  for (final e in errands) {
    if (e.status != ErrandStatus.broadcasting &&
        e.status != ErrandStatus.bidsIn) {
      continue;
    }
    final pos = _plot(e.id);
    out.add(LiveSignal(
      id: e.id,
      signalCode: _code(SignalModule.errand, e.id),
      module: SignalModule.errand,
      title: e.items.take(2).join(' · '),
      snippet: 'For ${e.recipientName} · ${e.recipientAddress}',
      lga: _extractLga(e.recipientAddress),
      createdAt: e.createdAt,
      phase: _phase(e.status == ErrandStatus.broadcasting),
      urgency: SignalUrgency.standard,
      relativeX: pos.x,
      relativeY: pos.y,
    ));
  }

  for (final j in jobs) {
    if (j.status != JobStatus.broadcasting &&
        j.status != JobStatus.bidsIn) {
      continue;
    }
    final pos = _plot(j.id);
    out.add(LiveSignal(
      id: j.id,
      signalCode: _code(SignalModule.artisan, j.id),
      module: SignalModule.artisan,
      title: j.serviceTitle,
      snippet: j.description,
      lga: _extractLga(j.address),
      createdAt: j.createdAt,
      phase: _phase(j.status == JobStatus.broadcasting),
      urgency: _mapArtisan(j.urgency),
      relativeX: pos.x,
      relativeY: pos.y,
    ));
  }

  for (final p in parts) {
    if (p.status != PartStatus.broadcasting &&
        p.status != PartStatus.bidsIn) {
      continue;
    }
    final pos = _plot(p.id);
    out.add(LiveSignal(
      id: p.id,
      signalCode: _code(SignalModule.parts, p.id),
      module: SignalModule.parts,
      title: p.partName,
      snippet: '${p.vehicleLabel} · ${p.notes}',
      lga: _extractLga(p.deliverTo),
      createdAt: p.createdAt,
      phase: _phase(p.status == PartStatus.broadcasting),
      urgency: SignalUrgency.standard,
      relativeX: pos.x,
      relativeY: pos.y,
    ));
  }

  for (final m in mechs) {
    if (m.status != MechStatus.broadcasting &&
        m.status != MechStatus.offersIn) {
      continue;
    }
    final pos = _plot(m.id);
    out.add(LiveSignal(
      id: m.id,
      signalCode: _code(SignalModule.mechanic, m.id),
      module: SignalModule.mechanic,
      title: m.title,
      snippet: '${m.vehicleLabel} · ${m.address}',
      lga: _extractLga(m.address),
      createdAt: m.createdAt,
      phase: _phase(m.status == MechStatus.broadcasting),
      urgency: _mapMech(m.urgency),
      relativeX: pos.x,
      relativeY: pos.y,
    ));
  }

  // Newest first.
  out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return out;
});

String _extractLga(String address) {
  // Best-effort: pull "Wuse II" / "Garki" / "Lekki" / etc. from a free-form
  // address. Falls back to the whole string.
  final parts = address.split(',');
  if (parts.length >= 2) return parts[parts.length - 2].trim();
  return address.trim();
}
