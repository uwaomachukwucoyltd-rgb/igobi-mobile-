import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Clean white onboarding carousel for the customer app.
///
/// Top: back + Skip. Center: stacked brand-color icon card. Below: mixed-
/// weight title, subtitle, dots, full-width rounded brand "Next" button.
/// Footer: "Already a member? Sign in" link.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;

  static const Color _brand = AppColors.emerald;

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.verified_user_outlined,
      titleLead: 'Shop',
      titleEmphasis: 'without',
      titleTail: '\nsecond-guessing.',
      body:
          'Every vendor on iGobi is KYC-verified. Pay through escrow — your money is safe until your order is in your hands.',
    ),
    _Slide(
      icon: Icons.smart_toy_outlined,
      titleLead: 'Vanguard does the',
      titleEmphasis: 'chasing.',
      titleTail: '\nYou do the choosing.',
      body:
          'Track orders, ask questions, raise disputes — Vanguard answers around the clock and escalates to a human only when it matters.',
    ),
    _Slide(
      icon: Icons.shopping_basket_outlined,
      titleLead: 'Fuel, food, fashion,',
      titleEmphasis: 'farm',
      titleTail: ' —\none app.',
      body:
          'Local-first marketplace. LPG, FMCG, farm produce, artisans, mechanics, parts. Real-time delivery tracking, transparent fees.',
    ),
  ];

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      context.go('/sign-up');
    } else {
      _pager.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _back() {
    _pager.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() => context.go('/sign-up');

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              _TopBar(
                brand: _brand,
                onBack: _page == 0 ? null : _back,
                onSkip: _skip,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pager,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlideView(
                    slide: _slides[i],
                    brand: _brand,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _Dots(count: _slides.length, active: _page, color: _brand),
              const SizedBox(height: 16),
              _ContinueButton(
                label: isLast ? 'Get started' : 'Next',
                color: _brand,
                onPressed: _next,
              ),
              SizedBox(height: 12 + media.padding.bottom * 0.2),
              GestureDetector(
                onTap: () => context.go('/sign-in'),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'Already a member? ',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                          color: _brand,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Slide content
// ============================================================

class _Slide {
  const _Slide({
    required this.icon,
    required this.titleLead,
    required this.titleEmphasis,
    required this.titleTail,
    required this.body,
  });

  final IconData icon;
  final String titleLead;
  final String titleEmphasis;
  final String titleTail;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.brand});
  final _Slide slide;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _StackedIconCard(icon: slide.icon, brand: brand),
        const SizedBox(height: 36),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.charcoal,
              fontSize: 26,
              fontWeight: FontWeight.w500,
              height: 1.25,
              letterSpacing: -0.6,
            ),
            children: [
              TextSpan(text: '${slide.titleLead} '),
              TextSpan(
                text: slide.titleEmphasis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              TextSpan(text: slide.titleTail),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedIconCard extends StatelessWidget {
  const _StackedIconCard({required this.icon, required this.brand});
  final IconData icon;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 16,
            top: 24,
            child: Transform.rotate(
              angle: -0.08,
              child: _CardTile(
                color: brand.withValues(alpha: 0.18),
                size: 170,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 24,
            child: Transform.rotate(
              angle: 0.08,
              child: _CardTile(
                color: brand.withValues(alpha: 0.18),
                size: 170,
              ),
            ),
          ),
          _CardTile(
            color: brand,
            size: 200,
            child: Icon(icon, color: Colors.white, size: 76),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.color,
    required this.size,
    this.child,
  });
  final Color color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ============================================================
// Chrome
// ============================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.brand, required this.onBack, required this.onSkip});
  final Color brand;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (onBack != null)
            _CircleIconButton(icon: Icons.arrow_back, onTap: onBack!)
          else
            const SizedBox(width: 40, height: 40),
          const Spacer(),
          GestureDetector(
            onTap: onSkip,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: brand,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.softWhite,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: AppColors.charcoal),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, required this.color});
  final int count;
  final int active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? color : AppColors.slateLight,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
