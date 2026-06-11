import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/brand_assets.dart';

/// Animated success indicator: white disc with the IGOBI logo-mark inside
/// (in natural colours — the JPEG's white background matches the disc, so the
/// mark reads cleanly). Around it: a soft emerald glow and two pulsing
/// concentric rings.
class SuccessLogoBurst extends StatefulWidget {
  const SuccessLogoBurst({
    super.key,
    this.size = 96,
    this.tint = AppColors.emerald,
  });

  final double size;
  final Color tint;

  @override
  State<SuccessLogoBurst> createState() => _SuccessLogoBurstState();
}

class _SuccessLogoBurstState extends State<SuccessLogoBurst>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _rings;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _entrance.forward();
    _rings.repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _rings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.8,
      height: s * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rings,
            builder: (_, __) => CustomPaint(
              size: Size.square(s * 1.8),
              painter: _RingPainter(progress: _rings.value, tint: widget.tint),
            ),
          ),
          AnimatedBuilder(
            animation: _rings,
            builder: (_, __) => CustomPaint(
              size: Size.square(s * 1.8),
              painter: _RingPainter(
                progress: ((_rings.value + 0.5) % 1.0),
                tint: widget.tint,
              ),
            ),
          ),
          Container(
            width: s * 1.2,
            height: s * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.tint.withValues(alpha: 0.25),
                  widget.tint.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _entrance,
            builder: (_, child) => Transform.scale(
              scale: 0.5 + (_scale.value * 0.5),
              child: Opacity(opacity: _fade.value, child: child),
            ),
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.tint.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(s * 0.08),
                child: ClipOval(
                  child: Image.asset(
                    BrandAssets.logoMark,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.check_rounded,
                          color: widget.tint, size: s * 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.tint});
  final double progress;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final r = (maxR * 0.35) + (maxR * 0.6 * progress);
    final alpha = (1.0 - progress).clamp(0.0, 1.0) * 0.4;
    final paint = Paint()
      ..color = tint.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(centre, r, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.tint != tint;
}
