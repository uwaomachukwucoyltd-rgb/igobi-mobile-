import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import 'religious_org_service.dart';
import 'sign_in_screen.dart';
import 'state/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otherOrgName = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  // Optional religious-organisation picker.
  bool _supportReligiousOrg = false;
  String? _pickedOrgSlug;
  bool _pickedOther = false;

  /// Curated short-list shown at signup. Slugs match seeded vendor-service
  /// ReligiousOrganization rows. "Other" lets the user free-text a name.
  static const _prominentOrgs = <_OrgOption>[
    _OrgOption(slug: 'rccg', label: 'RCCG', kind: 'Christian'),
    _OrgOption(slug: 'living-faith', label: 'Living Faith (Winners)', kind: 'Christian'),
    _OrgOption(slug: 'catholic', label: 'Catholic Church', kind: 'Christian'),
    _OrgOption(slug: 'nasfat', label: 'NASFAT', kind: 'Muslim'),
    _OrgOption(slug: 'mfm', label: 'Mountain of Fire', kind: 'Christian'),
    _OrgOption(slug: 'tijaniyya', label: 'Tijaniyya', kind: 'Muslim'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _otherOrgName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          );

      // Best-effort religious-org link after the session lands. Failures
      // here don't block account creation — the user can update later
      // from Profile.
      if (_supportReligiousOrg) {
        final orgName = _pickedOther
            ? _otherOrgName.text.trim()
            : null;
        if (_pickedOrgSlug != null || (orgName != null && orgName.isNotEmpty)) {
          try {
            await ref.read(religiousOrgServiceProvider).setForCurrentUser(
                  orgSlugOrId: _pickedOrgSlug,
                  freeTextName: orgName,
                );
          } catch (_) {/* keep going */}
        }
      }

      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } on NetworkException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      logoTint: AppColors.emerald,
      brand: AppColors.emerald,
      brandDark: AppColors.emeraldDark,
      heading: 'Create your Account',
      showBack: true,
      child: Column(
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                AuthTextField(
                  controller: _name,
                  label: 'Full name',
                  keyboardType: TextInputType.name,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Enter your email';
                    if (!t.contains('@') || !t.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _phone,
                  label: 'Phone (optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _password,
                  label: 'Password',
                  obscure: _obscure,
                  trailing: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.slate,
                      size: 20,
                    ),
                  ),
                  validator: (v) {
                    final p = v ?? '';
                    if (p.isEmpty) return 'Choose a password';
                    if (p.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  obscure: _obscureConfirm,
                  trailing: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.slate,
                      size: 20,
                    ),
                  ),
                  validator: (v) {
                    if ((v ?? '') != _password.text) {
                      return 'Passwords don\'t match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ReligiousOrgSection(
            enabled: _supportReligiousOrg,
            onToggle: (v) => setState(() {
              _supportReligiousOrg = v;
              if (!v) {
                _pickedOrgSlug = null;
                _pickedOther = false;
                _otherOrgName.clear();
              }
            }),
            orgs: _prominentOrgs,
            pickedSlug: _pickedOrgSlug,
            pickedOther: _pickedOther,
            otherController: _otherOrgName,
            onPick: (slug) => setState(() {
              _pickedOrgSlug = slug;
              _pickedOther = false;
            }),
            onPickOther: () => setState(() {
              _pickedOther = true;
              _pickedOrgSlug = null;
            }),
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: 'Sign up',
            color: AppColors.emerald,
            loading: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 28),
          AuthFooterLink(
            prompt: 'Already have an account?',
            actionLabel: 'Sign in',
            onTap: () => context.go('/sign-in'),
            tint: AppColors.emerald,
          ),
        ],
      ),
    );
  }
}

class _OrgOption {
  const _OrgOption({required this.slug, required this.label, required this.kind});
  final String slug;
  final String label;
  final String kind;
}

class _ReligiousOrgSection extends StatelessWidget {
  const _ReligiousOrgSection({
    required this.enabled,
    required this.onToggle,
    required this.orgs,
    required this.pickedSlug,
    required this.pickedOther,
    required this.otherController,
    required this.onPick,
    required this.onPickOther,
  });

  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<_OrgOption> orgs;
  final String? pickedSlug;
  final bool pickedOther;
  final TextEditingController otherController;
  final ValueChanged<String> onPick;
  final VoidCallback onPickOther;

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
          Row(
            children: [
              Checkbox(
                value: enabled,
                onChanged: (v) => onToggle(v ?? false),
                activeColor: AppColors.emerald,
              ),
              const Expanded(
                child: Text(
                  'Support a religious organisation (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 36, right: 4, bottom: 4),
            child: Text(
              "We donate 10% of iGobi's fee on every order to your community. Pick one or skip.",
              style: TextStyle(color: AppColors.slate, fontSize: 11.5, height: 1.45),
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in orgs)
                  _OrgChip(
                    label: o.label,
                    sub: o.kind,
                    selected: pickedSlug == o.slug,
                    onTap: () => onPick(o.slug),
                  ),
                _OrgChip(
                  label: 'Other',
                  sub: 'Type a name',
                  selected: pickedOther,
                  onTap: onPickOther,
                  isOther: true,
                ),
              ],
            ),
            if (pickedOther) ...[
              const SizedBox(height: 12),
              TextField(
                controller: otherController,
                maxLength: 120,
                decoration: InputDecoration(
                  hintText: 'Name of your church / mosque / community',
                  hintStyle: const TextStyle(color: AppColors.slate, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.slateLight, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.emerald, width: 1.4),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OrgChip extends StatelessWidget {
  const _OrgChip({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.isOther = false,
  });
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  final bool isOther;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.slateLight,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.charcoal,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.slate,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
