import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'state/auth_controller.dart';

/// Apple Guideline 5.1.1(v) + Google Play data-deletion policy compliance.
/// Type-to-confirm + double-tap + irreversible-warning copy.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  bool _busy = false;
  static const _phrase = 'DELETE';

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit => _confirm.text.trim() == _phrase && !_busy;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action is irreversible. Your profile, orders, escrow history '
          'and saved addresses will be removed within 30 days. You will not '
          'be able to recover this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(confirmation: _phrase);
      if (!mounted) return;
      showToast(
        context,
        'Account deletion submitted.',
        icon: Icons.check_circle_outline,
        background: AppColors.emerald,
      );
      context.go('/sign-in');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, e.message,
          icon: Icons.error_outline, background: AppColors.danger);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, e.message,
          icon: Icons.wifi_off, background: AppColors.danger);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, 'Could not delete account. Try again.',
          icon: Icons.error_outline, background: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This is permanent.',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                              fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'We will permanently delete or anonymise your '
                          'account, profile, orders, escrow ledger entries '
                          'and saved addresses within 30 days. Some records '
                          'may be retained where law requires (tax, AML).',
                          style: TextStyle(
                              color: AppColors.charcoal,
                              fontSize: 12.5,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Before you continue',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const _Bullet(
                text:
                    'Funds currently held in escrow will be released to the rightful party (buyer or vendor) per the dispute rules. Held balances are not refunded by deleting the account.'),
            const _Bullet(
                text:
                    'You will be signed out everywhere immediately and unable to sign back in with this email.'),
            const _Bullet(
                text:
                    'If you only want to stop notifications, change your password, or pause your account, contact support first — those are reversible.'),
            const SizedBox(height: 18),
            const Text(
              'Type DELETE to confirm',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirm,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(
                color: AppColors.charcoal,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
              decoration: const InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(
                  color: AppColors.slate,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.delete_forever),
              label:
                  Text(_busy ? 'Deleting…' : 'Permanently delete my account'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancel · keep my account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 5, color: AppColors.slate),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.slate, fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
