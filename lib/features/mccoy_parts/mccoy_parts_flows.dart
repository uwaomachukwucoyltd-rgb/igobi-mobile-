import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/success_logo_burst.dart';
import '../../shared/widgets/toast.dart';
import 'state/parts_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

const _slate = Color(0xFF334155);
const _emerald = AppColors.emerald;

// =====================================================================
// Broadcast a part request
// =====================================================================

Future<void> showPartBroadcastSheet(BuildContext context) {
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
  final _make = TextEditingController(text: 'Toyota');
  final _model = TextEditingController(text: 'Camry');
  final _year = TextEditingController(text: '2016');
  final _part = TextEditingController(text: 'Front shock absorber');
  final _notes = TextEditingController(
      text: 'OEM preferred. Driver-side rattling on rough roads.');
  final _deliverTo =
      TextEditingController(text: 'McCoy Node — Wuse II, Abuja');
  final _budget = TextEditingController(text: '35000');

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _part.dispose();
    _notes.dispose();
    _deliverTo.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final id =
        await ref.read(partsControllerProvider.notifier).createBroadcast(
              vehicleMake: _make.text.trim(),
              vehicleModel: _model.text.trim(),
              vehicleYear: int.parse(_year.text.trim()),
              partName: _part.text.trim(),
              notes: _notes.text.trim(),
              deliverTo: _deliverTo.text.trim(),
              budgetNgn: int.tryParse(_budget.text.trim()),
            );
    if (!mounted) return;
    Navigator.pop(context);
    showPartDetail(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.96,
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
                        color: _slate.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded,
                          color: _slate, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Broadcast a part request',
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
                      const _FieldLabel('VEHICLE'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _make,
                              style: const TextStyle(
                                  color: AppColors.charcoal, fontSize: 14),
                              decoration: const InputDecoration(
                                  hintText: 'Make',
                                  hintStyle:
                                      TextStyle(color: AppColors.slate)),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? '—'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _model,
                              style: const TextStyle(
                                  color: AppColors.charcoal, fontSize: 14),
                              decoration: const InputDecoration(
                                  hintText: 'Model',
                                  hintStyle:
                                      TextStyle(color: AppColors.slate)),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? '—'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 78,
                            child: TextFormField(
                              controller: _year,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: AppColors.charcoal, fontSize: 14),
                              decoration: const InputDecoration(
                                  hintText: 'Year',
                                  hintStyle:
                                      TextStyle(color: AppColors.slate)),
                              validator: (v) {
                                final y = int.tryParse(v?.trim() ?? '');
                                if (y == null || y < 1980 || y > 2030) {
                                  return '—';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('PART NAME'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _part,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Front shock absorber',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? '—' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('NOTES / VIN'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notes,
                        minLines: 2,
                        maxLines: 4,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText:
                              'OEM / aftermarket preference, condition notes, VIN if available.',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('DELIVER TO'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _deliverTo,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                          hintText: 'McCoy Node / mechanic address',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 5) ? '—' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('BUDGET (OPTIONAL)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _budget,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text('₦',
                                style: TextStyle(
                                  color: AppColors.charcoal,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                          hintText: '35000',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.broadcast_on_personal),
                          label: const Text('Send to verified dealers'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emerald,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
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
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 1.4,
      ),
    );
  }
}

// =====================================================================
// Detail bottom sheet
// =====================================================================

Future<void> showPartDetail(BuildContext context, String requestId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PartDetailSheet(requestId: requestId),
  );
}

class _PartDetailSheet extends ConsumerWidget {
  const _PartDetailSheet({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(partsControllerProvider);
    final req = requests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => requests.first,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.96,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.partName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(req.vehicleLabel,
                            style: const TextStyle(
                                color: AppColors.slate, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  _MetaRow(req: req),
                  const SizedBox(height: 12),
                  if (req.notes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slateLight.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        req.notes,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _StatusBanner(req: req),
                  const SizedBox(height: 16),
                  if (req.status == PartStatus.broadcasting)
                    const _RadioWaiting(),
                  if (req.status == PartStatus.bidsIn)
                    _BidList(req: req),
                  if (req.status == PartStatus.awarded)
                    _AwardedBlock(req: req),
                  if (req.status == PartStatus.awaitingFitment)
                    _AwaitingFitmentBlock(req: req),
                  if (req.status == PartStatus.fitmentVerified)
                    _ReleasedBlock(req: req),
                  if (req.status == PartStatus.confirmed)
                    _ConfirmedBlock(req: req),
                  if (req.status == PartStatus.cancelled)
                    const _CancelledBlock(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.req});
  final PartRequest req;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 14, color: AppColors.slate),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            req.deliverTo,
            style: const TextStyle(color: AppColors.slate, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (req.budgetNgn != null) ...[
          const SizedBox(width: 10),
          const Icon(Icons.account_balance_wallet_outlined,
              size: 14, color: AppColors.slate),
          const SizedBox(width: 4),
          Text(_money.format(req.budgetNgn),
              style: const TextStyle(color: AppColors.slate, fontSize: 12)),
        ],
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.req});
  final PartRequest req;
  @override
  Widget build(BuildContext context) {
    final (icon, copy) = switch (req.status) {
      PartStatus.broadcasting => (
        Icons.broadcast_on_personal,
        'Pinging verified dealers across the network…'
      ),
      PartStatus.bidsIn => (
        Icons.inbox_outlined,
        '${req.bids.length} dealers responded. Compare and award.'
      ),
      PartStatus.awarded => (
        Icons.lock_outline,
        'Bid accepted · escrow ${req.heldEscrowRef} locked. Dealer dispatching.'
      ),
      PartStatus.awaitingFitment => (
        Icons.verified_user_outlined,
        'Part delivered · ${req.verifierName} scheduled for fitment verification.'
      ),
      PartStatus.fitmentVerified => (
        Icons.check_circle_outline,
        'Fitment verified · escrow released to dealer.'
      ),
      PartStatus.confirmed => (
        Icons.task_alt,
        'Order closed. Warranty active.'
      ),
      PartStatus.cancelled => (
        Icons.cancel_outlined,
        'Request cancelled.'
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _slate.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _slate.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _slate, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(copy,
                style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _RadioWaiting extends StatefulWidget {
  const _RadioWaiting();
  @override
  State<_RadioWaiting> createState() => _RadioWaitingState();
}

class _RadioWaitingState extends State<_RadioWaiting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              return Container(
                width: 70 + 20 * _c.value,
                height: 70 + 20 * _c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _emerald.withValues(alpha: 0.6 - 0.4 * _c.value),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.radio, color: _emerald, size: 28),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Broadcasting…',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: _slate)),
          const SizedBox(height: 4),
          const Text('Verified dealers in your sector are listening',
              style: TextStyle(color: AppColors.slate, fontSize: 11)),
        ],
      ),
    );
  }
}

class _BidList extends ConsumerWidget {
  const _BidList({required this.req});
  final PartRequest req;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...req.bids]..sort((a, b) => a.priceNgn.compareTo(b.priceNgn));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Compare bids',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        for (final b in sorted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _slate.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store_mall_directory_outlined,
                          color: _slate, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.dealerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          Text(b.dealerNode,
                              style: const TextStyle(
                                  color: AppColors.slate, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(_money.format(b.priceNgn),
                        style: const TextStyle(
                            color: _emerald,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(text: b.condition, color: _slate),
                    _Tag(
                        text: '${b.warrantyDays}-day warranty',
                        color: Colors.indigo),
                    _Tag(text: 'ETA ${b.etaHours} h', color: Colors.deepOrange),
                    _Tag(
                        text: '★ ${b.rating.toStringAsFixed(1)} · ${b.fulfilled}',
                        color: Colors.amber.shade800),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(partsControllerProvider.notifier)
                          .acceptBid(req.id, b.id);
                      showToast(
                        context,
                        'Bid accepted · escrow locked',
                        icon: Icons.lock_outline,
                        background: _emerald,
                      );
                    },
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Award & lock escrow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _slate,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4)),
    );
  }
}

class _AwardedBlock extends StatelessWidget {
  const _AwardedBlock({required this.req});
  final PartRequest req;
  @override
  Widget build(BuildContext context) {
    final b = req.acceptedBid!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _emerald.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: _emerald),
              const SizedBox(width: 8),
              Text('${b.dealerName} dispatching to ${req.deliverTo}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              'Escrow ${req.heldEscrowRef} locked. ${b.condition} · ${b.warrantyDays}-day warranty · ETA ${b.etaHours} h.',
              style: const TextStyle(color: AppColors.slate, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AwaitingFitmentBlock extends ConsumerWidget {
  const _AwaitingFitmentBlock({required this.req});
  final PartRequest req;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: Colors.deepOrange),
                  SizedBox(width: 8),
                  Text('FITMENT VERIFICATION',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.deepOrange,
                          letterSpacing: 0.6)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  'Part delivered. ${req.verifierName} (McCoy Mechanic Node) will inspect on your vehicle. Escrow stays locked. Wrong part → dealer eats the swap.',
                  style: const TextStyle(
                      color: AppColors.charcoal, fontSize: 12.5, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              ref
                  .read(partsControllerProvider.notifier)
                  .verifyFitment(req.id);
              if (!context.mounted) return;
              await showDialog<void>(
                context: context,
                builder: (_) => const _ReleaseDialog(),
              );
              if (!context.mounted) return;
              showToast(
                context,
                'Fitment verified · escrow released',
                icon: Icons.check_circle_outline,
                background: _emerald,
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark fitment verified'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReleasedBlock extends ConsumerWidget {
  const _ReleasedBlock({required this.req});
  final PartRequest req;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _emerald.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_open_outlined, color: _emerald),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Escrow released · dealer paid. Warranty active.',
                    style: TextStyle(
                        color: _emerald, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: () {
              ref
                  .read(partsControllerProvider.notifier)
                  .confirmReceipt(req.id);
              Navigator.pop(context);
            },
            child: const Text('Close request'),
          ),
        ),
      ],
    );
  }
}

class _ConfirmedBlock extends StatelessWidget {
  const _ConfirmedBlock({required this.req});
  final PartRequest req;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: _emerald),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                'Closed. ${req.acceptedBid?.dealerName ?? "Dealer"} · ${req.acceptedBid?.warrantyDays ?? 0}-day warranty active.',
                style: const TextStyle(
                    color: _emerald, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _CancelledBlock extends StatelessWidget {
  const _CancelledBlock();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.redAccent),
          SizedBox(width: 8),
          Text('Request cancelled.',
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ReleaseDialog extends StatelessWidget {
  const _ReleaseDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            const SuccessLogoBurst(size: 110),
            const SizedBox(height: 18),
            const Text(
              'Fitment verified',
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'McCoy Mechanic confirmed correct fitment. Escrow released to the dealer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate, fontSize: 13),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emerald,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
