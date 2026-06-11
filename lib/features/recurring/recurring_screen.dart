import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import 'data/recurring_api.dart';

final _dateFmt = DateFormat('d MMM yyyy, h:mm a');

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(recurringPlansProvider);
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Subscriptions & reminders'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recurringPlansProvider);
          ref.invalidate(remindersProvider);
          await ref.read(remindersProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ---- Reminders ----
            Row(
              children: [
                const Text('Reminders',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddReminderSheet(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.emerald),
                ),
              ],
            ),
            const SizedBox(height: 6),
            remindersAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyHint(
                    text: 'No reminders. Add a refill or maintenance reminder.',
                  );
                }
                return Column(
                  children: [
                    for (final r in items)
                      _ReminderTile(
                        reminder: r,
                        onDelete: () => _deleteReminder(context, ref, r.id),
                      ),
                  ],
                );
              },
              loading: () => const _Loading(),
              error: (_, __) => _InlineError(
                message: 'Could not load reminders',
                onRetry: () => ref.invalidate(remindersProvider),
              ),
            ),
            const SizedBox(height: 24),

            // ---- Recurring plans ----
            Row(
              children: [
                const Text('Recurring plans',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddPlanSheet(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.emerald),
                ),
              ],
            ),
            const SizedBox(height: 6),
            plansAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyHint(
                    text: 'No recurring plans. Set up an auto-reorder cadence.',
                  );
                }
                return Column(
                  children: [
                    for (final p in items)
                      _PlanTile(
                        plan: p,
                        onDelete: () => _deletePlan(context, ref, p.id),
                      ),
                  ],
                );
              },
              loading: () => const _Loading(),
              error: (_, __) => _InlineError(
                message: 'Could not load plans',
                onRetry: () => ref.invalidate(recurringPlansProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReminder(
      BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(recurringApiProvider).deleteReminder(id);
      ref.invalidate(remindersProvider);
      if (context.mounted) {
        showToast(context, 'Reminder deleted', icon: Icons.delete_outline);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, _errText(e),
            icon: Icons.error_outline, background: AppColors.danger);
      }
    }
  }

  Future<void> _deletePlan(
      BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(recurringApiProvider).deletePlan(id);
      ref.invalidate(recurringPlansProvider);
      if (context.mounted) {
        showToast(context, 'Plan deleted', icon: Icons.delete_outline);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, _errText(e),
            icon: Icons.error_outline, background: AppColors.danger);
      }
    }
  }

  void _showAddReminderSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(ref: ref),
    );
  }

  void _showAddPlanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlanSheet(ref: ref),
    );
  }
}

String _errText(Object e) {
  if (e is ApiException) return e.message;
  if (e is NetworkException) return e.message;
  return 'Something went wrong';
}

// =====================================================================
// Add reminder
// =====================================================================

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({required this.ref});
  final WidgetRef ref;
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _kind = 'REFILL';
  DateTime? _dueAt;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      showToast(context, 'Enter a title', icon: Icons.error_outline);
      return;
    }
    if (_dueAt == null) {
      showToast(context, 'Pick a due date', icon: Icons.error_outline);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.ref.read(recurringApiProvider).createReminder(
            kind: _kind,
            title: _title.text.trim(),
            body: _body.text.trim(),
            dueAt: _dueAt!,
          );
      widget.ref.invalidate(remindersProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showToast(context, 'Reminder added',
          icon: Icons.check_circle_outline, background: AppColors.emerald);
    } catch (e) {
      if (!mounted) return;
      showToast(context, _errText(e),
          icon: Icons.error_outline, background: AppColors.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Add reminder',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final k in const ['REFILL', 'MAINTENANCE', 'CUSTOM'])
                ChoiceChip(
                  label: Text(k[0] + k.substring(1).toLowerCase()),
                  selected: _kind == k,
                  selectedColor: AppColors.emerald.withValues(alpha: 0.15),
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Refill gas cylinder',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 2,
            style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event, size: 18),
            label: Text(
              _dueAt == null ? 'Pick due date' : _dateFmt.format(_dueAt!),
            ),
          ),
          const SizedBox(height: 16),
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
                : const Text('Save reminder'),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Add plan
// =====================================================================

class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet({required this.ref});
  final WidgetRef ref;
  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _label = TextEditingController();
  final _cadence = TextEditingController(text: '30');
  bool _submitting = false;

  @override
  void dispose() {
    _label.dispose();
    _cadence.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _label.text.trim();
    final cadence = int.tryParse(_cadence.text.trim());
    if (label.isEmpty) {
      showToast(context, 'Enter a label', icon: Icons.error_outline);
      return;
    }
    if (cadence == null || cadence <= 0) {
      showToast(context, 'Enter cadence in days', icon: Icons.error_outline);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.ref
          .read(recurringApiProvider)
          .createPlan(label: label, cadenceDays: cadence);
      widget.ref.invalidate(recurringPlansProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showToast(context, 'Recurring plan added',
          icon: Icons.check_circle_outline, background: AppColors.emerald);
    } catch (e) {
      if (!mounted) return;
      showToast(context, _errText(e),
          icon: Icons.error_outline, background: AppColors.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Add recurring plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _label,
            style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. Monthly groceries',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cadence,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Repeat every (days)',
            ),
          ),
          const SizedBox(height: 16),
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
                : const Text('Save plan'),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Tiles + shared widgets
// =====================================================================

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder, required this.onDelete});
  final Reminder reminder;
  final VoidCallback onDelete;

  IconData get _icon => switch (reminder.kind) {
        'REFILL' => Icons.local_gas_station_outlined,
        'MAINTENANCE' => Icons.build_outlined,
        _ => Icons.notifications_outlined,
      };

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
              color: AppColors.aiBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: AppColors.aiBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Due ${_dateFmt.format(reminder.dueAt)}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onDelete});
  final RecurringPlan plan;
  final VoidCallback onDelete;

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
            child: const Icon(Icons.autorenew_rounded,
                color: AppColors.emerald, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Every ${plan.cadenceDays} day${plan.cadenceDays == 1 ? '' : 's'}'
                  '${plan.nextRunAt != null ? ' · next ${_dateFmt.format(plan.nextRunAt!)}' : ''}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Text(text,
          style: const TextStyle(color: AppColors.slate, fontSize: 13)),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
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
