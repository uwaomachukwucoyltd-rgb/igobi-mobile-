import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/success_logo_burst.dart';
import '../../shared/widgets/toast.dart';
import 'state/mechanic_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
final _time = DateFormat('HH:mm');

const _rose = Color(0xFFE11D48);
const _emerald = AppColors.emerald;

// =====================================================================
// Geofence broadcast
// =====================================================================

Future<void> showMechBroadcastSheet(BuildContext context) {
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
  final _title = TextEditingController(text: 'Engine knocking at idle');
  final _vehicle = TextEditingController(text: '2016 Toyota Camry');
  final _address =
      TextEditingController(text: '14 Aminu Kano Crescent, Wuse II, Abuja');
  final _budget = TextEditingController(text: '12000');
  MechUrgency _urgency = MechUrgency.urgent;

  @override
  void dispose() {
    _title.dispose();
    _vehicle.dispose();
    _address.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final id =
        await ref.read(mechanicControllerProvider.notifier).createBroadcast(
              title: _title.text.trim(),
              vehicleLabel: _vehicle.text.trim(),
              address: _address.text.trim(),
              urgency: _urgency,
              budgetNgn: int.tryParse(_budget.text.trim()),
            );
    if (!mounted) return;
    Navigator.pop(context);
    showMechDetail(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _rose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_searching,
                          color: _rose, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Geofence broadcast',
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
                      const _FieldLabel('WHAT IS THE PROBLEM?'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _title,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Engine knocking at idle',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? '—' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('VEHICLE'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _vehicle,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Year, make, model',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? '—' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('URGENCY'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final u in MechUrgency.values) ...[
                            Expanded(
                              child: _UrgencyTile(
                                urgency: u,
                                selected: _urgency == u,
                                onTap: () => setState(() => _urgency = u),
                              ),
                            ),
                            if (u != MechUrgency.values.last)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('VEHICLE LOCATION'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _address,
                        minLines: 2,
                        maxLines: 3,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                          hintText: 'Where is the vehicle right now?',
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
                          hintText: '12000',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.broadcast_on_personal),
                          label: const Text('Sync to nearby mechanics'),
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

class _UrgencyTile extends StatelessWidget {
  const _UrgencyTile({
    required this.urgency,
    required this.selected,
    required this.onTap,
  });
  final MechUrgency urgency;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = switch (urgency) {
      MechUrgency.routine => AppColors.slate,
      MechUrgency.urgent => Colors.deepOrange,
      MechUrgency.emergency => Colors.redAccent,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : AppColors.slateLight,
              width: selected ? 1.4 : 1),
        ),
        child: Column(
          children: [
            Text(urgency.label,
                style: TextStyle(
                    color: selected ? color : AppColors.charcoal,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(urgency.window,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selected ? color : AppColors.slate,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Protocol Registry — quick book
// =====================================================================

Future<void> showMechProtocolSheet(
    BuildContext context, MechProtocol protocol) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProtocolBookSheet(protocol: protocol),
  );
}

class _ProtocolBookSheet extends ConsumerStatefulWidget {
  const _ProtocolBookSheet({required this.protocol});
  final MechProtocol protocol;
  @override
  ConsumerState<_ProtocolBookSheet> createState() =>
      _ProtocolBookSheetState();
}

class _ProtocolBookSheetState extends ConsumerState<_ProtocolBookSheet> {
  final _vehicle = TextEditingController(text: '2016 Toyota Camry');
  final _address =
      TextEditingController(text: '14 Aminu Kano Crescent, Wuse II, Abuja');

  @override
  void dispose() {
    _vehicle.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    final id = await ref
        .read(mechanicControllerProvider.notifier)
        .bookProtocol(widget.protocol,
            vehicleLabel: _vehicle.text.trim(),
            address: _address.text.trim());
    if (!mounted) return;
    Navigator.pop(context);
    showMechDetail(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _rose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    // ignore: non_const_argument_for_const_parameter
                    IconData(widget.protocol.icon, fontFamily: 'MaterialIcons'),
                    color: _rose,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.protocol.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      Text(
                          '${_money.format(widget.protocol.priceNgn)} · ${widget.protocol.etaWindow}',
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slateLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(widget.protocol.summary,
                  style: const TextStyle(
                      color: AppColors.charcoal, fontSize: 12.5)),
            ),
            const SizedBox(height: 14),
            const Align(
                alignment: Alignment.centerLeft,
                child: _FieldLabel('VEHICLE')),
            const SizedBox(height: 6),
            TextField(
              controller: _vehicle,
              style: const TextStyle(
                  color: AppColors.charcoal, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Year, make, model',
                hintStyle: TextStyle(color: AppColors.slate),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
                alignment: Alignment.centerLeft,
                child: _FieldLabel('ADDRESS')),
            const SizedBox(height: 6),
            TextField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(
                  color: AppColors.charcoal, fontSize: 14),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'Where is the vehicle?',
                hintStyle: TextStyle(color: AppColors.slate),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _book,
                icon: const Icon(Icons.lock_outline),
                label: Text(
                    'Lock ${_money.format(widget.protocol.priceNgn)} in escrow'),
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
    );
  }
}

// =====================================================================
// Detail
// =====================================================================

Future<void> showMechDetail(BuildContext context, String requestId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MechDetailSheet(requestId: requestId),
  );
}

class _MechDetailSheet extends ConsumerWidget {
  const _MechDetailSheet({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(mechanicControllerProvider);
    final req = requests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => requests.first,
    );
    return DraggableScrollableSheet(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.title,
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
                  _Meta(req: req),
                  const SizedBox(height: 12),
                  _StatusBanner(req: req),
                  const SizedBox(height: 14),
                  if (req.status == MechStatus.broadcasting)
                    const _RadioWaiting(),
                  if (req.status == MechStatus.offersIn)
                    _OfferList(req: req),
                  if (req.status == MechStatus.enRoute ||
                      req.status == MechStatus.onSite)
                    _InProgressBlock(req: req),
                  if (req.status == MechStatus.reportUploaded)
                    _ReportBlock(req: req, allowAck: true),
                  if (req.status == MechStatus.released)
                    _ReportBlock(req: req, allowAck: false),
                  if (req.status == MechStatus.cancelled)
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

class _Meta extends StatelessWidget {
  const _Meta({required this.req});
  final MechRequest req;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 14, color: AppColors.slate),
        const SizedBox(width: 4),
        Expanded(
          child: Text(req.address,
              style: const TextStyle(color: AppColors.slate, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _rose.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(req.urgency.label.toUpperCase(),
              style: const TextStyle(
                  color: _rose,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.req});
  final MechRequest req;
  @override
  Widget build(BuildContext context) {
    final (icon, copy) = switch (req.status) {
      MechStatus.broadcasting => (
        Icons.location_searching,
        'Geofence scan in progress · nearby mechanics receiving the request'
      ),
      MechStatus.offersIn => (
        Icons.inbox_outlined,
        '${req.offers.length} mechanics responded'
      ),
      MechStatus.enRoute => (
        Icons.directions_car_filled_outlined,
        '${req.acceptedOffer?.mechanicName ?? "Mechanic"} en route · escrow locked'
      ),
      MechStatus.onSite => (
        Icons.engineering_outlined,
        'Mechanic on site · diagnostics in progress'
      ),
      MechStatus.reportUploaded => (
        Icons.description_outlined,
        'Diagnostic report uploaded · please acknowledge'
      ),
      MechStatus.released => (
        Icons.check_circle_outline,
        'Acknowledged · escrow released'
      ),
      MechStatus.cancelled => (Icons.cancel_outlined, 'Request cancelled.'),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _rose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rose.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _rose, size: 18),
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
                    color: _rose.withValues(alpha: 0.6 - 0.4 * _c.value),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.radar, color: _rose, size: 28),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Geofence scanning…',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: _rose)),
          const SizedBox(height: 4),
          const Text('Mechanics within 8 km are pinged',
              style: TextStyle(color: AppColors.slate, fontSize: 11)),
        ],
      ),
    );
  }
}

class _OfferList extends ConsumerWidget {
  const _OfferList({required this.req});
  final MechRequest req;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...req.offers]..sort((a, b) => a.etaMin.compareTo(b.etaMin));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mechanic offers',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        for (final o in sorted) ...[
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
                        color: _rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.engineering,
                          color: _rose, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.mechanicName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          Text(o.node,
                              style: const TextStyle(
                                  color: AppColors.slate, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(_money.format(o.priceNgn),
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
                    _Tag(text: o.specialty, color: _rose),
                    _Tag(
                        text: 'ETA ${o.etaMin} min',
                        color: Colors.deepOrange),
                    _Tag(
                        text: '${o.distanceKm.toStringAsFixed(1)} km away',
                        color: Colors.indigo),
                    _Tag(
                        text:
                            '★ ${o.rating.toStringAsFixed(1)} · ${o.completed}',
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
                          .read(mechanicControllerProvider.notifier)
                          .acceptOffer(req.id, o.id);
                      showToast(
                        context,
                        '${o.mechanicName} dispatched',
                        icon: Icons.directions_car_filled_outlined,
                        background: _rose,
                      );
                    },
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Dispatch & lock escrow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose,
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

class _InProgressBlock extends StatelessWidget {
  const _InProgressBlock({required this.req});
  final MechRequest req;
  @override
  Widget build(BuildContext context) {
    final o = req.acceptedOffer!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_filled_outlined,
                  color: Colors.deepOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    req.status == MechStatus.enRoute
                        ? '${o.mechanicName} en route · ETA ${o.etaMin} min'
                        : '${o.mechanicName} on site · diagnostics in progress',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              'Escrow ${req.heldEscrowRef} locked. Mechanic will upload a signed Diagnostic Report on completion.',
              style: const TextStyle(color: AppColors.slate, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ReportBlock extends ConsumerWidget {
  const _ReportBlock({required this.req, required this.allowAck});
  final MechRequest req;
  final bool allowAck;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = req.report!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                  const Icon(Icons.description_outlined, color: _rose),
                  const SizedBox(width: 8),
                  const Text('DIAGNOSTIC REPORT',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _rose,
                          letterSpacing: 0.6)),
                  const Spacer(),
                  Text(_time.format(r.uploadedAt),
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.summary,
                  style: const TextStyle(
                      color: AppColors.charcoal, fontSize: 13, height: 1.5)),
              const SizedBox(height: 12),
              const _ReportSubhead(text: 'Findings'),
              for (final f in r.findings) _ReportLine(text: f),
              const SizedBox(height: 8),
              const _ReportSubhead(text: 'Recommendations'),
              for (final f in r.recommendations) _ReportLine(text: f),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.image_outlined,
                      size: 14, color: AppColors.slate),
                  const SizedBox(width: 4),
                  Text('${r.photosCount} photos attached',
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SETTLEMENT BREAKDOWN',
                  style: TextStyle(
                      color: _emerald,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      fontSize: 11)),
              const SizedBox(height: 8),
              _SettleRow(
                  label: 'Mechanic payout',
                  value: _money.format(req.mechanicPayoutNgn ?? 0)),
              _SettleRow(
                  label: 'McCoy Service Fee (10%)',
                  value: _money.format(req.mccoyFeeNgn ?? 0)),
              const Divider(),
              _SettleRow(
                label: 'Total escrow',
                value: _money.format(
                    (req.acceptedOffer?.priceNgn ?? req.budgetNgn ?? 0)),
                bold: true,
              ),
            ],
          ),
        ),
        if (allowAck) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                ref
                    .read(mechanicControllerProvider.notifier)
                    .acknowledgeReport(req.id);
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (_) => const _AckDialog(),
                );
                if (!context.mounted) return;
                showToast(
                  context,
                  'Escrow released · mechanic paid',
                  icon: Icons.check_circle_outline,
                  background: _emerald,
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Acknowledge report · release escrow'),
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
      ],
    );
  }
}

class _ReportSubhead extends StatelessWidget {
  const _ReportSubhead({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w800,
              fontSize: 12)),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppColors.slate, fontWeight: FontWeight.w800)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.slate, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _SettleRow extends StatelessWidget {
  const _SettleRow(
      {required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: bold ? AppColors.charcoal : AppColors.slate,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5)),
          ),
          Text(value,
              style: TextStyle(
                  color: bold ? AppColors.emerald : AppColors.charcoal,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
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

class _AckDialog extends StatelessWidget {
  const _AckDialog();
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
              'Report acknowledged',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Escrow released. Mechanic paid, McCoy fee retained.',
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
