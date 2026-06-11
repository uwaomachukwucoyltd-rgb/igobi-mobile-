import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'state/errand_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

// =====================================================================
// Broadcast sheet — buyer describes the errand
// =====================================================================

Future<void> showBroadcastSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BroadcastSheet(),
  );
}

class _BroadcastSheet extends ConsumerStatefulWidget {
  const _BroadcastSheet();
  @override
  ConsumerState<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends ConsumerState<_BroadcastSheet> {
  final _form = GlobalKey<FormState>();
  final _items = TextEditingController(
      text: '5kg Yam tubers\n2L Palm Oil\n6 fresh Titus fish');
  final _recipientName = TextEditingController(text: 'Mama Adesina');
  final _recipientAddress =
      TextEditingController(text: '14 Aminu Kano Crescent, Wuse II, Abuja');
  final _budget = TextEditingController(text: '18000');
  bool _abroad = false;

  @override
  void dispose() {
    _items.dispose();
    _recipientName.dispose();
    _recipientAddress.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final lines = _items.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final budget = int.tryParse(_budget.text.trim());
    final id = ref.read(errandControllerProvider.notifier).createErrand(
          items: lines,
          recipientName: _recipientName.text.trim(),
          recipientAddress: _recipientAddress.text.trim(),
          maxBudgetNgn: budget,
        );
    Navigator.pop(context);
    showErrandDetail(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slateLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: AppColors.gold, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Broadcast an errand',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _form,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      const _FieldLabel('ITEMS LIST'),
                      const Text(
                        'One per line. Be specific — "5kg Yam tubers" beats "yam".',
                        style: TextStyle(
                            color: AppColors.slate, fontSize: 11, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _items,
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '5kg Yam tubers\n2L Palm Oil\n6 fresh Titus fish',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Add at least one item' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Checkbox(
                            value: _abroad,
                            onChanged: (v) =>
                                setState(() => _abroad = v ?? false),
                            activeColor: AppColors.emerald,
                          ),
                          const Expanded(
                            child: Text(
                              'I\'m abroad — this is for family in Nigeria',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const _FieldLabel('RECIPIENT NAME'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _recipientName,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Who is receiving this?',
                          hintStyle: TextStyle(color: AppColors.slate),
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 2) ? 'Add a name' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('RECIPIENT ADDRESS'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _recipientAddress,
                        minLines: 2,
                        maxLines: 3,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Street, area, city',
                          hintStyle: TextStyle(color: AppColors.slate),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 5) ? 'Add an address' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('MAX BUDGET (OPTIONAL)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _budget,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '18000',
                          hintStyle: TextStyle(color: AppColors.slate),
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text('₦',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.charcoalSoft,
                                )),
                          ),
                          prefixIconConstraints:
                              BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.emerald.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                color: AppColors.emerald, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Funds lock in iGobi escrow when you accept a bid. Released only when the recipient confirms receipt.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.charcoalSoft,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 16 + MediaQuery.of(context).padding.bottom),
                child: SizedBox(
                  height: 56,
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
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Initialize signal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.slate,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

// =====================================================================
// Errand detail sheet — bids list (if open) or runner progress
// =====================================================================

Future<void> showErrandDetail(BuildContext context, String errandId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ErrandDetailSheet(errandId: errandId),
  );
}

class _ErrandDetailSheet extends ConsumerWidget {
  const _ErrandDetailSheet({required this.errandId});
  final String errandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errands = ref.watch(errandControllerProvider);
    final errand = errands.firstWhere(
      (e) => e.id == errandId,
      orElse: () => errands.first,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Text(
                    'Errand · ${errand.recipientName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errand.recipientAddress,
                    style: const TextStyle(color: AppColors.slate, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  _ItemsCard(items: errand.items),
                  const SizedBox(height: 16),
                  _StatusSection(errand: errand),
                ],
              ),
            ),
            if (errand.status == ErrandStatus.delivered)
              _ConfirmFooter(errandId: errand.id),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ITEMS LIST',
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 14, color: AppColors.emerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13, height: 1.4),
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

class _StatusSection extends ConsumerWidget {
  const _StatusSection({required this.errand});
  final Errand errand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (errand.status) {
      case ErrandStatus.broadcasting:
        return const _BroadcastingPanel();
      case ErrandStatus.bidsIn:
        return _BidsList(errand: errand);
      case ErrandStatus.assigned:
      case ErrandStatus.delivered:
      case ErrandStatus.confirmed:
        return _AssignedPanel(errand: errand);
      case ErrandStatus.cancelled:
        return const _CancelledPanel();
    }
  }
}

class _BroadcastingPanel extends StatelessWidget {
  const _BroadcastingPanel();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2.5),
              ),
              SizedBox(width: 10),
              Text(
                'Signal broadcasting to 12 nearby runners',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Verified runners in your LGA hub are checking your items list. First bids usually arrive within 20 seconds.',
            style: TextStyle(
              color: AppColors.charcoalSoft,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BidsList extends ConsumerWidget {
  const _BidsList({required this.errand});
  final Errand errand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${errand.bids.length} BIDS IN',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pick a runner — funds lock in escrow',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final bid in errand.bids) _BidCard(errand: errand, bid: bid),
      ],
    );
  }
}

class _BidCard extends ConsumerWidget {
  const _BidCard({required this.errand, required this.bid});
  final Errand errand;
  final Bid bid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                child: Text(
                  bid.runnerName[0],
                  style: const TextStyle(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bid.runnerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${bid.rating.toStringAsFixed(1)} · ${bid.completed} errands',
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _money.format(bid.priceNgn),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.slate),
              const SizedBox(width: 4),
              Text('${bid.etaMin} min',
                  style: const TextStyle(color: AppColors.slate, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.hub_outlined,
                  size: 14, color: AppColors.slate),
              const SizedBox(width: 4),
              Text(bid.hub,
                  style: const TextStyle(color: AppColors.slate, fontSize: 12)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _accept(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.lock_outline_rounded, size: 14),
                label: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _accept(BuildContext context, WidgetRef ref) async {
    final escrowRef = ref.read(errandControllerProvider.notifier).acceptBid(
          errand.id,
          bid.id,
        );
    showToast(
      context,
      'Funds locked in escrow · ${bid.runnerName} accepted',
      icon: Icons.lock_rounded,
      background: AppColors.emerald,
    );
    Navigator.pop(context);
    // Brief delay then re-open the detail to show assigned state
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (context.mounted) showErrandDetail(context, errand.id);
    // ignore: unused_local_variable
    final _ = escrowRef;
  }
}

class _AssignedPanel extends StatelessWidget {
  const _AssignedPanel({required this.errand});
  final Errand errand;

  @override
  Widget build(BuildContext context) {
    final bid = errand.acceptedBid!;
    final isConfirmed = errand.status == ErrandStatus.confirmed;
    final isDelivered = errand.status == ErrandStatus.delivered;
    final tone = isConfirmed
        ? AppColors.success
        : isDelivered
            ? AppColors.warning
            : AppColors.aiBlue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tone.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: tone.withValues(alpha: 0.2),
                child: Text(
                  bid.runnerName[0],
                  style: TextStyle(
                    color: tone,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bid.runnerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      isConfirmed
                          ? 'Delivered & confirmed'
                          : isDelivered
                              ? 'Delivered · awaiting your confirmation'
                              : 'En route · ${bid.etaMin} min ETA',
                      style: TextStyle(color: tone, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                _money.format(bid.priceNgn),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                isConfirmed
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                color: AppColors.emerald,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfirmed
                          ? 'Escrow released'
                          : 'Funds held in escrow',
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (errand.heldEscrowRef != null)
                      Text(
                        errand.heldEscrowRef!,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _Timeline(),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineRow(label: 'Signal broadcasted', done: true),
        _TimelineRow(label: 'Bids received', done: true),
        _TimelineRow(label: 'Runner accepted · escrow locked', done: true),
        _TimelineRow(label: 'Delivered to recipient', done: true, active: true),
        _TimelineRow(label: 'Recipient confirms · escrow releases', done: false),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.done,
    this.active = false,
  });
  final String label;
  final bool done;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.success
        : active
            ? AppColors.warning
            : AppColors.slate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done ? AppColors.charcoal : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmFooter extends ConsumerWidget {
  const _ConfirmFooter({required this.errandId});
  final String errandId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 8, 20, 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Runner says delivered. Confirm to release the escrowed funds.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.charcoalSoft),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showToast(context, 'Support notified · dispute opened',
                          icon: Icons.gavel_outlined,
                          background: AppColors.danger);
                    },
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Dispute'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(errandControllerProvider.notifier)
                          .confirmReceipt(errandId);
                      Navigator.pop(context);
                      showToast(
                        context,
                        'Confirmed · funds released to runner',
                        icon: Icons.lock_open_rounded,
                        background: AppColors.success,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                    ),
                    icon:
                        const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Confirm receipt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledPanel extends StatelessWidget {
  const _CancelledPanel();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slateLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text('This errand was cancelled.',
          style: TextStyle(color: AppColors.slate)),
    );
  }
}
