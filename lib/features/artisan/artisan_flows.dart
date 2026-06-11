import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'state/job_state.dart';

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

const _amber = Color(0xFFD97706);

// =====================================================================
// Broadcast a service
// =====================================================================

Future<void> showArtisanBroadcastSheet(BuildContext context) {
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
  final _title = TextEditingController(text: 'Plumbing · kitchen sink');
  final _description = TextEditingController(
      text: 'Burst pipe under the kitchen sink — water leaking continuously.');
  final _address =
      TextEditingController(text: '14 Aminu Kano Crescent, Wuse II, Abuja');
  final _budget = TextEditingController(text: '10000');
  Urgency _urgency = Urgency.urgent;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final id = ref.read(artisanControllerProvider.notifier).createBroadcast(
          serviceTitle: _title.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
          urgency: _urgency,
          budgetNgn: int.tryParse(_budget.text.trim()),
        );
    Navigator.pop(context);
    showJobDetail(context, id);
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
                        color: _amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: _amber, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Broadcast a service',
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
                      const _FieldLabel('SERVICE'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _title,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Plumbing · kitchen sink',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'Add a title' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('DESCRIPTION'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Describe the problem and any details.',
                          hintStyle: TextStyle(color: AppColors.slate),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 8) ? 'Add some detail' : null,
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('URGENCY'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final u in Urgency.values) ...[
                            Expanded(
                              child: _UrgencyTile(
                                urgency: u,
                                selected: _urgency == u,
                                onTap: () => setState(() => _urgency = u),
                              ),
                            ),
                            if (u != Urgency.values.last) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('ADDRESS'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _address,
                        minLines: 2,
                        maxLines: 3,
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Where should the artisan come?',
                          hintStyle: TextStyle(color: AppColors.slate),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 5) ? 'Add an address' : null,
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
                          hintText: '10000',
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
                                'Funds lock in iGobi escrow when you accept a bid. Released only when you confirm the work meets satisfaction.',
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
                                'Dispatch signal',
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

class _UrgencyTile extends StatelessWidget {
  const _UrgencyTile({
    required this.urgency,
    required this.selected,
    required this.onTap,
  });
  final Urgency urgency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = switch (urgency) {
      Urgency.routine => AppColors.slate,
      Urgency.urgent => AppColors.warning,
      Urgency.emergency => AppColors.danger,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? tone.withValues(alpha: 0.12) : AppColors.softWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? tone : AppColors.slateLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              urgency.label,
              style: TextStyle(
                color: selected ? tone : AppColors.charcoal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              urgency.note,
              style: const TextStyle(color: AppColors.slate, fontSize: 10),
            ),
          ],
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
// Direct Registry — instant booking
// =====================================================================

Future<void> showDirectBookSheet(BuildContext context, DirectService service) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DirectBookSheet(service: service),
  );
}

class _DirectBookSheet extends ConsumerStatefulWidget {
  const _DirectBookSheet({required this.service});
  final DirectService service;
  @override
  ConsumerState<_DirectBookSheet> createState() => _DirectBookSheetState();
}

class _DirectBookSheetState extends ConsumerState<_DirectBookSheet> {
  final _address =
      TextEditingController(text: '14 Aminu Kano Crescent, Wuse II, Abuja');

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _book() {
    final addr = _address.text.trim();
    if (addr.length < 5) return;
    final id = ref
        .read(artisanControllerProvider.notifier)
        .bookDirect(widget.service, addr);
    Navigator.pop(context);
    showToast(
      context,
      '${widget.service.title} · artisan dispatched',
      icon: Icons.flash_on_rounded,
      background: _amber,
    );
    showJobDetail(context, id);
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
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 16 + MediaQuery.of(context).padding.bottom),
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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'INSTANT',
                    style: TextStyle(
                      color: _amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.service.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(widget.service.summary,
                style: const TextStyle(
                    color: AppColors.slate, fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slateLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FIXED PRICE',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          _money.format(widget.service.priceNgn),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('ETA',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 4),
                      Text(widget.service.etaWindow,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('ADDRESS'),
            const SizedBox(height: 6),
            TextField(
              controller: _address,
              style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'Where should the artisan come?',
                hintStyle: TextStyle(color: AppColors.slate),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _book,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.flash_on_rounded),
                label: Text(
                  'Book & lock ${_money.format(widget.service.priceNgn)} in escrow',
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
// Job detail sheet
// =====================================================================

Future<void> showJobDetail(BuildContext context, String jobId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JobDetailSheet(jobId: jobId),
  );
}

class _JobDetailSheet extends ConsumerWidget {
  const _JobDetailSheet({required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(artisanControllerProvider);
    final job = jobs.firstWhere((j) => j.id == jobId, orElse: () => jobs.first);
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
                    job.serviceTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.address,
                    style: const TextStyle(color: AppColors.slate, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.softWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slateLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SCOPE',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 6),
                        Text(job.description,
                            style: const TextStyle(fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusSection(job: job),
                ],
              ),
            ),
            if (job.status == JobStatus.completed)
              _ConfirmFooter(jobId: job.id),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends ConsumerWidget {
  const _StatusSection({required this.job});
  final ArtisanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (job.status) {
      case JobStatus.broadcasting:
        return const _BroadcastingPanel();
      case JobStatus.bidsIn:
        return _BidsList(job: job);
      case JobStatus.dispatched:
      case JobStatus.onSite:
      case JobStatus.completed:
      case JobStatus.confirmed:
        return _DispatchedPanel(job: job);
      case JobStatus.cancelled:
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
        color: _amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.3)),
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
                    color: _amber, strokeWidth: 2.5),
              ),
              SizedBox(width: 10),
              Text(
                'Signal broadcasting to vetted artisans',
                style: TextStyle(
                  color: _amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Artisan nodes inside your LGA are reviewing your request. First bids usually arrive within 20 seconds.',
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

class _BidsList extends StatelessWidget {
  const _BidsList({required this.job});
  final ArtisanJob job;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${job.bids.length} BIDS IN',
                style: const TextStyle(
                  color: _amber,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pick an artisan — escrow locks on accept',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final bid in job.bids) _BidCard(job: job, bid: bid),
      ],
    );
  }
}

class _BidCard extends ConsumerWidget {
  const _BidCard({required this.job, required this.bid});
  final ArtisanJob job;
  final ArtisanBid bid;

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
                backgroundColor: _amber.withValues(alpha: 0.18),
                child: Text(
                  bid.artisanName[0],
                  style: const TextStyle(
                    color: _amber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bid.artisanName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: AppColors.success, size: 14),
                      ],
                    ),
                    Text(
                      bid.specialty,
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 12),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: _amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${bid.rating.toStringAsFixed(1)} · ${bid.completed} jobs · ${bid.lga}',
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money.format(bid.priceNgn),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.emerald,
                    ),
                  ),
                  Text(
                    '${bid.etaMin} min',
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton.icon(
              onPressed: () => _accept(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
              ),
              icon: const Icon(Icons.lock_outline_rounded, size: 16),
              label: Text(
                'Lock ${_money.format(bid.priceNgn)} in escrow',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _accept(BuildContext context, WidgetRef ref) async {
    ref.read(artisanControllerProvider.notifier).acceptBid(job.id, bid.id);
    showToast(
      context,
      '${bid.artisanName} dispatched · funds in escrow',
      icon: Icons.lock_rounded,
      background: AppColors.emerald,
    );
    Navigator.pop(context);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (context.mounted) showJobDetail(context, job.id);
  }
}

class _DispatchedPanel extends StatelessWidget {
  const _DispatchedPanel({required this.job});
  final ArtisanJob job;
  @override
  Widget build(BuildContext context) {
    final bid = job.acceptedBid!;
    final isConfirmed = job.status == JobStatus.confirmed;
    final isCompleted = job.status == JobStatus.completed;
    final isOnSite = job.status == JobStatus.onSite;
    final tone = isConfirmed
        ? AppColors.success
        : isCompleted
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
                  bid.artisanName[0],
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
                    Text(bid.artisanName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      isConfirmed
                          ? 'Completed & confirmed'
                          : isCompleted
                              ? 'Work complete · awaiting your confirmation'
                              : isOnSite
                                  ? 'At your address · ${bid.specialty}'
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
                isConfirmed ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: AppColors.emerald,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfirmed ? 'Escrow released' : 'Funds held in escrow',
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (job.heldEscrowRef != null)
                      Text(
                        job.heldEscrowRef!,
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
        _Timeline(currentStatus: job.status),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.currentStatus});
  final JobStatus currentStatus;
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Signal dispatched', JobStatus.broadcasting),
      ('Bids received', JobStatus.bidsIn),
      ('Artisan accepted · escrow locked', JobStatus.dispatched),
      ('At your address', JobStatus.onSite),
      ('Work complete', JobStatus.completed),
      ('You confirm · escrow releases', JobStatus.confirmed),
    ];
    final currentIdx = steps.indexWhere((s) => s.$2 == currentStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            label: steps[i].$1,
            done: i < currentIdx ||
                (i == currentIdx && currentStatus == JobStatus.confirmed),
            active: i == currentIdx && currentStatus != JobStatus.confirmed,
          ),
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
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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
  const _ConfirmFooter({required this.jobId});
  final String jobId;
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
                'Artisan reports the work is complete. Confirm to release escrow.',
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
                          .read(artisanControllerProvider.notifier)
                          .confirmReceipt(jobId);
                      Navigator.pop(context);
                      showToast(
                        context,
                        'Confirmed · funds released to artisan',
                        icon: Icons.lock_open_rounded,
                        background: AppColors.success,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Confirm complete'),
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
      child: const Text('This job was cancelled.',
          style: TextStyle(color: AppColors.slate)),
    );
  }
}
