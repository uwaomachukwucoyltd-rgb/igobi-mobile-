import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../auth/state/auth_controller.dart';
import '../religious_orgs/pick_org_sheet.dart';
import '../religious_orgs/state/religious_orgs_providers.dart';
import 'data/impact_api.dart';
import 'state/impact_providers.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
final _date = DateFormat('d MMM y');

class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(impactSummaryProvider);
    final donationsAsync = ref.watch(impactDonationsProvider);
    final auth = ref.watch(authControllerProvider);
    final orgId = auth is AuthSignedIn ? auth.user.selectedReligiousOrgId : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Impact')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(impactSummaryProvider);
          ref.invalidate(impactDonationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _SummaryCard(summaryAsync: summaryAsync),
            const SizedBox(height: 18),
            _OrgCard(orgId: orgId, onPick: () => _pickOrg(context, ref)),
            const SizedBox(height: 22),
            const Text(
              'Recent contributions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            donationsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Could not load donation history.',
                      style: TextStyle(color: AppColors.slate)),
                ),
              ),
              data: (rows) => rows.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.softWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slateLight),
                      ),
                      child: const Text(
                        'No contributions yet. Place your first order and 10% of our fee will support your chosen organisation.',
                        style: TextStyle(color: AppColors.slate, fontSize: 13),
                      ),
                    )
                  : Column(
                      children: [
                        for (final d in rows) _DonationRow(donation: d),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickOrg(BuildContext context, WidgetRef ref) async {
    final picked = await showPickOrgSheet(context);
    if (picked == null || !context.mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).setReligiousOrg(picked.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your community: ${picked.name}')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your selection.')),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summaryAsync});
  final AsyncValue<ImpactSummary> summaryAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.emeraldDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR LIFETIME CONTRIBUTION',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          summaryAsync.when(
            loading: () => const SizedBox(
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
            error: (_, __) => const Text(
              'Could not load total',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            data: (s) => Text(
              _money.format(s.totalNgn),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 36,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          summaryAsync.maybeWhen(
            data: (s) => Text(
              s.count == 0
                  ? 'Across no contributions yet'
                  : 'Across ${s.count} contribution${s.count == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _OrgCard extends ConsumerWidget {
  const _OrgCard({required this.orgId, required this.onPick});
  final String? orgId;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orgId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite_rounded,
                    size: 16, color: AppColors.gold),
                SizedBox(width: 8),
                Text(
                  'Direct your impact',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick a religious organisation to receive 10% of our fee on every order you make.',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onPick,
              child: const Text('Choose organisation'),
            ),
          ],
        ),
      );
    }

    final orgAsync = ref.watch(religiousOrgByIdProvider(orgId!));
    return orgAsync.when(
      loading: () => const SizedBox(
          height: 64, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => OutlinedButton(
        onPressed: onPick,
        child: const Text('Change organisation'),
      ),
      data: (org) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.diversity_3_rounded,
                  color: AppColors.emerald),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENTLY SUPPORTING',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    org.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    org.location,
                    style:
                        const TextStyle(color: AppColors.slate, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onPick, child: const Text('Change')),
          ],
        ),
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  const _DonationRow({required this.donation});
  final ImpactDonation donation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded,
                size: 16, color: AppColors.emerald),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.lineLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _date.format(donation.createdAt),
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            _money.format(donation.amountNgn),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
