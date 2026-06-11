import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'live_feed_state.dart';

const _slate = Color(0xFF0F172A);
const _slateMid = Color(0xFF1E293B);
const _slateLine = Color(0xFF334155);
const _emerald = AppColors.emerald;
const _orange = Color(0xFFF97316);
const _rose = Color(0xFFE11D48);

Color _urgencyColor(SignalUrgency u) => switch (u) {
      SignalUrgency.standard => _emerald,
      SignalUrgency.urgent => _orange,
      SignalUrgency.emergency => _rose,
    };

/// Compact radar widget for the marketplace home / vendor command-center.
/// Renders all active BROADCASTING / BIDDING signals as pulsing dots over a
/// scanning grid. Tap a dot → bottom-anchored signal detail.
class LiveNodeFeed extends ConsumerStatefulWidget {
  const LiveNodeFeed({super.key, this.height = 220});
  final double height;

  @override
  ConsumerState<LiveNodeFeed> createState() => _LiveNodeFeedState();
}

class _LiveNodeFeedState extends ConsumerState<LiveNodeFeed>
    with TickerProviderStateMixin {
  late final AnimationController _sweep;
  late final AnimationController _pulse;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signals = ref.watch(liveSignalsProvider);
    final selected = _selectedId == null
        ? null
        : signals.where((s) => s.id == _selectedId).cast<LiveSignal?>().firstWhere(
              (s) => true,
              orElse: () => null,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_slate, _slateMid],
            ),
          ),
          child: Column(
            children: [
              _Header(count: signals.length),
              SizedBox(
                height: widget.height,
                child: LayoutBuilder(builder: (_, c) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _RadarBackdrop(controller: _sweep),
                      for (final s in signals)
                        _Dot(
                          signal: s,
                          width: c.maxWidth,
                          height: c.maxHeight,
                          pulse: _pulse,
                          selected: _selectedId == s.id,
                          onTap: () => setState(() {
                            _selectedId =
                                _selectedId == s.id ? null : s.id;
                          }),
                        ),
                      if (signals.isEmpty)
                        const Center(
                          child: Text(
                            'No active signals.\nNetwork is quiet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              if (selected != null) _SignalDetail(signal: selected),
              if (selected == null) const _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _emerald,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _emerald.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE NODE FEED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _emerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count active',
              style: const TextStyle(
                color: _emerald,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarBackdrop extends StatelessWidget {
  const _RadarBackdrop({required this.controller});
  final AnimationController controller;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _RadarPainter(progress: controller.value),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines.
    final grid = Paint()
      ..color = _slateLine.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;
    const cols = 6;
    const rows = 4;
    for (var i = 1; i < cols; i++) {
      final x = w * i / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var i = 1; i < rows; i++) {
      final y = h * i / rows;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // Concentric range rings centred on the radar.
    final center = Offset(w / 2, h / 2);
    final maxR = math.min(w, h) * 0.45;
    final ring = Paint()
      ..color = _emerald.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxR * i / 3, ring);
    }

    // Crosshair through centre.
    final cross = Paint()
      ..color = _emerald.withValues(alpha: 0.25)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, h), cross);
    canvas.drawLine(Offset(0, center.dy), Offset(w, center.dy), cross);

    // Scanning sweep — a thin wedge that rotates.
    final sweepAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.35,
        endAngle: sweepAngle,
        colors: [
          _emerald.withValues(alpha: 0.0),
          _emerald.withValues(alpha: 0.45),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.signal,
    required this.width,
    required this.height,
    required this.pulse,
    required this.selected,
    required this.onTap,
  });
  final LiveSignal signal;
  final double width;
  final double height;
  final AnimationController pulse;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(signal.urgency);
    final dx = signal.relativeX * width;
    final dy = signal.relativeY * height;
    return Positioned(
      left: dx - 14,
      top: dy - 14,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedBuilder(
          animation: pulse,
          builder: (_, __) {
            final glow = 0.3 + 0.7 * pulse.value;
            final ringScale = 1.0 + 0.4 * pulse.value;
            return SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 22 * ringScale,
                    height: 22 * ringScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.5 * (1 - pulse.value)),
                        width: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    width: selected ? 12 : 9,
                    height: selected ? 12 : 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: glow),
                          blurRadius: 10,
                        ),
                      ],
                      border: selected
                          ? Border.all(color: Colors.white, width: 1.5)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: const Row(
        children: [
          _LegendDot(color: _emerald, label: 'Standard'),
          SizedBox(width: 12),
          _LegendDot(color: _orange, label: 'Urgent'),
          SizedBox(width: 12),
          _LegendDot(color: _rose, label: 'Emergency'),
          Spacer(),
          Text(
            'Tap a node',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _SignalDetail extends StatelessWidget {
  const _SignalDetail({required this.signal});
  final LiveSignal signal;
  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(signal.urgency);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: const Border(top: BorderSide(color: _slateLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  signal.phase.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  signal.module.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                signal.signalCode,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            signal.title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            signal.snippet,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.white54, size: 12),
              const SizedBox(width: 4),
              Text(
                signal.lga,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _openModule(context, signal.module),
                child: Text(
                  'Open ${signal.module.label} →',
                  style: const TextStyle(
                    color: _emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openModule(BuildContext context, SignalModule m) {
    final path = switch (m) {
      SignalModule.errand => '/community',
      SignalModule.artisan => '/artisan',
      SignalModule.parts => '/mccoy-parts',
      SignalModule.mechanic => '/mccoy-mechanic',
    };
    context.push(path);
  }
}
