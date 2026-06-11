import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../checkout/data/escrow_models.dart';
import '../ratings/rate_vendor_sheet.dart';
import 'state/orders_providers.dart';

final _money = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(ordersFeedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersFeedProvider),
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            // Force scrollability so pull-to-refresh works in error state.
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.slate, size: 40),
              const SizedBox(height: 12),
              const Center(child: Text('Could not load your orders')),
              const SizedBox(height: 8),
              Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(ordersFeedProvider),
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                children: const [
                  SizedBox(height: 40),
                  Center(
                    child: Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppColors.slate),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No orders yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Place an order from the marketplace to see it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate, fontSize: 12),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderTile(entry: entries[i]),
            );
          },
        ),
      ),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  const _OrderTile({required this.entry});
  final OrderEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tint = _tintForEntry(entry);
    final icon = entry.isService
        ? Icons.handyman_outlined
        : Icons.shopping_bag_outlined;
    return InkWell(
      onTap: () => _showOrderDetail(context, ref, entry),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.statusLabel,
                      style: TextStyle(
                        color: tint,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.reference,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money.format(entry.amountNgn),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: AppColors.slate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _tintForEntry(OrderEntry e) {
  if (e.escrow != null) {
    switch (e.escrow!.status) {
      case EscrowStatus.pendingFunding:
        return AppColors.warning;
      case EscrowStatus.funded:
      case EscrowStatus.partiallyReleased:
        return AppColors.emerald;
      case EscrowStatus.released:
        return AppColors.success;
      case EscrowStatus.refunded:
        return AppColors.warning;
      case EscrowStatus.disputed:
        return AppColors.danger;
      case EscrowStatus.cancelled:
        return AppColors.slate;
    }
  }
  return AppColors.emerald;
}

void _showOrderDetail(BuildContext context, WidgetRef ref, OrderEntry entry) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(entry.statusLabel,
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                _money.format(entry.amountNgn),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isService ? 'ESCROW REFERENCE' : 'PAYMENT REFERENCE',
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.reference,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEE d MMM, HH:mm').format(entry.createdAt),
                  style: const TextStyle(
                      color: AppColors.slate, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (entry.escrow != null) ...[
            Text(
              entry.escrow!.status == EscrowStatus.funded
                  ? 'Funds held in iGobi escrow. Release once the service is delivered to your satisfaction.'
                  : entry.escrow!.status == EscrowStatus.released
                      ? 'Funds released to the vendor.'
                      : 'Status: ${entry.statusLabel}',
              style: const TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ] else ...[
            const Text(
              "Direct-pay order. The vendor has been paid. If something's wrong, file a complaint and the vendor is suspended until you confirm resolution.",
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final vendorId = entry.escrow?.vendorId;
              if (vendorId == null) {
                showToast(
                  context,
                  'Rating a product order needs orders-service. Coming soon.',
                  icon: Icons.info_outline,
                );
                return;
              }
              final ok = await showRateVendorSheet(
                context,
                vendorId: vendorId,
                vendorName: 'this vendor',
                orderRef: entry.reference,
              );
              if (ok && context.mounted) {
                showToast(
                  context,
                  'Thanks — your rating helps keep iGobi honest.',
                  icon: Icons.star_rounded,
                  background: AppColors.gold,
                );
                ref.invalidate(ordersFeedProvider);
              }
            },
            icon: const Icon(Icons.star_outline_rounded, size: 16),
            label: const Text('Rate vendor'),
          ),
        ],
      ),
    ),
  );
}
