import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import 'state/ratings_providers.dart';

/// Bottom sheet that collects a 1-5 star rating + optional complaint text and
/// POSTs it to vendor-service. Returns true if the rating was successfully
/// submitted.
Future<bool> showRateVendorSheet(
  BuildContext context, {
  required String vendorId,
  required String vendorName,
  String? orderRef,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _RateVendorSheet(
        vendorId: vendorId,
        vendorName: vendorName,
        orderRef: orderRef,
      ),
    ),
  );
  return result ?? false;
}

class _RateVendorSheet extends ConsumerStatefulWidget {
  const _RateVendorSheet({
    required this.vendorId,
    required this.vendorName,
    this.orderRef,
  });

  final String vendorId;
  final String vendorName;
  final String? orderRef;

  @override
  ConsumerState<_RateVendorSheet> createState() => _RateVendorSheetState();
}

class _RateVendorSheetState extends ConsumerState<_RateVendorSheet> {
  int _stars = 0;
  final _complaintController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  bool get _wantsComplaint => _stars > 0 && _stars <= 2;

  Future<void> _submit() async {
    if (_stars == 0 || _submitting) return;
    if (_wantsComplaint && _complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tell us what went wrong so we can act on it.'),
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(ratingsApiProvider).rate(
            vendorId: widget.vendorId,
            stars: _stars,
            complaint:
                _complaintController.text.trim().isEmpty ? null : _complaintController.text.trim(),
            orderRef: widget.orderRef,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'Rate ${widget.vendorName}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your rating drives whether they stay on IGOBI. Low ratings with a complaint suspend the vendor until you confirm a resolution.',
            style: TextStyle(color: AppColors.slate, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return IconButton(
                iconSize: 36,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? AppColors.gold : AppColors.slate,
                ),
                onPressed: () => setState(() => _stars = i + 1),
              );
            }),
          ),
          if (_wantsComplaint) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _complaintController,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'What went wrong?',
                helperText: 'A low rating with a complaint suspends the vendor until you mark it resolved.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit rating'),
            ),
          ),
        ],
      ),
    );
  }
}
