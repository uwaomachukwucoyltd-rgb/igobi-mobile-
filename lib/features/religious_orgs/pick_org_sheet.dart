import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'data/religious_orgs_api.dart';
import 'state/religious_orgs_providers.dart';

/// Bottom sheet that lets the customer search + pick a religious
/// organisation. Returns the selected ReligiousOrg, or null on dismiss.
Future<ReligiousOrg?> showPickOrgSheet(BuildContext context) {
  return showModalBottomSheet<ReligiousOrg>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PickOrgSheet(),
  );
}

class _PickOrgSheet extends ConsumerStatefulWidget {
  const _PickOrgSheet();

  @override
  ConsumerState<_PickOrgSheet> createState() => _PickOrgSheetState();
}

class _PickOrgSheetState extends ConsumerState<_PickOrgSheet> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(religiousOrgsSearchProvider(_query));
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose your community',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '10% of our fee on every order will support the organisation you pick. You can change this anytime in your Profile.',
                style: TextStyle(color: AppColors.slate, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name, location, or code',
                  prefixIcon: Icon(Icons.search, color: AppColors.slate),
                ),
              ),
            ),
            Expanded(
              child: searchAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load organisations. Try again in a moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate),
                    ),
                  ),
                ),
                data: (orgs) => orgs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No matches. Try a different search, or paste an organisation code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.slate),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: orgs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _OrgTile(
                          org: orgs[i],
                          onTap: () => Navigator.pop(context, orgs[i]),
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

class _OrgTile extends StatelessWidget {
  const _OrgTile({required this.org, required this.onTap});
  final ReligiousOrg org;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.diversity_3_rounded,
                  color: AppColors.emerald),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          org.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (org.verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            size: 14, color: AppColors.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_typeLabel(org.type)} · ${org.location}',
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    org.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppColors.slate,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
      ),
    );
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'CHURCH':
      return 'Church';
    case 'MOSQUE':
      return 'Mosque';
    case 'MINISTRY':
      return 'Ministry';
    case 'CHARITY':
      return 'Charity';
    default:
      return 'Organisation';
  }
}
