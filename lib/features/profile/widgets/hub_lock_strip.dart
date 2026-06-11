import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../state/user_profile_state.dart';

/// Shows which hub the screen is locked to. Two modes:
///   • Standard — pinned to the user's primary hub.
///   • Diaspora — visibility delegated to a recipient hub. Escrow still gated
///     locally; the strip makes this contract visible.
class HubLockStrip extends ConsumerWidget {
  const HubLockStrip({super.key, this.tone = AppColors.emerald});
  final Color tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileControllerProvider);
    final diaspora = profile.diasporaMode && profile.recipientHubId != null;
    final hub = profile.visibilityHub;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (diaspora ? AppColors.aiBlue : tone).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (diaspora ? AppColors.aiBlue : tone).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              diaspora ? Icons.public : Icons.location_on_outlined,
              size: 16,
              color: diaspora ? AppColors.aiBlue : tone,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diaspora
                        ? 'DIASPORA · syncing to ${hub.lga}, ${hub.state}'
                        : 'LOCKED · ${hub.lga}, ${hub.state}',
                    style: TextStyle(
                      color: diaspora ? AppColors.aiBlue : tone,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    diaspora
                        ? 'Buying for someone in ${hub.lga}. Escrow releases only on local recipient confirmation.'
                        : 'You only see vendors and runners in this LGA.',
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                      height: 1.4,
                    ),
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

/// Pill that shows the user's hub on hub screens that *don't* hard-lock —
/// e.g. Farm Harvest (national reach) shows a "National · seeing all states"
/// pill so the user understands why it isn't filtered.
class NationalReachStrip extends StatelessWidget {
  const NationalReachStrip({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF65A30D).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF65A30D).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.public, size: 16, color: Color(0xFF65A30D)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'NATIONAL REACH · farm harvest is strategic-resource, all states visible',
                style: TextStyle(
                  color: Color(0xFF65A30D),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
