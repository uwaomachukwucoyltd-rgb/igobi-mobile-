import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../profile/state/user_profile_state.dart';

/// Role-aware multi-step onboarding. Reached via `/setup` either from sign-up
/// (post-registration) or from Profile → "Edit" on the identity card.
class RoleSetupScreen extends ConsumerStatefulWidget {
  const RoleSetupScreen({super.key});

  @override
  ConsumerState<RoleSetupScreen> createState() => _RoleSetupScreenState();
}

class _RoleSetupScreenState extends ConsumerState<RoleSetupScreen> {
  int _step = 0;
  UserRole? _role;
  String? _hubId;
  bool _diaspora = false;
  String? _recipientHubId;
  String? _businessCategory;
  String? _deliveryVehicle;
  bool _briefingAck = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(userProfileControllerProvider);
    _role = p.role;
    _hubId = p.primaryHubId;
    _diaspora = p.diasporaMode;
    _recipientHubId = p.recipientHubId;
    _businessCategory = p.businessCategory;
    _deliveryVehicle = p.deliveryVehicle;
    _briefingAck = p.escrowBriefingSeen;
  }

  List<Widget> get _steps {
    return [
      _RolePickerStep(
        selected: _role,
        onPick: (r) => setState(() {
          _role = r;
        }),
      ),
      if (_role == UserRole.buyer) ...[
        _HubPickerStep(
          title: 'Connect to your primary hub',
          subtitle:
              'You will only see vendors and runners in this LGA. You can override this later with Diaspora Mode.',
          selected: _hubId,
          onPick: (id) => setState(() => _hubId = id),
        ),
        _DiasporaStep(
          enabled: _diaspora,
          recipientHubId: _recipientHubId,
          onToggle: (v) => setState(() {
            _diaspora = v;
            if (!v) _recipientHubId = null;
          }),
          onPickRecipient: (id) => setState(() => _recipientHubId = id),
        ),
        _EscrowBriefingStep(
          acknowledged: _briefingAck,
          onAck: () => setState(() => _briefingAck = true),
        ),
      ],
      if (_role == UserRole.vendor) ...[
        _BusinessCategoryStep(
          selected: _businessCategory,
          onPick: (c) => setState(() => _businessCategory = c),
        ),
        _HubPickerStep(
          title: 'Sync your shop to a hub',
          subtitle:
              'Buyer signals reach you only inside this hub. Vendors with physical shops should pick the LGA the shop sits in.',
          selected: _hubId,
          onPick: (id) => setState(() => _hubId = id),
        ),
        const _VendorVerificationStep(),
      ],
      if (_role == UserRole.deliveryAgent) ...[
        _DeliveryVehicleStep(
          selected: _deliveryVehicle,
          onPick: (v) => setState(() => _deliveryVehicle = v),
        ),
        _HubPickerStep(
          title: 'Lock to a delivery hub',
          subtitle:
              'Tasks come from broadcasts inside this LGA. You can request a transfer to another hub from your dashboard.',
          selected: _hubId,
          onPick: (id) => setState(() => _hubId = id),
        ),
        const _AgentClearanceStep(),
      ],
      if (_role == UserRole.admin) ...[
        const _AdminLedgerStep(),
      ],
    ];
  }

  bool get _canAdvance {
    final steps = _steps;
    if (_step == 0) return _role != null;
    final stepWidget = steps[_step];
    if (stepWidget is _HubPickerStep) return _hubId != null;
    if (stepWidget is _DiasporaStep) {
      return !_diaspora || _recipientHubId != null;
    }
    if (stepWidget is _EscrowBriefingStep) return _briefingAck;
    if (stepWidget is _BusinessCategoryStep) return _businessCategory != null;
    if (stepWidget is _DeliveryVehicleStep) return _deliveryVehicle != null;
    return true;
  }

  void _next() {
    final last = _step == _steps.length - 1;
    if (!last) {
      setState(() => _step += 1);
      return;
    }
    _commit();
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() => _step -= 1);
  }

  void _commit() {
    final ctl = ref.read(userProfileControllerProvider.notifier);
    ctl.setRole(_role!);
    if (_hubId != null) ctl.setPrimaryHub(_hubId!);
    if (_diaspora && _recipientHubId != null) {
      ctl.enableDiaspora(_recipientHubId!);
    } else {
      ctl.disableDiaspora();
    }
    if (_role == UserRole.vendor) {
      ctl.setBusinessCategory(_businessCategory);
      ctl.markVendorPending();
    }
    if (_role == UserRole.deliveryAgent) {
      ctl.setDeliveryVehicle(_deliveryVehicle);
    }
    if (_briefingAck) ctl.markBriefingSeen();
    ctl.setSetupComplete(true);

    showToast(
      context,
      'Setup complete · welcome ${_role!.shortLabel}',
      icon: Icons.check_circle_outline,
      background: AppColors.emerald,
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    return Scaffold(
      backgroundColor: AppColors.softWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: _step,
              total: steps.length,
              onBack: _back,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey('step_${_step}_${_role?.name}'),
                    child: steps[_step],
                  ),
                ),
              ),
            ),
            _Footer(
              canAdvance: _canAdvance,
              isLast: _step == steps.length - 1,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Header / Footer
// =====================================================================

class _Header extends StatelessWidget {
  const _Header(
      {required this.step, required this.total, required this.onBack});
  final int step;
  final int total;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP ${step + 1} OF $total',
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: (step + 1) / total,
                    backgroundColor: AppColors.slateLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
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

class _Footer extends StatelessWidget {
  const _Footer(
      {required this.canAdvance,
      required this.isLast,
      required this.onNext});
  final bool canAdvance;
  final bool isLast;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: canAdvance ? onNext : null,
            icon: Icon(isLast
                ? Icons.check_circle_outline
                : Icons.arrow_forward_rounded),
            label: Text(isLast ? 'Finish setup' : 'Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.slateLight,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Shared step bits
// =====================================================================

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle, this.icon});
  final String title;
  final String subtitle;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.emerald, size: 24),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    this.tint = AppColors.emerald,
  });
  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;
  final Color tint;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tint : AppColors.slateLight,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? tint : AppColors.slateLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Step 1 — Pick role
