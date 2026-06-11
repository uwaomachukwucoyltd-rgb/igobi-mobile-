import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../adverts/advert_widgets.dart';
import 'data/fmcg_api.dart';
import 'state/fmcg_state.dart';

const _indigo = Color(0xFF6366F1);
const _indigoDark = Color(0xFF4338CA);

class FMCGScreen extends ConsumerWidget {
  const FMCGScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(fmcgVendorsProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              title: const Text('FMCG'),
            ),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            const SliverToBoxAdapter(child: AdBanner(category: 'FMCG')),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.storefront, color: _indigo, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Verified brand storefronts',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Spacer(),
                    Text('online · brand-direct',
                        style: TextStyle(color: AppColors.slate, fontSize: 11)),
                  ],
                ),
              ),
            ),
            ...vendorsAsync.when(
              data: (vendors) => vendors.isEmpty
                  ? const [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Center(
                            child: Text('No storefronts listed yet.',
                                style: TextStyle(color: AppColors.slate)),
                          ),
                        ),
                      ),
                    ]
                  : [
                      SliverList.separated(
                        itemCount: vendors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _BrandCard(vendor: vendors[i]),
                        ),
                      ),
                    ],
              loading: () => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 48, 20, 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (err, _) => [
                SliverToBoxAdapter(
                  child: _LoadError(
                    onRetry: () => ref.invalidate(fmcgVendorsProvider),
                  ),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AdInline(category: 'FMCG'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigo, _indigoDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ONLINE BRAND DIRECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.inventory_2_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'FMCG — straight from the brand.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Each storefront is run by the brand or an authorised distributor. No middlemen, escrow-protected.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.vendor});
  final FMCGVendor vendor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/fmcg/${vendor.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_indigo, _indigoDark],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  vendor.iconChar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vendor.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          color: AppColors.success, size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vendor.tagline,
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 13, color: AppColors.slate),
                      const SizedBox(width: 4),
                      Text(vendor.eta,
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 11)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        vendor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _indigo),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.slate, size: 40),
            const SizedBox(height: 10),
            const Text('Could not load storefronts',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
