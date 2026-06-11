import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../profile/widgets/hub_lock_strip.dart';
import 'data/store_api.dart';
import 'state/store_state.dart';

class ConvenienceScreen extends ConsumerWidget {
  const ConvenienceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storeNodesProvider);
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
              title: const Text('Convenience'),
            ),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(
              child: HubLockStrip(tone: Color(0xFF0EA5E9)),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: AppColors.aiBlue, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Stores near you',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Spacer(),
                    Text('within 5 km',
                        style: TextStyle(color: AppColors.slate, fontSize: 11)),
                  ],
                ),
              ),
            ),
            ...storesAsync.when(
              data: (stores) => stores.isEmpty
                  ? const [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Center(
                            child: Text('No stores near you yet.',
                                style: TextStyle(color: AppColors.slate)),
                          ),
                        ),
                      ),
                    ]
                  : [
                      SliverList.separated(
                        itemCount: stores.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _StoreCard(store: stores[i]),
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
                    onRetry: () => ref.invalidate(storeNodesProvider),
                  ),
                ),
              ],
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.aiBlue, Color(0xFF0369A1)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MULTI-STORE NETWORK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.local_convenience_store_outlined,
                  color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Independent physical stores —\nverified, geofenced, fast.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Each store is a verified node with its own inventory. Tap one to enter and shop only its stock.',
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

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});
  final StoreNode store;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/store/${store.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.aiBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_convenience_store,
                      color: AppColors.aiBlue),
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
                              store.name,
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
                        store.location,
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              store.description,
              style: const TextStyle(color: AppColors.charcoalSoft, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in store.specialties)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.slateLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            color: AppColors.charcoalSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: AppColors.slate),
                const SizedBox(width: 4),
                Text(store.eta,
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 12)),
                const Spacer(),
                const Text('Enter store',
                    style: TextStyle(
                      color: AppColors.aiBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
                const Icon(Icons.chevron_right, color: AppColors.aiBlue),
              ],
            ),
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
            const Text('Could not load stores',
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
