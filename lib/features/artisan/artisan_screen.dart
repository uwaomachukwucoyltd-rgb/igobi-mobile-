import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'artisan_flows.dart';
import 'state/job_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

class ArtisanHubScreen extends ConsumerWidget {
  const ArtisanHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(artisanControllerProvider);
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
              title: const Text('Artisan Hub'),
              actions: [
                IconButton(
                  onPressed: () => showToast(
                    context,
                    '1,247 vetted artisans across 12 LGAs',
                    icon: Icons.verified_user_outlined,
                    background: const Color(0xFFD97706),
                  ),
                  icon: const Icon(Icons.help_outline_rounded),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: _BroadcastCta()),
            const SliverToBoxAdapter(child: _DirectRegistry()),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Your active jobs',
                trailing: jobs.isEmpty
                    ? null
                    : Text('${jobs.length} active',
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12)),
              ),
            ),
            if (jobs.isEmpty)
              const SliverToBoxAdapter(child: _EmptyJobs())
            else
              SliverList.separated(
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _JobCard(job: jobs[i]),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'How it works')),
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
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
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
                  'SERVICE DISPATCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.handyman_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Skilled labour, dispatched\nlike a ride-hail.',
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
            'Broadcast your need · vetted artisans in your LGA bid live · escrow-locked until you confirm completion.',
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
              onTap: () => showArtisanBroadcastSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Broadcast a service request',
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

class _DirectRegistry extends ConsumerWidget {
  const _DirectRegistry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live registry, with the bundled list as a fallback while loading / on error.
    final services =
        ref.watch(directServicesProvider).asData?.value ?? directServices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded,
                  color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Direct Registry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'INSTANT',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'Pre-negotiated fixed-rate services — order without waiting for bids.',
            style: TextStyle(color: AppColors.slate, fontSize: 12),
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _DirectCard(service: services[i]),
          ),
        ),
      ],
    );
  }
}

class _DirectCard extends ConsumerWidget {
  const _DirectCard({required this.service});
  final DirectService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: () => showDirectBookSheet(context, service),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  IconData(service.icon, fontFamily: 'MaterialIcons'),
                  color: const Color(0xFFD97706),
                  size: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                service.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  service.summary,
                  style:
                      const TextStyle(color: AppColors.slate, fontSize: 11, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _money.format(service.priceNgn),
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    service.etaWindow,
                    style:
                        const TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                ],
              ),
            ],
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

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();
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
            'No active jobs. Broadcast a service or tap a Direct Registry tile to dispatch instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 13, height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job});
  final ArtisanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = _toneFor(job.status);
    final label = _labelFor(job.status);
    return InkWell(
      onTap: () => showJobDetail(context, job.id),
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
                _Chip(tone: tone, label: label),
                const SizedBox(width: 6),
                _UrgencyChip(urgency: job.urgency),
                const Spacer(),
                Text(
                  DateFormat('h:mm a').format(job.createdAt),
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.serviceTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              job.description,
              style:
                  const TextStyle(color: AppColors.slate, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (job.acceptedBid != null) ...[
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
                          job.acceptedBid!.artisanName[0],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.acceptedBid!.artisanName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            job.acceptedBid!.specialty,
                            style: const TextStyle(
                                color: AppColors.slate, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _money.format(job.acceptedBid!.priceNgn),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else if (job.status == JobStatus.bidsIn) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.gavel_rounded,
                      color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${job.bids.length} artisans bidding — tap to pick',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else if (job.status == JobStatus.broadcasting) ...[
              const SizedBox(height: 12),
              const _PulsingStrip(),
            ],
          ],
        ),
      ),
    );
  }

  static Color _toneFor(JobStatus s) {
    switch (s) {
      case JobStatus.broadcasting:
      case JobStatus.bidsIn:
        return const Color(0xFFD97706); // amber
      case JobStatus.dispatched:
      case JobStatus.onSite:
        return AppColors.aiBlue;
      case JobStatus.completed:
        return AppColors.warning;
      case JobStatus.confirmed:
        return AppColors.success;
      case JobStatus.cancelled:
        return AppColors.slate;
    }
  }

  static String _labelFor(JobStatus s) {
    switch (s) {
      case JobStatus.broadcasting:
        return 'BROADCASTING';
      case JobStatus.bidsIn:
        return 'BIDS IN';
      case JobStatus.dispatched:
        return 'DISPATCHED';
      case JobStatus.onSite:
        return 'AT YOUR ADDRESS';
      case JobStatus.completed:
        return 'AWAITING CONFIRMATION';
      case JobStatus.confirmed:
        return 'COMPLETED · ESCROW RELEASED';
      case JobStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.tone, required this.label});
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

class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({required this.urgency});
  final Urgency urgency;
  @override
  Widget build(BuildContext context) {
    final color = switch (urgency) {
      Urgency.routine => AppColors.slate,
      Urgency.urgent => AppColors.warning,
      Urgency.emergency => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        urgency.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PulsingStrip extends StatefulWidget {
  const _PulsingStrip();
  @override
  State<_PulsingStrip> createState() => _PulsingStripState();
}

class _PulsingStripState extends State<_PulsingStrip>
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
          color: const Color(0xFFD97706).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706)
                    .withValues(alpha: 0.4 + (_c.value * 0.5)),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Signal out · artisans in your LGA checking',
              style: TextStyle(
                color: Color(0xFFD97706),
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
    ['1', 'Dispatch', 'Describe the work, set urgency, optional budget.'],
    ['2', 'Geofenced broadcast', 'Signal reaches vetted artisan nodes in your LGA.'],
    ['3', 'Live bidding', 'Artisans respond with price, ETA, and verified rating.'],
    ['4', 'Direct Registry', 'Or skip bidding — book fixed-rate express services instantly.'],
    ['5', 'Escrow security', 'Funds release only when you confirm the work meets satisfaction.'],
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
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          s[0],
                          style: const TextStyle(
                            color: Color(0xFFB45309),
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
