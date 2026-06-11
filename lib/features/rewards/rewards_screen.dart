import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'data/rewards_api.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM yyyy');

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final _redeemController = TextEditingController();
  bool _redeeming = false;

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _redeemController.text.trim();
    if (code.isEmpty) {
      showToast(context, 'Enter a referral code', icon: Icons.error_outline);
      return;
    }
    setState(() => _redeeming = true);
    try {
      final res = await ref.read(rewardsApiProvider).redeemReferral(code);
      if (!mounted) return;
      showToast(
        context,
        res.message.isNotEmpty
            ? res.message
            : (res.ok ? 'Referral redeemed' : 'Could not redeem'),
        icon: res.ok ? Icons.check_circle_outline : Icons.error_outline,
        background: res.ok ? AppColors.emerald : AppColors.danger,
      );
      if (res.ok) {
        _redeemController.clear();
        ref.invalidate(referralsProvider);
        ref.invalidate(loyaltyProvider);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showToast(context, e.message,
          icon: Icons.error_outline, background: AppColors.danger);
    } on NetworkException catch (e) {
      if (!mounted) return;
      showToast(context, e.message,
          icon: Icons.error_outline, background: AppColors.danger);
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyAsync = ref.watch(loyaltyProvider);
    final codeAsync = ref.watch(referralCodeProvider);
    final referralsAsync = ref.watch(referralsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Rewards & referrals'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loyaltyProvider);
          ref.invalidate(referralCodeProvider);
          ref.invalidate(referralsProvider);
          await ref.read(loyaltyProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ---- Loyalty ----
            loyaltyAsync.when(
              data: (l) => _LoyaltyCard(info: l),
              loading: () => const _CardSkeleton(height: 120),
              error: (_, __) => _InlineError(
                message: 'Could not load loyalty',
                onRetry: () => ref.invalidate(loyaltyProvider),
              ),
            ),
            const SizedBox(height: 22),

            // ---- Your referral code ----
            const Text('Your referral code',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            codeAsync.when(
              data: (code) => _ReferralCodeCard(code: code),
              loading: () => const _CardSkeleton(height: 70),
              error: (_, __) => _InlineError(
                message: 'Could not load code',
                onRetry: () => ref.invalidate(referralCodeProvider),
              ),
            ),
            const SizedBox(height: 22),

            // ---- Redeem someone else's code ----
            const Text("Got a friend's code?",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _redeemController,
                    textCapitalization: TextCapitalization.characters,
                    style:
                        const TextStyle(color: AppColors.charcoal, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter referral code',
                      hintStyle: TextStyle(color: AppColors.slate),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _redeeming ? null : _redeem,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  child: _redeeming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Redeem'),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ---- Referral history ----
            const Text('Referral history',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            referralsAsync.when(
              data: (info) {
                if (info.referrals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(0, 24, 0, 24),
                    child: Center(
                      child: Text(
                        'No referrals yet. Share your code to earn rewards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration_outlined,
                              color: AppColors.goldDark, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Total earned: ${_money.format(info.totalRewarded)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final r in info.referrals) _ReferralTile(entry: r),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(0, 24, 0, 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _InlineError(
                message: 'Could not load referrals',
                onRetry: () => ref.invalidate(referralsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.info});
  final LoyaltyInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LOYALTY POINTS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                Text(
                  '${info.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  info.tier.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code.isEmpty ? '—' : code,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            onPressed: code.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      showToast(context, 'Code copied',
                          icon: Icons.copy, background: AppColors.emerald);
                    }
                  },
            icon: const Icon(Icons.copy_rounded, color: AppColors.emerald),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: code.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(
                        text:
                            'Join me on iGobi! Use my referral code $code to get started.'));
                    if (context.mounted) {
                      showToast(context, 'Invite copied — paste it anywhere',
                          icon: Icons.ios_share, background: AppColors.emerald);
                    }
                  },
            icon: const Icon(Icons.ios_share, color: AppColors.emerald),
          ),
        ],
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  const _ReferralTile({required this.entry});
  final ReferralEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline,
                color: AppColors.emerald, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _dateFmt.format(entry.createdAt!),
                    style:
                        const TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (entry.rewardedMinor > 0)
            Text(
              '+${_money.format(entry.rewarded)}',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.slateLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.slate, size: 36),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
