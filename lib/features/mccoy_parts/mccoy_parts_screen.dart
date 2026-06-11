import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'mccoy_parts_flows.dart';
import 'state/parts_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

const _slate = Color(0xFF334155);
const _slateDark = Color(0xFF1E293B);
const _emerald = AppColors.emerald;

class McCoyPartsScreen extends ConsumerWidget {
  const McCoyPartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(partsControllerProvider);
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
              title: const Text('McCoy Auto Parts'),
              actions: [
                IconButton(
                  onPressed: () => showToast(
                    context,
                    'OEM dealers across 9 industrial nodes. Fitment verified by McCoy Mechanics.',
                    icon: Icons.precision_manufacturing_rounded,
                    background: _slate,
                  ),
                  icon: const Icon(Icons.help_outline_rounded),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: _BroadcastCta()),
            const SliverToBoxAdapter(child: _NodeNetworkStrip()),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Your active part requests',
                trailing: requests.isEmpty
                    ? null
                    : Text('${requests.length} active',
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12)),
              ),
            ),
            if (requests.isEmpty)
              const SliverToBoxAdapter(child: _EmptyRequests())
            else
              SliverList.separated(
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _RequestCard(request: requests[i]),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Protocol')),
            const SliverToBoxAdapter(child: _Protocol()),
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
          colors: [_slate, _slateDark],
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
                  color: _emerald.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radio_button_checked,
                        size: 10, color: _emerald),
                    SizedBox(width: 6),
                    Text(
                      'TECHNICAL DISPATCH NODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.precision_manufacturing_rounded,
                  color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'OEM parts, sourced via\nbroadcast & bid.',
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
            'Specify make · model · year · part. Verified dealers across industrial nodes bid live. Escrow is held until a McCoy Mechanic performs FITMENT VERIFICATION.',
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

class _BroadcastCta extends StatelessWidget {
  const _BroadcastCta();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 58,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_emerald, AppColors.emeraldDark],
            ),
            boxShadow: [
              BoxShadow(
                color: _emerald.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showPartBroadcastSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broadcast_on_personal,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Broadcast a part request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeNetworkStrip extends StatefulWidget {
  const _NodeNetworkStrip();
  @override
  State<_NodeNetworkStrip> createState() => _NodeNetworkStripState();
}

class _NodeNetworkStripState extends State<_NodeNetworkStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _slateDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _slate),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: 0.4 + 0.6 * _c.value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _emerald.withValues(alpha: 0.6 * _c.value),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'RADIO',
              style: TextStyle(
                color: _emerald,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '9 industrial nodes online · 1,247 dealers listening',
                style: TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.signal_cellular_alt,
                color: _emerald, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: const Row(
          children: [
            Icon(Icons.inventory_outlined, color: _slate),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No part requests yet. Broadcast a part and verified dealers in your sector will bid within minutes.',
                style: TextStyle(color: AppColors.slate, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});
  final PartRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => showPartDetail(context, request.id),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _slate.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.precision_manufacturing_rounded,
                      color: _slate, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.partName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        request.vehicleLabel,
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
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (request.acceptedBid != null) ...[
                  const Icon(Icons.payments_outlined,
                      size: 13, color: AppColors.slate),
                  const SizedBox(width: 4),
                  Text(
                    _money.format(request.acceptedBid!.priceNgn),
                    style: const TextStyle(
                      color: _emerald,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (request.budgetNgn != null) ...[
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 13, color: AppColors.slate),
                  const SizedBox(width: 4),
                  Text(
                    'Budget ${_money.format(request.budgetNgn)}',
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (request.heldEscrowRef != null) ...[
                  const Icon(Icons.lock_clock_outlined,
                      size: 13, color: AppColors.slate),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      request.heldEscrowRef!,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${request.bids.length} bid${request.bids.length == 1 ? "" : "s"}',
                    style:
                        const TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                ],
              ],
            ),
            if (request.status == PartStatus.awaitingFitment &&
                request.verifierName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _emerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: _emerald, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Fitment check by ${request.verifierName}',
                        style: const TextStyle(
                          color: _emerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final PartStatus status;
  @override
  Widget build(BuildContext context) {
    final c = switch (status) {
      PartStatus.broadcasting => _slate,
      PartStatus.bidsIn => Colors.indigo,
      PartStatus.awarded => Colors.amber.shade800,
      PartStatus.awaitingFitment => Colors.deepOrange,
      PartStatus.fitmentVerified => _emerald,
      PartStatus.confirmed => _emerald,
      PartStatus.cancelled => Colors.redAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Protocol extends StatelessWidget {
  const _Protocol();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          _Step(
              n: '1',
              title: 'Broadcast',
              body:
                  'Specify make · model · year · part name. Request fans out to verified dealers.'),
          _Step(
              n: '2',
              title: 'Bids in',
              body:
                  'Dealers respond with condition (OEM / Aftermarket / Refurbished), price, warranty and ETA.'),
          _Step(
              n: '3',
              title: 'Award & escrow',
              body:
                  'You accept a bid · escrow is locked · dealer ships to the McCoy Node.'),
          _Step(
              n: '4',
              title: 'Fitment verification',
              body:
                  'A McCoy Mechanic Node inspects the part on your vehicle. Wrong part → dealer eats the swap.'),
          _Step(
              n: '5',
              title: 'Release',
              body:
                  'Once fitment is verified, escrow releases to the dealer. You confirm receipt.'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.body});
  final String n;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _slate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  n,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
