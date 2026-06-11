import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'state/advert_state.dart';

// ============================================================
// Common helpers
// ============================================================

void _handleTap(BuildContext context, WidgetRef ref, Advert ad) {
  ref.read(advertControllerProvider.notifier).recordClick(ad.id);
  switch (ad.action) {
    case AdAction.route:
      context.push(ad.actionTarget);
    case AdAction.external:
      showToast(
        context,
        'Opening ${ad.actionTarget}',
        icon: Icons.open_in_new,
        background: AppColors.aiBlue,
      );
  }
}

class _Sponsored extends StatelessWidget {
  const _Sponsored({this.tone = Colors.white});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'SPONSORED',
        style: TextStyle(
          color: tone,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ============================================================
// Banner — large format, top-of-hub
// ============================================================

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key, this.category});
  final String? category;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  String? _impressedId;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(advertControllerProvider);
    final ads = adsFor(
        all: all, surface: AdSurface.banner, category: widget.category);
    if (ads.isEmpty) return const SizedBox.shrink();
    final ad = ads.first;

    if (_impressedId != ad.id) {
      _impressedId = ad.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(advertControllerProvider.notifier).recordImpression(ad.id);
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: InkWell(
        onTap: () => _handleTap(context, ref, ad),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ad.gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ad.gradient.first.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(ad.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Sponsored(),
                        const SizedBox(width: 6),
                        Text(
                          'by ${ad.vendorName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ad.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ad.cta,
                  style: TextStyle(
                    color: ad.gradient.last,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Spotlight — horizontal vendor carousel
// ============================================================

class AdSpotlight extends ConsumerStatefulWidget {
  const AdSpotlight({super.key, this.category, this.height = 130});
  final String? category;
  final double height;

  @override
  ConsumerState<AdSpotlight> createState() => _AdSpotlightState();
}

class _AdSpotlightState extends ConsumerState<AdSpotlight> {
  final Set<String> _impressed = {};

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(advertControllerProvider);
    final ads = adsFor(
        all: all, surface: AdSurface.spotlight, category: widget.category);
    if (ads.isEmpty) return const SizedBox.shrink();

    for (final ad in ads) {
      if (!_impressed.contains(ad.id)) {
        _impressed.add(ad.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(advertControllerProvider.notifier).recordImpression(ad.id);
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Row(
            children: [
              Text(
                'Vendor Spotlight',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              _Sponsored(tone: AppColors.slate),
            ],
          ),
        ),
        SizedBox(
          height: widget.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _SpotlightCard(ad: ads[i]),
          ),
        ),
      ],
    );
  }
}

class _SpotlightCard extends ConsumerWidget {
  const _SpotlightCard({required this.ad});
  final Advert ad;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _handleTap(context, ref, ad),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: ad.gradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(ad.icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
                const _Sponsored(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ad.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              ad.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ad.cta,
                style: TextStyle(
                  color: ad.gradient.last,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Inline — slots inside lists
// ============================================================

class AdInline extends ConsumerStatefulWidget {
  const AdInline({super.key, this.category});
  final String? category;

  @override
  ConsumerState<AdInline> createState() => _AdInlineState();
}

class _AdInlineState extends ConsumerState<AdInline> {
  String? _impressedId;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(advertControllerProvider);
    final ads = adsFor(
        all: all, surface: AdSurface.inline, category: widget.category);
    if (ads.isEmpty) return const SizedBox.shrink();
    final ad = ads.first;

    if (_impressedId != ad.id) {
      _impressedId = ad.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(advertControllerProvider.notifier).recordImpression(ad.id);
      });
    }

    return InkWell(
      onTap: () => _handleTap(context, ref, ad),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: ad.gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ad.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Sponsored(tone: ad.gradient.last),
                      const SizedBox(width: 6),
                      Text(
                        ad.vendorName,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ad.subtitle,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ad.gradient.last,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ad.cta,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
