import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'data/wallet_api.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM, h:mm a');

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final txnsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Wallet'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(walletTransactionsProvider);
          await ref.read(walletBalanceProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            balanceAsync.when(
              data: (b) => _BalanceCard(balance: b),
              loading: () => const _BalanceCardSkeleton(),
              error: (_, __) => _InlineError(
                message: 'Could not load balance',
                onRetry: () => ref.invalidate(walletBalanceProvider),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _showTopUpSheet(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Top up wallet'),
            ),
            const SizedBox(height: 22),
            const Text(
              'Transactions',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            txnsAsync.when(
              data: (page) {
                if (page.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(0, 32, 0, 32),
                    child: Center(
                      child: Text(
                        'No transactions yet.',
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final t in page.items) _TxnTile(txn: t),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(0, 32, 0, 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _InlineError(
                message: 'Could not load transactions',
                onRetry: () => ref.invalidate(walletTransactionsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopUpSheet(ref: ref),
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final naira = int.tryParse(_controller.text.trim().replaceAll(',', ''));
    if (naira == null || naira <= 0) {
      showToast(context, 'Enter a valid amount', icon: Icons.error_outline);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.ref
          .read(walletApiProvider)
          .topUp(amountMinor: naira * 100);
      widget.ref.invalidate(walletBalanceProvider);
      widget.ref.invalidate(walletTransactionsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showToast(context, 'Wallet topped up with ${_money.format(naira)}',
          icon: Icons.check_circle_outline, background: AppColors.emerald);
    } on ApiException catch (e) {
      if (!mounted) return;
      showToast(context, e.message, icon: Icons.error_outline,
          background: AppColors.danger);
    } on NetworkException catch (e) {
      if (!mounted) return;
      showToast(context, e.message, icon: Icons.error_outline,
          background: AppColors.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickAmounts = [1000, 2000, 5000, 10000];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const Text('Top up wallet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: AppColors.charcoal, fontSize: 16),
              decoration: const InputDecoration(
                prefixText: '₦ ',
                hintText: 'Amount',
                hintStyle: TextStyle(color: AppColors.slate),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in quickAmounts)
                  ActionChip(
                    label: Text(_money.format(a)),
                    onPressed: () => setState(() =>
                        _controller.text = a.toString()),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm top-up'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final WalletBalance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.emeraldDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AVAILABLE BALANCE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Text(
            _money.format(balance.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balance.currency,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.slateLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn});
  final WalletTxn txn;

  @override
  Widget build(BuildContext context) {
    final credit = txn.isCredit;
    final amountText =
        '${credit ? '+' : '-'}${_money.format(txn.amount.abs())}';
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
              color: (credit ? AppColors.success : AppColors.danger)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: credit ? AppColors.success : AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description.isEmpty ? txn.type : txn.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFmt.format(txn.createdAt),
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              color: credit ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
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
