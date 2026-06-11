import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_sheet.dart';
import '../marketplace/marketplace_data.dart';
import 'data/store_api.dart';
import 'state/store_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

class StoreDetailScreen extends ConsumerWidget {
  const StoreDetailScreen({super.key, required this.storeId});
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storeNodesProvider);
    return storesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: _DetailError(
          message: 'Could not load this store',
          onRetry: () => ref.invalidate(storeNodesProvider),
        ),
      ),
      data: (stores) {
        final store = stores.firstWhere(
          (s) => s.id == storeId,
          orElse: () => stores.isNotEmpty
              ? stores.first
              : throw StateError('No stores'),
        );
        return _StoreDetailBody(store: store);
      },
    );
  }
}

class _StoreDetailBody extends ConsumerWidget {
  const _StoreDetailBody({required this.store});
  final StoreNode store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(storeInventoryProvider(store.id));
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
              title: Text(store.name),
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
            SliverToBoxAdapter(child: _StoreHeader(store: store)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Inventory',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(this store only)',
                      style: TextStyle(color: AppColors.slate, fontSize: 11),
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
                              'This store has no inventory listed yet.',
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
                          child: _InventoryRow(
                            item: inventory[i],
                            storeName: store.name,
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
                    message: 'Could not load inventory',
                    onRetry: () =>
                        ref.invalidate(storeInventoryProvider(store.id)),
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

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store});
  final StoreNode store;
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
                                  'VERIFIED NODE',
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.id,
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
                          store.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      store.eta,
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
                    store.location,
                    style: const TextStyle(
                        color: AppColors.charcoalSoft, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              store.description,
              style: const TextStyle(
                  color: AppColors.charcoalSoft, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryRow extends ConsumerWidget {
  const _InventoryRow({required this.item, required this.storeName});
  final StoreProduct item;
  final String storeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = item.inStock <= 10;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.slateLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.unit,
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.slateLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.sku,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _money.format(item.priceNgn),
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: lowStock
                            ? AppColors.warning.withValues(alpha: 0.12)
                            : AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lowStock
                            ? '${item.inStock} left'
                            : 'In stock',
                        style: TextStyle(
                          color: lowStock
                              ? AppColors.warning
                              : AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              // Bridge into the existing global cart by minting a Product.
              final p = Product(
                id: 'store_${item.sku}',
                name: item.name,
                vendorId: 'v_conv_${item.sku}',
                category: 'Convenience',
                productType: ProductType.physical,
                priceNgn: item.priceNgn,
                unit: item.unit,
                emoji: item.emoji,
              );
              ref.read(cartControllerProvider.notifier).add(p);
              showToast(
                context,
                'Added ${item.name} · $storeName',
                icon: Icons.shopping_bag_outlined,
                background: AppColors.aiBlue,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.aiBlue,
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
