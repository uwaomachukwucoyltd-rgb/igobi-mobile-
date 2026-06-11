import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/brand_assets.dart';

/// The IGOBI Concierge mascot: the logo-mark inside a small white tile.
/// The JPEG's baked-in white background blends with the tile, so the brand
/// mark reads as a clean icon on whatever surface this sits on.
class MascotAvatar extends StatelessWidget {
  const MascotAvatar({
    super.key,
    this.size = 28,
    this.ringTint,
    this.shadow = true,
  });
  final double size;
  final Color? ringTint;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: ringTint != null
            ? Border.all(color: ringTint!, width: 1.5)
            : null,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: Image.asset(
          BrandAssets.logoMark,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(Icons.auto_awesome,
                color: AppColors.emerald, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}
