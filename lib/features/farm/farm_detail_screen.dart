import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_sheet.dart';
import '../marketplace/marketplace_data.dart';
import 'data/farm_api.dart';
import 'state/farm_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

const _farmLime = Color(0xFF65A30D);
const _farmLimeDark = Color(0xFF4D7C0F);

class FarmDetailScreen extends ConsumerWidget {
  const FarmDetailScreen({super.key, required this.farmId});
  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(farmNodesProvider);
    return nodesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: _DetailError(
          message: 'Could not load this cluster',
          onRetry: () => ref.invalidate(farmNodesProvider),
        ),
      ),
      data: (nodes) {
        final farm = nodes.firstWhere(
          (f) => f.id == farmId,
          orElse: () => nodes.isNotEmpty
              ? nodes.first
              : throw StateError('No farm nodes'),
        );
        return _FarmDetailBody(farm: farm);
      },
    );
  }
}

class _FarmDetailBody extends ConsumerWidget {
  const _FarmDetailBody({required this.farm});
  final FarmNode farm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(farmInventoryProvider(farm.id));
    final inventory = inventoryAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <FarmProduct>[],
    );
    final cart = ref.watch(cartControllerProvider);

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
              title: Text(farm.name),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      onPressed: () => showCartSheet(context),
                    ),
                    if (cart.count > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.softWhite, width: 2),
                          ),
                          child: Text(
                            '${cart.count}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(child: _FarmHeader(farm: farm)),
            const SliverToBoxAdapter(child: _IntegrityStrip()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const Text(
                      'This cluster\'s harvest',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${inventory.length} batches',
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            ...inventoryAsync.when(
              data: (inventory) => inventory.isEmpty
                  ? const [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Center(
                            child: Text(
                              'This cluster has no batches listed yet.',
                              style: TextStyle(color: AppColors.slate),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : [
                      SliverList.separated(
                        itemCount: inventory.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ProduceRow(
                            item: inventory[i],
                            farm: farm,
                          ),
                        ),
                      ),
                    ],
              loading: () => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 40, 20, 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (err, _) => [
                SliverToBoxAdapter(
                  child: _DetailError(
                    message: 'Could not load harvest',
                    onRetry: () =>
                        ref.invalidate(farmInventoryProvider(farm.id)),
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

class _FarmHeader extends StatelessWidget {
  const _FarmHeader({required this.farm});
  final FarmNode farm;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                color: AppColors.success, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED FARM NODE',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        farm.id,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          farm.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      farm.region,
                      style:
                          const TextStyle(color: AppColors.slate, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.slate, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Verified from ${farm.lga}, ${farm.state}',
                    style: const TextStyle(
                        color: AppColors.charcoalSoft, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              farm.description,
              style: const TextStyle(
                  color: AppColors.charcoalSoft, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.slate, size: 40),
            const SizedBox(height: 10),
            Text(message,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
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

class _IntegrityStrip extends StatelessWidget {
  const _IntegrityStrip();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withValues(alpha: 0.08),
            AppColors.gold.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.emerald, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, height: 1.5),
                children: [
                  TextSpan(
                    text: 'Integrity Protocol · ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                  TextSpan(
                    text:
                        'mandatory escrow + batch-tracked sourcing. Funds release only on receipt and quality confirmation.',
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

class _ProduceRow extends ConsumerWidget {
  const _ProduceRow({required this.item, required this.farm});
  final FarmProduct item;
  final FarmNode farm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _farmLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _farmLime.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.unit,
                        style: const TextStyle(
                          color: _farmLimeDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Harvested ${item.harvestedAt}',
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.tag, size: 11, color: AppColors.slate),
                    const SizedBox(width: 3),
                    Text(
                      item.batchId,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _money.format(item.priceNgn),
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ESCROW ACTIVE',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              final p = Product(
                id: 'farm_${item.sku}',
                name: item.name,
                vendorId: farm.vendorId,
                category: 'Farm Harvest',
                productType: ProductType.physical,
                priceNgn: item.priceNgn,
                unit: item.unit,
                emoji: item.emoji,
              );
              ref.read(cartControllerProvider.notifier).add(p);
              showToast(
                context,
                'Added ${item.name} · ${farm.lga}',
                icon: Icons.agriculture_rounded,
                background: _farmLime,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _farmLime,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
