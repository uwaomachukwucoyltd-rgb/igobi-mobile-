import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../profile/widgets/hub_lock_strip.dart';
import 'data/farm_api.dart';
import 'state/farm_state.dart';

class FarmHarvestScreen extends ConsumerStatefulWidget {
  const FarmHarvestScreen({super.key});
  @override
  ConsumerState<FarmHarvestScreen> createState() => _FarmHarvestScreenState();
}

class _FarmHarvestScreenState extends ConsumerState<FarmHarvestScreen> {
  String? _regionFilter;
  String _query = '';

  static const _farmLime = Color(0xFF65A30D);

  List<String> _regions(List<FarmNode> nodes) {
    final set = nodes.map((n) => n.region).toSet().toList()..sort();
    return set;
  }

  List<FarmNode> _filtered(List<FarmNode> nodes) {
    return nodes.where((n) {
      if (_regionFilter != null && n.region != _regionFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return n.name.toLowerCase().contains(q) ||
          n.lga.toLowerCase().contains(q) ||
          n.state.toLowerCase().contains(q) ||
          n.specialties.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(farmNodesProvider);
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
              title: const Text('Farm Harvest'),
            ),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: NationalReachStrip()),
            const SliverToBoxAdapter(child: _DispatchFeeStrip()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  style:
                      const TextStyle(color: AppColors.charcoal, fontSize: 14),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search produce, LGA, or state…',
                    hintStyle: TextStyle(color: AppColors.slate),
                    prefixIcon: Icon(Icons.search, color: AppColors.slate),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _RegionChip(
                      label: 'All regions',
                      active: _regionFilter == null,
                      onTap: () => setState(() => _regionFilter = null),
                    ),
                    for (final r in nodesAsync.maybeWhen(
                      data: _regions,
                      orElse: () => const <String>[],
                    )) ...[
                      const SizedBox(width: 8),
                      _RegionChip(
                        label: r,
                        active: _regionFilter == r,
                        onTap: () => setState(() => _regionFilter = r),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ...nodesAsync.when(
              data: (nodes) {
                final filtered = _filtered(nodes);
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.agriculture_rounded,
                              color: _farmLime, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Verified farm clusters',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const Spacer(),
                          Text('${filtered.length} nodes',
                              style: const TextStyle(
                                  color: AppColors.slate, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
                        child: Center(
                          child: Text(
                            'No clusters match this filter.',
                            style: TextStyle(color: AppColors.slate),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _FarmCard(farm: filtered[i]),
                      ),
                    ),
                ];
              },
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
                    onRetry: () => ref.invalidate(farmNodesProvider),
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF65A30D), Color(0xFF4D7C0F)],
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
                  'DIRECT-TO-FARM PROTOCOL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.agriculture_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Verified clusters · batch-tracked\nharvest · escrow secured.',
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
            'Sourced from rural farm hubs across Nigeria — each batch tagged with origin LGA, harvest date, and a verified vendor node.',
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

class _DispatchFeeStrip extends StatelessWidget {
  const _DispatchFeeStrip();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: AppColors.gold, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, height: 1.4),
                children: [
                  TextSpan(
                    text: '₦3,500 Local Dispatch fee · ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldDark,
                    ),
                  ),
                  TextSpan(
                    text:
                        'flat across the National Reach Network, covers logistics from farm hub to your door.',
                    style: TextStyle(color: AppColors.charcoalSoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF65A30D)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF65A30D)
                : AppColors.slateLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.charcoal,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm});
  final FarmNode farm;
  static const _farmLime = Color(0xFF65A30D);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/farm/${farm.id}'),
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
                    color: _farmLime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.agriculture_rounded,
                      color: _farmLime),
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
                              farm.name,
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
                        '${farm.lga} LGA · ${farm.state} · ${farm.region}',
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 11),
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
                        farm.rating.toStringAsFixed(1),
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
              farm.description,
              style: const TextStyle(
                  color: AppColors.charcoalSoft, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in farm.specialties)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _farmLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            color: _farmLimeDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          color: AppColors.emerald, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'ESCROW ACTIVE',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text('Enter cluster',
                    style: TextStyle(
                      color: _farmLime,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
                const Icon(Icons.chevron_right, color: _farmLime),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _farmLimeDark = Color(0xFF4D7C0F);
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
            const Text('Could not load farm clusters',
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
