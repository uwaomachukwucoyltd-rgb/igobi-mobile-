import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advert engine — internal sponsored placements with category targeting,
/// impression + click tracking, and three native surfaces:
///   • Banner   — top-of-hub large-format
///   • Spotlight — horizontal vendor carousel
///   • Inline   — within product/service lists

enum AdSurface { banner, spotlight, inline }

enum AdAction { route, external }

class Advert {
  Advert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.surface,
    required this.targetCategory, // null = global
    required this.gradient,
    required this.icon,
    required this.action,
    required this.actionTarget, // route path OR external label
    required this.vendorName,
    required this.budgetNgn,
    required this.spentNgn,
    required this.startedAt,
    this.endsAt,
    this.paused = false,
    this.impressions = 0,
    this.clicks = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String cta;
  final AdSurface surface;
  final String? targetCategory;
  final List<Color> gradient;
  final IconData icon;
  final AdAction action;
  final String actionTarget;
  final String vendorName;
  final int budgetNgn;
  int spentNgn;
  final DateTime startedAt;
  final DateTime? endsAt;
  bool paused;
  int impressions;
  int clicks;

  bool get active {
    if (paused) return false;
    if (spentNgn >= budgetNgn) return false;
    if (endsAt != null && DateTime.now().isAfter(endsAt!)) return false;
    return true;
  }

  double get ctr => impressions == 0 ? 0 : clicks / impressions;
}

class AdvertController extends StateNotifier<List<Advert>> {
  AdvertController() : super(_seed());