// =====================================================================

class _RolePickerStep extends StatelessWidget {
  const _RolePickerStep({required this.selected, required this.onPick});
  final UserRole? selected;
  final ValueChanged<UserRole> onPick;
  @override
  Widget build(BuildContext context) {
    final options = [
      (UserRole.buyer, Icons.shopping_bag_outlined, 'Shop & receive escrow-protected orders. Optionally diaspora-delegate to a relative.'),
      (UserRole.vendor, Icons.storefront_outlined, 'List products or services. Vendors enter a Pending Verification queue before publishing.'),
      (UserRole.deliveryAgent, Icons.two_wheeler_outlined, 'Bridge vendors and recipients. Tasks come from broadcasts in your LGA.'),
      (UserRole.admin, Icons.shield_outlined, 'Govern the platform. Audit integrity, settle disputes, oversee distribution.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.account_circle_outlined,
          title: 'How will you use iGobi?',
          subtitle:
              'Pick the role that fits today. You can change it from your profile later.',
        ),
        for (final (role, icon, body) in options) ...[
          _OptionCard(
            icon: icon,
            title: role.label,
            body: body,
            selected: selected == role,
            onTap: () => onPick(role),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// =====================================================================
// Hub picker — used by Buyer, Vendor, Agent
// =====================================================================

class _HubPickerStep extends StatelessWidget {
  const _HubPickerStep({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onPick,
  });
  final String title;
  final String subtitle;
  final String? selected;
  final ValueChanged<String> onPick;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          icon: Icons.location_on_outlined,
          title: title,
          subtitle: subtitle,
        ),
        for (final h in igobiHubs) ...[
          _OptionCard(
            icon: Icons.location_on_outlined,
            title: h.name,
            body: '${h.lga}, ${h.state}',
            selected: selected == h.id,
            onTap: () => onPick(h.id),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// =====================================================================
// Diaspora step — toggle + recipient picker
// =====================================================================

class _DiasporaStep extends StatelessWidget {
  const _DiasporaStep({
    required this.enabled,
    required this.recipientHubId,
    required this.onToggle,
    required this.onPickRecipient,
  });
  final bool enabled;
  final String? recipientHubId;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onPickRecipient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.public,
          title: 'Buying for someone back home?',
          subtitle:
              'Diaspora Mode delegates visibility to the recipient’s LGA. You pay; escrow only releases when they confirm receipt.',
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateLight),
          ),
          child: SwitchListTile.adaptive(
            value: enabled,
            activeColor: AppColors.aiBlue,
            onChanged: onToggle,
            title: const Text(
              'Turn on Diaspora Mode',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            subtitle: const Text(
              'Optional. You can flip this any time from your profile.',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ),
        ),
        if (enabled) ...[
          const SizedBox(height: 14),
          const Text(
            'Pick the recipient hub',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          for (final h in igobiHubs) ...[
            _OptionCard(
              icon: Icons.location_on_outlined,
              title: h.name,
              body: '${h.lga}, ${h.state}',
              selected: recipientHubId == h.id,
              tint: AppColors.aiBlue,
              onTap: () => onPickRecipient(h.id),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

// =====================================================================
// Escrow briefing — buyer terminal step
// =====================================================================

class _EscrowBriefingStep extends StatelessWidget {
  const _EscrowBriefingStep(
      {required this.acknowledged, required this.onAck});
  final bool acknowledged;
  final VoidCallback onAck;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.lock_outline,
          title: 'How escrow protects you',
          subtitle:
              'Read this carefully — the trust contract is the spine of iGobi.',
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateLight),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BriefLine(
                  n: '1',
                  text:
                      'When you pay, funds enter iGobi escrow — not the vendor’s wallet.'),
              SizedBox(height: 10),
              _BriefLine(
                  n: '2',
                  text:
                      'Funds release only when you confirm receipt of the goods or service.'),
              SizedBox(height: 10),
              _BriefLine(
                  n: '3',
                  text:
                      'Disputes pause the release. An iGobi integrity officer reviews evidence from both sides.'),
              SizedBox(height: 10),
              _BriefLine(
                  n: '4',
                  text:
                      'Some categories add gates: McCoy Parts requires fitment verification; Farm Harvest requires quality confirmation.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onAck,
          icon: Icon(acknowledged
              ? Icons.check_circle_outline
              : Icons.radio_button_unchecked),
          label: Text(acknowledged ? 'Acknowledged' : 'I understand'),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                acknowledged ? AppColors.emerald : AppColors.charcoal,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            side: BorderSide(
              color: acknowledged ? AppColors.emerald : AppColors.slateLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _BriefLine extends StatelessWidget {
  const _BriefLine({required this.n, required this.text});
  final String n;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.emerald,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              n,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.charcoal,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Vendor steps
// =====================================================================

class _BusinessCategoryStep extends StatelessWidget {
  const _BusinessCategoryStep(
      {required this.selected, required this.onPick});
  final String? selected;
  final ValueChanged<String> onPick;

  static const _categories = [
    ('Energy Hub', Icons.local_gas_station_rounded,
        'Petroleum, gas, fuel logistics.'),
    ('FMCG', Icons.inventory_2_rounded,
        'Brand-direct fast-moving consumer goods.'),
    ('Convenience', Icons.local_convenience_store_outlined,
        'Physical neighbourhood store.'),
    ('Community Market', Icons.diversity_3_rounded,
        'Fashion, accessories, market commerce.'),
    ('Farm Harvest', Icons.agriculture_rounded,
        'Direct-from-farm produce supply.'),
    ('Artisan', Icons.handyman_rounded,
        'Service trades — plumbing, tailoring, electrical, etc.'),
    ('McCoy Parts', Icons.precision_manufacturing_rounded,
        'OEM and aftermarket auto parts dealer.'),
    ('McCoy Mechanic', Icons.car_repair_rounded,
        'Mechanic node — diagnostics, repair, fitment verification.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.storefront_outlined,
          title: 'Pick your specialty node',
          subtitle:
              'This determines which buyer signals you receive and how your listings are categorised.',
        ),
        for (final (name, icon, body) in _categories) ...[
          _OptionCard(
            icon: icon,
            title: name,
            body: body,
            selected: selected == name,
            onTap: () => onPick(name),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _VendorVerificationStep extends StatelessWidget {
  const _VendorVerificationStep();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.pending_actions_outlined,
          title: 'Verification queue',
          subtitle:
              'Your vendor account will be created in PENDING state. An iGobi officer reviews shop / expertise proofs within 24–48 h.',
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.upload_file_outlined, color: AppColors.goldDark),
                  SizedBox(width: 8),
                  Text(
                    'What you’ll be asked for',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDark),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text('• Shop / workshop address with a recent photo',
                  style:
                      TextStyle(color: AppColors.charcoal, fontSize: 12.5, height: 1.5)),
              Text('• ID or CAC certificate (sole prop or limited)',
                  style: TextStyle(
                      color: AppColors.charcoal, fontSize: 12.5, height: 1.5)),
              Text(
                  '• Optional: 1–3 references from the local trade community',
                  style: TextStyle(
                      color: AppColors.charcoal, fontSize: 12.5, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_outlined, color: AppColors.emerald),
                  SizedBox(width: 8),
                  Text(
                    'Inventory setup',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Once approved, you can bulk-upload via the Data Ingestion Portal (CSV or API) or list items manually from the Vendor Cockpit.',
                style: TextStyle(
                    color: AppColors.charcoal, fontSize: 12.5, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Delivery agent steps
// =====================================================================

class _DeliveryVehicleStep extends StatelessWidget {
  const _DeliveryVehicleStep(
      {required this.selected, required this.onPick});
  final String? selected;
  final ValueChanged<String> onPick;
  @override
  Widget build(BuildContext context) {
    final vehicles = [
      ('Bicycle', Icons.pedal_bike_outlined,
          'Short-radius errands — up to 4 km, parcels under 8 kg.'),
      ('Motorcycle', Icons.two_wheeler_outlined,
          'Wider radius — cross-LGA, parcels under 30 kg, weather-dependent.'),
      ('Van', Icons.local_shipping_outlined,
          'Bulky orders — cartons, mini-fleet, inter-state where allowed.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.two_wheeler_outlined,
          title: 'What do you ride?',
          subtitle:
              'Your vehicle decides the parcel weight and radius the system can assign you.',
        ),
        for (final (name, icon, body) in vehicles) ...[
          _OptionCard(
            icon: icon,
            title: name,
            body: body,
            selected: selected == name,
            onTap: () => onPick(name),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AgentClearanceStep extends StatelessWidget {
  const _AgentClearanceStep();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.security_outlined,
          title: 'Clearance & route permissions',
          subtitle:
              'Agents handle physical goods. We verify your identity and enable real-time route tracking before tasks land.',
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateLight),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChecklistRow(
                icon: Icons.badge_outlined,
                title: 'Identity verification',
                body:
                    'NIN or driver’s licence + a clear face photo.',
              ),
              SizedBox(height: 10),
              _ChecklistRow(
                icon: Icons.gps_fixed_outlined,
                title: 'Location permissions',
                body:
                    'Real-time tracking so vendors and buyers see your ETA.',
              ),
              SizedBox(height: 10),
              _ChecklistRow(
                icon: Icons.shield_outlined,
                title: 'Hub vetting',
                body:
                    'A short interview with your hub officer before your first dispatch.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.emerald, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 2),
              Text(body,
                  style: const TextStyle(
                      color: AppColors.slate, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Admin step
// =====================================================================

class _AdminLedgerStep extends StatelessWidget {
  const _AdminLedgerStep();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          icon: Icons.shield_outlined,
          title: 'Governance & transparency',
          subtitle:
              'Admins facilitate, they don’t over-rule. You’ll get scoped permissions and access to the Transparency Ledger.',
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateLight),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChecklistRow(
                icon: Icons.fact_check_outlined,
                title: 'Integrity Audit',
                body:
                    'Review escrow flows and dispute outcomes against the Igobi Constitution.',
              ),
              SizedBox(height: 10),
              _ChecklistRow(
                icon: Icons.gavel_outlined,
                title: 'Dispute Settlement',
                body:
                    'Mediate buyer–vendor conflicts with evidence from both sides.',
              ),
              SizedBox(height: 10),
              _ChecklistRow(
                icon: Icons.account_tree_outlined,
                title: 'Distribution Oversight',
                body:
                    'See the 10% religious-organisation contribution flow without exposing user data.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
