import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/consent/consent_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../auth/state/auth_controller.dart';
import 'state/user_profile_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final user = state is AuthSignedIn ? state.user : null;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (user?.email.split('@').first ?? 'Guest');
    final email = user?.email ?? '—';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slateLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(color: AppColors.slate, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            user?.mfaEnabled ?? false ? Icons.verified : Icons.shield_outlined,
                            color: user?.mfaEnabled ?? false ? AppColors.success : AppColors.slate,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.mfaEnabled ?? false ? 'MFA enabled' : 'MFA off',
                            style: TextStyle(
                              color: user?.mfaEnabled ?? false ? AppColors.success : AppColors.slate,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Marketplace identity'),
          const _IdentityCard(),
          const SizedBox(height: 8),
          const _SectionLabel(label: 'Account'),
          _ProfileTile(
            icon: Icons.location_on_outlined,
            label: 'Addresses',
            onTap: () => _showAddresses(context),
          ),
          _ProfileTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            onTap: () => context.push('/wallet'),
          ),
          _ProfileTile(
            icon: Icons.card_giftcard_outlined,
            label: 'Rewards & referrals',
            onTap: () => context.push('/rewards'),
          ),
          _ProfileTile(
            icon: Icons.autorenew_rounded,
            label: 'Subscriptions & reminders',
            onTap: () => context.push('/recurring'),
          ),
          _ProfileTile(
            icon: Icons.payment_outlined,
            label: 'Payment methods',
            onTap: () => _showPaymentMethods(context),
          ),
          _ProfileTile(
            icon: Icons.security_outlined,
            label: 'Security & MFA',
            onTap: () => showToast(context,
                'Security & MFA settings coming soon',
                icon: Icons.security_outlined),
          ),
          const SizedBox(height: 8),
          const _SectionLabel(label: 'Community'),
          _ProfileTile(
            icon: Icons.favorite_rounded,
            label: 'Your Impact',
            onTap: () => context.push('/impact'),
          ),
          const SizedBox(height: 8),
          const _SectionLabel(label: 'Support'),
          _ProfileTile(
            icon: Icons.help_outline,
            label: 'Help center',
            onTap: () => showToast(context, 'Opening help center…',
                icon: Icons.help_outline),
          ),
          _ProfileTile(
            icon: Icons.report_gmailerrorred_outlined,
            label: 'Report a problem',
            onTap: () => showToast(context, 'A support agent will reach out shortly',
                icon: Icons.support_agent_outlined, background: AppColors.aiBlue),
          ),
          _ProfileTile(
            icon: Icons.gavel_outlined,
            label: 'Disputes',
            badge: '1 active',
            onTap: () => showToast(context, 'Disputes — coming next week',
                icon: Icons.gavel_outlined),
          ),
          const SizedBox(height: 8),
          const _SectionLabel(label: 'Privacy & data'),
          const _ConsentToggleTile(kind: _ConsentKind.crashReporting),
          const _ConsentToggleTile(kind: _ConsentKind.analytics),
          const SizedBox(height: 8),
          const _SectionLabel(label: 'Legal'),
          _ProfileTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => context.push('/legal/privacy'),
          ),
          _ProfileTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => context.push('/legal/terms'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/sign-in');
            },
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.push('/account/delete'),
            icon: const Icon(Icons.delete_forever, color: AppColors.danger),
            label: const Text(
              'Delete account',
              style: TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'iGobi · v0.1.0',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

enum _ConsentKind { crashReporting, analytics }

class _ConsentToggleTile extends ConsumerWidget {
  const _ConsentToggleTile({required this.kind});
  final _ConsentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consentControllerProvider);
    final controller = ref.read(consentControllerProvider.notifier);

    final (label, sub, icon, value, onChanged) = switch (kind) {
      _ConsentKind.crashReporting => (
          'Crash reporting',
          'Help iGobi fix issues by sending anonymous crash data.',
          Icons.bug_report_outlined,
          state.crashReporting,
          (bool v) => controller.setCrashReporting(v),
        ),
      _ConsentKind.analytics => (
          'Product analytics',
          'Share anonymous usage stats so we can improve the app.',
          Icons.insights_outlined,
          state.analytics,
          (bool v) => controller.setAnalytics(v),
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.emerald,
        secondary: Icon(icon, color: AppColors.charcoalSoft),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            sub,
            style: const TextStyle(color: AppColors.slate, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.slate,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.badge,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.charcoalSoft),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// =====================================================================
// Profile tile sheets
// =====================================================================

void _showAddresses(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _SheetShell(
      title: 'Saved addresses',
      child: Column(
        children: [
          const _AddressTile(
            label: 'Home',
            body: '14 Aminu Kano Crescent, Wuse II, Abuja',
            isDefault: true,
          ),
          const _AddressTile(
            label: 'Office',
            body: 'Plot 7B, Adeola Odeku St, Victoria Island, Lagos',
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(sheetCtx);
              showToast(context, 'Add address — coming soon',
                  icon: Icons.add_location_alt_outlined);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add address'),
          ),
        ],
      ),
    ),
  );
}

void _showPaymentMethods(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _SheetShell(
      title: 'Payment methods',
      child: Column(
        children: [
          const _PayMethodTile(
            icon: Icons.credit_card,
            title: 'Visa •••• 4881',
            body: 'Expires 09/28 · default',
            tint: AppColors.aiBlue,
          ),
          const _PayMethodTile(
            icon: Icons.account_balance,
            title: 'GTBank •••• 7204',
            body: 'Linked via Flutterwave',
            tint: AppColors.emerald,
          ),
          const _PayMethodTile(
            icon: Icons.phone_iphone,
            title: 'OPay wallet',
            body: '+234 9*** *** 412',
            tint: AppColors.gold,
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(sheetCtx);
              showToast(context, 'Add payment method — coming soon',
                  icon: Icons.add_card_outlined);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add method'),
          ),
        ],
      ),
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
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
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.label, required this.body, this.isDefault = false});
  final String label;
  final String body;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.emerald),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('default',
                            style: TextStyle(
                              color: AppColors.emerald,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(color: AppColors.slate, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  const _PayMethodTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.tint,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(color: AppColors.slate, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Marketplace identity card — role, primary hub, Diaspora toggle
// =====================================================================

class _IdentityCard extends ConsumerWidget {
  const _IdentityCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(userProfileControllerProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.role.shortLabel.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (p.diasporaMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.aiBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DIASPORA',
                    style: TextStyle(
                      color: AppColors.aiBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/setup'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit',
                    style: TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.slate),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Primary: ${p.primaryHub.displayLine}',
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (p.diasporaMode && p.recipientHubId != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.public, size: 16, color: AppColors.aiBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Recipient: ${hubById(p.recipientHubId)?.displayLine ?? "—"}',
                    style: const TextStyle(
                      color: AppColors.aiBlue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slateLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.aiBlue,
              value: p.diasporaMode,
              onChanged: (v) async {
                if (v) {
                  final picked = await _pickRecipientHub(context);
                  if (picked != null) {
                    ref
                        .read(userProfileControllerProvider.notifier)
                        .enableDiaspora(picked);
                  }
                } else {
                  ref
                      .read(userProfileControllerProvider.notifier)
                      .disableDiaspora();
                }
              },
              title: const Text(
                'Diaspora Mode',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              subtitle: const Text(
                'Shop for someone in a different LGA. Escrow stays gated on their confirmation.',
                style: TextStyle(color: AppColors.slate, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickRecipientHub(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slateLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.public, color: AppColors.aiBlue),
                    SizedBox(width: 8),
                    Text(
                      'Pick the recipient hub',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  itemCount: igobiHubs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final h = igobiHubs[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.slateLight),
                      ),
                      leading: const Icon(Icons.location_on_outlined,
                          color: AppColors.aiBlue),
                      title: Text(h.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text('${h.lga}, ${h.state}',
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 11)),
                      onTap: () => Navigator.pop(sheetCtx, h.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
