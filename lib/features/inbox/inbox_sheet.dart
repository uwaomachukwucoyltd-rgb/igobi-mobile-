import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'data/inbox_api.dart';
import 'state/inbox_providers.dart';

/// Bottom-sheet inbox that replaces the seed-data `_showNotifications` modal
/// in marketplace_screen.dart. Pulls from notification-service, marks read
/// on tap, supports mark-all-read.
Future<void> showInboxSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _InboxSheet(),
  );
}

class _InboxSheet extends ConsumerWidget {
  const _InboxSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _Handle(),
            _Header(inbox: inboxAsync),
            const Divider(height: 1, color: AppColors.slateLight),
            Expanded(
              child: inboxAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            color: AppColors.slate, size: 36),
                        const SizedBox(height: 8),
                        const Text('Could not load notifications'),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => ref.invalidate(inboxProvider),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (page) => page.items.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: page.items.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 64,
                          color: AppColors.slateLight,
                        ),
                        itemBuilder: (_, i) => _NotificationTile(item: page.items[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.slateLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.inbox});
  final AsyncValue<InboxPage> inbox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = inbox.maybeWhen(data: (p) => p.unread, orElse: () => 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unread new',
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (unread > 0)
            TextButton(
              onPressed: () async {
                final api = ref.read(inboxApiProvider);
                try {
                  await api.markAllRead();
                  ref.invalidate(inboxProvider);
                } catch (_) {
                  // best-effort
                }
              },
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.emerald, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nothing new yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Order updates, escrow releases, and dispute messages will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});
  final InboxNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, tint) = _iconForType(item.type);
    return InkWell(
      onTap: () async {
        if (item.isUnread) {
          try {
            await ref.read(inboxApiProvider).markRead(item.id);
            ref.invalidate(inboxProvider);
          } catch (_) {/* best-effort */}
        }
        final route = item.data['route'] as String?;
        if (route != null && context.mounted) {
          Navigator.pop(context);
          context.push(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        color: item.isUnread ? AppColors.emerald.withValues(alpha: 0.04) : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                item.isUnread ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatRelative(item.createdAt),
                        style: const TextStyle(color: AppColors.slate, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: const TextStyle(color: AppColors.slate, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

(IconData, Color) _iconForType(String type) {
  switch (type) {
    case 'payment.success':
      return (Icons.check_circle_outline, AppColors.success);
    case 'payment.failed':
      return (Icons.error_outline, AppColors.danger);
    case 'escrow.funded':
      return (Icons.shield_outlined, AppColors.emerald);
    case 'escrow.released':
      return (Icons.lock_open_outlined, AppColors.success);
    case 'escrow.refunded':
      return (Icons.replay_outlined, AppColors.warning);
    case 'dispute.opened':
      return (Icons.gavel_outlined, AppColors.warning);
    case 'dispute.resolved':
      return (Icons.handshake_outlined, AppColors.aiBlue);
    default:
      return (Icons.notifications_none_rounded, AppColors.slate);
  }
}

String _formatRelative(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}