  static List<Advert> _seed() {
    final now = DateTime.now();
    return [
      // BANNERS — full-width, category-targeted
      Advert(
        id: 'ad_banner_mccoy_parts',
        title: 'OEM parts · weekend rebate',
        subtitle: '5% back on first bid · ladipo bonded dealers',
        cta: 'Browse parts',
        surface: AdSurface.banner,
        targetCategory: 'McCoy Parts',
        gradient: const [Color(0xFF334155), Color(0xFF1E293B)],
        icon: Icons.precision_manufacturing_rounded,
        action: AdAction.route,
        actionTarget: '/mccoy-parts',
        vendorName: 'OEM Express NG',
        budgetNgn: 150000,
        spentNgn: 38400,
        startedAt: now.subtract(const Duration(days: 4)),
        endsAt: now.add(const Duration(days: 9)),
        impressions: 4920,
        clicks: 188,
      ),
      Advert(
        id: 'ad_banner_energy',
        title: 'Free logistics · LPG refill',
        subtitle: 'tank-to-door delivery · Lagos mainland',
        cta: 'Refill now',
        surface: AdSurface.banner,
        targetCategory: 'Energy Hub',
        gradient: const [Color(0xFFF97316), Color(0xFFC2410C)],
        icon: Icons.local_gas_station_rounded,
        action: AdAction.route,
        actionTarget: '/energy',
        vendorName: 'Sunny Petroleum',
        budgetNgn: 200000,
        spentNgn: 84200,
        startedAt: now.subtract(const Duration(days: 7)),
        endsAt: now.add(const Duration(days: 6)),
        impressions: 8104,
        clicks: 422,
      ),
      Advert(
        id: 'ad_banner_farm',
        title: 'Direct from Benue',
        subtitle: 'yam tubers · fresh harvest crate · ₦14,500',
        cta: 'Order direct',
        surface: AdSurface.banner,
        targetCategory: 'Farm Harvest',
        gradient: const [Color(0xFF65A30D), Color(0xFF3F6212)],
        icon: Icons.agriculture_rounded,
        action: AdAction.route,
        actionTarget: '/farm',
        vendorName: 'Tiv Farms Co-op',
        budgetNgn: 120000,
        spentNgn: 27800,
        startedAt: now.subtract(const Duration(days: 2)),
        endsAt: now.add(const Duration(days: 12)),
        impressions: 2410,
        clicks: 91,
      ),

      // SPOTLIGHT — vendor carousel (global)
      Advert(
        id: 'ad_spot_dufil',
        title: 'Dufil Direct',
        subtitle: 'Indomie · Power Pasta · cartons & cases',
        cta: 'Shop brand',
        surface: AdSurface.spotlight,
        targetCategory: null,
        gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
        icon: Icons.ramen_dining_outlined,
        action: AdAction.route,
        actionTarget: '/fmcg/BRAND-DUFIL',
        vendorName: 'Dufil Direct',
        budgetNgn: 90000,
        spentNgn: 41200,
        startedAt: now.subtract(const Duration(days: 5)),
        endsAt: now.add(const Duration(days: 5)),
        impressions: 5240,
        clicks: 268,
      ),
      Advert(
        id: 'ad_spot_hollandia',
        title: 'Hollandia Store',
        subtitle: 'Cold-chain dairy · same-day delivery',
        cta: 'Open store',
        surface: AdSurface.spotlight,
        targetCategory: null,
        gradient: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
        icon: Icons.icecream_outlined,
        action: AdAction.route,
        actionTarget: '/fmcg/BRAND-HOLLAND',
        vendorName: 'Hollandia Store',
        budgetNgn: 70000,
        spentNgn: 22400,
        startedAt: now.subtract(const Duration(days: 3)),
        endsAt: now.add(const Duration(days: 4)),
        impressions: 3120,
        clicks: 124,
      ),
      Advert(
        id: 'ad_spot_mccoy_mech',
        title: 'McCoy Mechanic',
        subtitle: 'Computerized scan · ₦6,000 flat',
        cta: 'Book scan',
        surface: AdSurface.spotlight,
        targetCategory: null,
        gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
        icon: Icons.car_repair_rounded,
        action: AdAction.route,
        actionTarget: '/mccoy-mechanic',
        vendorName: 'McCoy Network',
        budgetNgn: 110000,
        spentNgn: 54100,
        startedAt: now.subtract(const Duration(days: 6)),
        endsAt: now.add(const Duration(days: 8)),
        impressions: 6480,
        clicks: 340,
      ),

      // INLINE — within product/service lists
      Advert(
        id: 'ad_inline_coke',
        title: 'Coca-Cola NG',
        subtitle: 'Case of 24 · 50cl · ₦7,500',
        cta: 'Shop case',
        surface: AdSurface.inline,
        targetCategory: 'FMCG',
        gradient: const [Color(0xFFDC2626), Color(0xFF991B1B)],
        icon: Icons.local_drink_outlined,
        action: AdAction.route,
        actionTarget: '/fmcg/BRAND-COKE',
        vendorName: 'Coca-Cola NG',
        budgetNgn: 60000,
        spentNgn: 14200,
        startedAt: now.subtract(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 10)),
        impressions: 1810,
        clicks: 72,
      ),
      Advert(
        id: 'ad_inline_airgate',
        title: 'Airgate · airtime + data',
        subtitle: 'Top up any line · escrow protected',
        cta: 'Top up',
        surface: AdSurface.inline,
        targetCategory: null,
        gradient: const [Color(0xFF4F46E5), Color(0xFF312E81)],
        icon: Icons.sim_card_outlined,
        action: AdAction.external,
        actionTarget: 'airgate.ng',
        vendorName: 'Airgate NG',
        budgetNgn: 80000,
        spentNgn: 31800,
        startedAt: now.subtract(const Duration(days: 8)),
        endsAt: now.add(const Duration(days: 3)),
        impressions: 4120,
        clicks: 162,
      ),
    ];
  }

  void recordImpression(String id) {
    final i = state.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final ad = state[i];
    ad.impressions += 1;
    // 0.5% of avg CPM-equivalent — tiny spend per impression, demo-only.
    ad.spentNgn = (ad.spentNgn + 2).clamp(0, ad.budgetNgn);
    state = [...state];
  }

  void recordClick(String id) {
    final i = state.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final ad = state[i];
    ad.clicks += 1;
    // Per-click spend (~₦80) — demo numbers.
    ad.spentNgn = (ad.spentNgn + 80).clamp(0, ad.budgetNgn);
    state = [...state];
  }

  void togglePause(String id) {
    final i = state.indexWhere((a) => a.id == id);
    if (i < 0) return;
    state[i].paused = !state[i].paused;
    state = [...state];
  }
}

final advertControllerProvider =
    StateNotifierProvider<AdvertController, List<Advert>>(
  (_) => AdvertController(),
);

/// Active ads for a given surface, filtered by category. Pass `category=null`
/// for global placements (anything with no targetCategory matches).
List<Advert> adsFor({
  required List<Advert> all,
  required AdSurface surface,
  String? category,
}) {
  return all
      .where((a) => a.active && a.surface == surface)
      .where((a) =>
          a.targetCategory == null ||
          (category != null && a.targetCategory == category))
      .toList();
}
