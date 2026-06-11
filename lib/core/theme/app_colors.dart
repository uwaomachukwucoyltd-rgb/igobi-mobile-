import 'package:flutter/material.dart';

/// IGOBI brand palette.
/// Emerald + warm gold on charcoal/soft-white, with electric blue reserved
/// for AI-driven surfaces.
class AppColors {
  AppColors._();

  // Primary
  static const Color emerald = Color(0xFF047857);
  static const Color emeraldDark = Color(0xFF065F46);
  static const Color emeraldLight = Color(0xFF10B981);

  // Secondary
  static const Color gold = Color(0xFFD4A24C);
  static const Color goldDark = Color(0xFFB8862F);
  static const Color goldLight = Color(0xFFEFC97A);

  // Neutrals
  static const Color charcoal = Color(0xFF1F2937);
  static const Color charcoalSoft = Color(0xFF374151);
  static const Color softWhite = Color(0xFFFAFAF7);
  static const Color slate = Color(0xFF6B7280);
  static const Color slateLight = Color(0xFFE5E7EB);

  // AI surfaces
  static const Color aiBlue = Color(0xFF4F46E5);
  static const Color aiBlueLight = Color(0xFF818CF8);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
}
