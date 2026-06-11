import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../ratings/rate_vendor_sheet.dart';
import 'marketplace_data.dart';
import 'state/marketplace_providers.dart';
import 'widgets/product_card.dart';

class VendorDetailScreen extends ConsumerWidget {
  const VendorDetailScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorByIdProvider(vendorId));

    return vendorAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: AppColors.slate, size: 40),
                const SizedBox(height: 10),
                const Text('Could not load vendor',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(vendorByIdProvider(vendorId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (vendor) => _VendorDetailBody(vendor: vendor),
    );
  }
}

class _VendorDetailBody extends ConsumerWidget {
  const _VendorDetailBody({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByVendorProvider(vendor.id));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(vendor.name),
        actions: [
          IconButton(
            onPressed: () => showToast(
              context,
              'Saved ${vendor.name} to favorites',
              icon: Icons.favorite_rounded,
              background: AppColors.danger,
            ),
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            onPressed: () => showToast(
              context,
              'Share link copied',
              icon: Icons.link,
            ),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    vendor.name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vendor.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ),
                        if (vendor.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.success, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vendor.tagline,
                      style: const TextStyle(color: AppColors.slate, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Trust',
                  value: '${vendor.trustScore.toStringAsFixed(1)} ★',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: _Stat(label: 'Orders', value: '1.2k')),
              const SizedBox(width: 12),
              const Expanded(child: _Stat(label: 'On-time', value: '98%')),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${vendor.name} is a KYC-verified iGobi vendor in ${vendor.location}. '
            'All payments are escrow-protected — funds are released only after you confirm delivery.',
            style: const TextStyle(color: AppColors.slate, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Listings',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          productsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load listings',
                        style: TextStyle(color: AppColors.slate)),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.invalidate(productsByVendorProvider(vendor.id)),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
            data: (products) => products.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No active listings yet.',
                          style: TextStyle(color: AppColors.slate)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) =>
                        ProductCard(product: products[i]),
                  ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showMessageSheet(context, vendor),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message vendor'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showStartOrderSheet(context, vendor),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Start an order'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showRateVendorSheet(
                context,
                vendorId: vendor.id,
                vendorName: vendor.name,
              );
              if (ok && context.mounted) {
                showToast(
                  context,
                  'Thanks — your rating helps keep iGobi honest.',
                  icon: Icons.star_rounded,
                  background: AppColors.gold,
                );
              }
            },
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Rate vendor'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.slate, fontSize: 11)),
        ],
      ),
    );
  }
}

void _showMessageSheet(BuildContext context, Vendor vendor) {
  final controller = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                    child: Text(
                      vendor.name[0],
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const Text('Usually replies within 1 hour',
                            style: TextStyle(color: AppColors.slate, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slateLight),
                ),
                child: const Text(
                  "Hi! Welcome to our shop. Let us know what you're looking for and we'll respond with availability and pricing.",
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.aiBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.aiBlue),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Vanguard will draft replies in your inbox while you\'re away.',
                        style: TextStyle(fontSize: 12, color: AppColors.charcoalSoft),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(color: AppColors.slate),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showToast(
                      context,
                      'Message sent to ${vendor.name}',
                      icon: Icons.send_rounded,
                      background: AppColors.emerald,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showStartOrderSheet(BuildContext context, Vendor vendor) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
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
          const Text('Start an order',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 4),
          Text('with ${vendor.name}',
              style: const TextStyle(color: AppColors.slate, fontSize: 13)),
          const SizedBox(height: 18),
          _OrderOption(
            icon: Icons.list_alt_rounded,
            tint: AppColors.emerald,
            title: 'Browse their listings',
            body: 'Add items below to your cart and place an escrow-protected order.',
            onTap: () {
              Navigator.pop(sheetContext);
              showToast(
                context,
                'Scroll down to add their products to your cart',
                icon: Icons.arrow_downward_rounded,
                background: AppColors.emerald,
              );
            },
          ),
          const SizedBox(height: 10),
          _OrderOption(
            icon: Icons.edit_outlined,
            tint: AppColors.gold,
            title: 'Custom request',
            body: 'Send a brief — they\'ll quote and we\'ll hold funds in escrow.',
            onTap: () {
              Navigator.pop(sheetContext);
              showToast(
                context,
                'Custom request form coming soon',
                icon: Icons.edit_outlined,
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _OrderOption extends StatelessWidget {
  const _OrderOption({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.onTap,
  });
  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: const TextStyle(color: AppColors.slate, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
      ),
    );
  }
}
