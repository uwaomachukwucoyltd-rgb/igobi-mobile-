import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../profile/widgets/hub_lock_strip.dart';
import 'community_flows.dart';
import 'state/errand_state.dart';

final _money = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

class CommunityMarketScreen extends ConsumerWidget {
  const CommunityMarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errands = ref.watch(errandControllerProvider);
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
              title: const Text('Community Market'),
              actions: [
                IconButton(
                  onPressed: () => showToast(
                    context,
                    'Runners reachable in 12 LGAs · 1,247 verified',
                    icon: Icons.verified_user_outlined,
                    background: AppColors.gold,
                  ),
                  icon: const Icon(Icons.help_outline_rounded),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: HubLockStrip(tone: AppColors.gold)),
            const SliverToBoxAdapter(child: _StartCta()),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Your active errands',
                trailing: errands.isEmpty
                    ? null
                    : Text('${errands.length} active',
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12)),
              ),
            ),
            if (errands.isEmpty)
              const SliverToBoxAdapter(child: _EmptyErrands())
            else
              SliverList.separated(
                itemCount: errands.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ErrandCard(errand: errands[i]),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'How it works'),
            ),
            const SliverToBoxAdapter(child: _HowItWorks()),
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
          colors: [AppColors.gold, Color(0xFFB8862F)],
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
                  'ERRAND-ON-DEMAND',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.diversity_3_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Broadcast what you need from\nyour local Nigerian market.',
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
            'Verified runners bid · funds held in escrow · released only when your recipient confirms receipt.',
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

class _StartCta extends StatelessWidget {
  const _StartCta();

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
              colors: [AppColors.emerald, AppColors.emeraldDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showBroadcastSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Broadcast a new errand',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _EmptyErrands extends StatelessWidget {
  const _EmptyErrands();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: const Center(
          child: Text(
            'No active errands. Broadcast your first to see runners bid in seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 13, height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ErrandCard extends ConsumerWidget {
  const _ErrandCard({required this.errand});
  final Errand errand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = _toneFor(errand.status);
    final label = _labelFor(errand.status);
    return InkWell(
      onTap: () => showErrandDetail(context, errand.id),
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
                _StatusChip(tone: tone, label: label),
                const Spacer(),
                Text(
                  DateFormat('h:mm a').format(errand.createdAt),
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              errand.items.join(' · '),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.slate, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${errand.recipientName} · ${errand.recipientAddress}',
                    style:
                        const TextStyle(color: AppColors.slate, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (errand.status == ErrandStatus.broadcasting) ...[
              const SizedBox(height: 12),
              const _BroadcastingStrip(),
            ] else if (errand.status == ErrandStatus.bidsIn) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.gavel_rounded,
                      color: AppColors.gold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${errand.bids.length} runner bids — tap to choose',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else if (errand.acceptedBid != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          errand.acceptedBid!.runnerName[0],
                          style: TextStyle(
                            color: tone,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${errand.acceptedBid!.runnerName} · ${_money.format(errand.acceptedBid!.priceNgn)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${errand.acceptedBid!.etaMin} min',
                      style:
                          const TextStyle(color: AppColors.slate, fontSize: 12),
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

  static Color _toneFor(ErrandStatus s) {
    switch (s) {
      case ErrandStatus.broadcasting:
        return AppColors.gold;
      case ErrandStatus.bidsIn:
        return AppColors.gold;
      case ErrandStatus.assigned:
        return AppColors.aiBlue;
      case ErrandStatus.delivered:
        return AppColors.warning;
      case ErrandStatus.confirmed:
        return AppColors.success;
      case ErrandStatus.cancelled:
        return AppColors.slate;
    }
  }

  static String _labelFor(ErrandStatus s) {
    switch (s) {
      case ErrandStatus.broadcasting:
        return 'BROADCASTING';
      case ErrandStatus.bidsIn:
        return 'BIDS IN';
      case ErrandStatus.assigned:
        return 'RUNNER ASSIGNED';
      case ErrandStatus.delivered:
        return 'AWAITING CONFIRMATION';
      case ErrandStatus.confirmed:
        return 'CONFIRMED · ESCROW RELEASED';
      case ErrandStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.tone, required this.label});
  final Color tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _BroadcastingStrip extends StatefulWidget {
  const _BroadcastingStrip();
  @override
  State<_BroadcastingStrip> createState() => _BroadcastingStripState();
}

class _BroadcastingStripState extends State<_BroadcastingStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.4 + (_c.value * 0.5)),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Signal out · runners checking your list',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    ['1', 'Broadcast', 'Create an Errand List — describe the exact items from your local market.'],
    ['2', 'Market signal', 'Your request reaches Verified Runners in your LGA hub.'],
    ['3', 'Live bidding', 'Runners respond with price, ETA, and node rating. You pick.'],
    ['4', 'Escrow-locked', 'Funds are held by iGobi — released only when the recipient confirms receipt.'],
    ['5', 'Diaspora ready', 'Abroad? Set a recipient address for family in Nigeria. No risk of diversion.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final s in _steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slateLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          s[0],
                          style: const TextStyle(
                            color: AppColors.goldDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s[1],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(s[2],
                              style: const TextStyle(
                                  color: AppColors.slate,
                                  fontSize: 12,
                                  height: 1.5)),
                        ],
                      ),
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
