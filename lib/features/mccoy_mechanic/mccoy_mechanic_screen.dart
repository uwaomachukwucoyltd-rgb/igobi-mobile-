import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'mccoy_mechanic_flows.dart';
import 'state/mechanic_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

const _rose = Color(0xFFE11D48);
const _roseDark = Color(0xFFBE123C);

class McCoyMechanicScreen extends ConsumerWidget {
  const McCoyMechanicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(mechanicControllerProvider);

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
              title: const Text('McCoy Mechanic'),
              actions: [
                IconButton(
                  onPressed: () => showToast(
                    context,
                    'Encrypted dispatch · Proof-of-Service settlement · 10% McCoy fee',
                    icon: Icons.lock_outline,
                    background: _rose,
                  ),
                  icon: const Icon(Icons.help_outline_rounded),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: _BroadcastCta()),
            const SliverToBoxAdapter(child: _EncryptedSyncStrip()),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Protocol Registry')),
            const SliverToBoxAdapter(child: _ProtocolRegistry()),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Your active service requests',
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
          colors: [_rose, _roseDark],
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
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white, size: 10),
                    SizedBox(width: 6),
                    Text(
                      'DIAGNOSTIC DISPATCH',
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
              const Icon(Icons.car_repair_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Mechanics, dispatched\nby diagnostic.',
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
            'Pick a fixed-rate protocol or geofence-broadcast a problem. Escrow holds until the mechanic uploads the Diagnostic Report and you acknowledge.',
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
              onTap: () => showMechBroadcastSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_searching,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Geofence broadcast',
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

class _EncryptedSyncStrip extends StatefulWidget {
  const _EncryptedSyncStrip();
  @override
  State<_EncryptedSyncStrip> createState() => _EncryptedSyncStripState();
}

class _EncryptedSyncStripState extends State<_EncryptedSyncStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
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
          color: _roseDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _rose),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                return Icon(
                  Icons.lock_outline,
                  size: 14,
                  color:
                      Colors.white.withValues(alpha: 0.4 + 0.6 * _c.value),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'ENCRYPTED SYNCS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '12 nodes within 8 km · 4 mechanics on standby',
                style: TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.location_on, color: Colors.white, size: 14),
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

class _ProtocolRegistry extends ConsumerWidget {
  const _ProtocolRegistry();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocols = ref.watch(mechProtocolsProvider);
    return SizedBox(
      height: 160,
      child: protocols.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Could not load protocols',
              style: TextStyle(color: AppColors.slate)),
        ),
        data: (items) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => _ProtocolCard(protocol: items[i]),
        ),
      ),
    );
  }
}

class _ProtocolCard extends ConsumerWidget {
  const _ProtocolCard({required this.protocol});
  final MechProtocol protocol;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => showMechProtocolSheet(context, protocol),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
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
                color: _rose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                // ignore: non_const_argument_for_const_parameter
                IconData(protocol.icon, fontFamily: 'MaterialIcons'),
                color: _rose,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(protocol.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(protocol.summary,
                style:
                    const TextStyle(color: AppColors.slate, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                Text(_money.format(protocol.priceNgn),
                    style: const TextStyle(
                        color: _rose,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                const Spacer(),
                Text(protocol.etaWindow,
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 10)),
              ],
            ),
          ],
        ),
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
            Icon(Icons.engineering_outlined, color: _rose),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No service requests yet. Tap a fixed-rate protocol or broadcast your diagnostic problem.',
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
  final MechRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => showMechDetail(context, request.id),
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
                    color: _rose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.car_repair_rounded,
                      color: _rose, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(request.vehicleLabel,
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (request.acceptedOffer != null) ...[
                  const Icon(Icons.payments_outlined,
                      size: 13, color: AppColors.slate),
                  const SizedBox(width: 4),
                  Text(_money.format(request.acceptedOffer!.priceNgn),
                      style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                  const SizedBox(width: 12),
                ],
                if (request.urgency != MechUrgency.routine) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: request.urgency == MechUrgency.emergency
                          ? Colors.redAccent.withValues(alpha: 0.12)
                          : Colors.deepOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      request.urgency.label.toUpperCase(),
                      style: TextStyle(
                        color: request.urgency == MechUrgency.emergency
                            ? Colors.redAccent
                            : Colors.deepOrange,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (request.heldEscrowRef != null) ...[
                  const Icon(Icons.lock_clock_outlined,
                      size: 13, color: AppColors.slate),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(request.heldEscrowRef!,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final MechStatus status;
  @override
  Widget build(BuildContext context) {
    final c = switch (status) {
      MechStatus.broadcasting => _rose,
      MechStatus.offersIn => Colors.indigo,
      MechStatus.enRoute => Colors.amber.shade800,
      MechStatus.onSite => Colors.deepOrange,
      MechStatus.reportUploaded => Colors.teal,
      MechStatus.released => AppColors.emerald,
      MechStatus.cancelled => Colors.redAccent,
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
