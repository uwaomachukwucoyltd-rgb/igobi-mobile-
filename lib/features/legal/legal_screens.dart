import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Bundled legal text. Replace the `[YOUR_LEGAL_TEXT]` markers with text from
/// your counsel before submission. The strings here exist so Apple and Google
/// reviewers can crawl the screens in-app without requiring network access.
///
/// You should ALSO host these at:
///   https://igobi.app/privacy
///   https://igobi.app/terms
/// and provide both URLs in the store listings (Privacy Policy URL is
/// mandatory for both Play and the App Store).

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _LegalShell(
      title: 'Privacy Policy',
      lastUpdated: 'Effective: 2026-05-17',
      sections: _privacySections,
      url: 'https://igobi.app/privacy',
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _LegalShell(
      title: 'Terms of Service',
      lastUpdated: 'Effective: 2026-05-17',
      sections: _termsSections,
      url: 'https://igobi.app/terms',
    );
  }
}

class _LegalShell extends StatelessWidget {
  const _LegalShell({
    required this.title,
    required this.lastUpdated,
    required this.sections,
    required this.url,
  });
  final String title;
  final String lastUpdated;
  final List<_Section> sections;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.slateLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.slate, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastUpdated,
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final s in sections) ...[
              Text(
                s.heading,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.body,
                style: const TextStyle(
                  color: AppColors.charcoal,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slateLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest version online',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'For questions, write to legal@igobi.app',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.heading, this.body);
  final String heading;
  final String body;
}

// ---- PRIVACY POLICY -----------------------------------------------------

const _privacySections = <_Section>[
  _Section(
    '1. Who we are',
    'iGobi Technologies Ltd ("iGobi", "we") operates the iGobi Mobile app and '
        'the iGobi marketplace platform. You can reach us at legal@igobi.app or '
        'at our registered office in Lagos, Nigeria.',
  ),
  _Section(
    '2. What data we collect',
    'Account data: name, email, phone, password (hashed with argon2id). '
        'Profile data: chosen role, primary hub (LGA), Diaspora Mode setting, '
        'recipient hub, addresses you save, optional religious organisation. '
        'Transactional data: orders, escrow ledger entries, payment references, '
        'dispute records. Device data: app version, OS version, device model, '
        'IP address (for security and fraud detection). Optional data: photos '
        'you upload to disputes, voice transcripts when you use the Concierge.',
  ),
  _Section(
    '2a. Location data',
    'We collect location data only with your permission and only for the '
        'features that need it: (a) delivery address geocoding so vendors and '
        'agents can find you; (b) live agent tracking while an order is out '
        'for delivery — your agent\'s phone shares its position with you and '
        'with us until the order is marked delivered, then sharing stops; '
        '(c) energy-hub proximity routing so a verified LPG depot near you can '
        'be matched to your refill. We never sell location data, and we never '
        'share your home address with another customer. You can disable '
        'background location at any time in your phone settings; foreground '
        'location is still needed during active deliveries.',
  ),
  _Section(
    '3. How we use it',
    'To run your account and process orders. To release or hold escrow per '
        'the protocol. To detect fraud, abuse and chargebacks. To improve the '
        'product (aggregated, never identifiable). To comply with Nigerian '
        'tax, AML, and consumer-protection law.',
  ),
  _Section(
    '4. Who we share it with',
    'Service providers strictly under data-processing agreements: Flutterwave '
        '(payments), our cloud infrastructure provider, our SMS/email vendors, '
        'and our crash/analytics vendor (when enabled). We never sell your '
        'data and we do not run third-party advertising trackers.',
  ),
  _Section(
    '5. Your rights',
    'You can access, correct, export or delete your data at any time. Delete '
        'is available in the app under Profile → Security → Delete account. '
        'We hard-delete or anonymise within 30 days, except where law requires '
        'us to retain a record (tax, AML, dispute audit). To exercise other '
        'rights, write to privacy@igobi.app.',
  ),
  _Section(
    '6. Data retention',
    'Active account data: while your account is open. Closed accounts: '
        'transactional records retained for 7 years (Nigerian tax law). '
        'Marketing consents and device logs: 24 months. Anything else: '
        'deleted within 30 days of account closure.',
  ),
  _Section(
    '7. International transfers',
    'Your data is processed primarily in Nigeria. Some processors operate in '
        'the EU/US under standard contractual clauses. We will not transfer '
        'data to a country with materially weaker protections without your '
        'explicit consent.',
  ),
  _Section(
    '8. Children',
    'iGobi is not intended for users under 18. We do not knowingly collect '
        'data from minors. If we learn we have, we delete it.',
  ),
  _Section(
    '9. Changes',
    'We will notify you in-app and by email at least 14 days before any '
        'material change. Your continued use after the effective date means '
        'you accept the change.',
  ),
];

// ---- TERMS OF SERVICE ----------------------------------------------------

const _termsSections = <_Section>[
  _Section(
    '1. Agreement',
    'By creating an account or using the iGobi Mobile app you agree to these '
        'Terms and to the Privacy Policy. If you do not agree, do not use the '
        'app.',
  ),
  _Section(
    '2. Eligibility',
    'You must be at least 18 years old and legally able to enter contracts. '
        'You must use accurate identity information. One person, one account.',
  ),
  _Section(
    '3. Marketplace role',
    'iGobi is a marketplace and escrow operator. We are not the seller of '
        'goods or the provider of services listed by vendors, artisans, '
        'mechanics, dealers or farms. We facilitate the trust contract '
        'between you and the counterparty.',
  ),
  _Section(
    '4. Payments + escrow',
    'Payments are processed by Flutterwave and held in escrow by iGobi. '
        'Funds release on confirmation of receipt or, in protocols that '
        'require it, on third-party verification (e.g. Fitment Verification '
        'for McCoy Parts, Quality Confirmation for Farm Harvest). Direct-Sync '
        'categories (Energy Hub) bypass escrow per the Direct-Sync clause.',
  ),
  _Section(
    '5. Disputes',
    'Open a dispute within 7 days of marked delivery. iGobi integrity '
        'officers review evidence from both parties. The decision is binding '
        'unless overturned by a Nigerian court of competent jurisdiction.',
  ),
  _Section(
    '6. Direct settlement (Energy Hub)',
    'For verified energy nodes, iGobi processes payment directly to the '
        'supplying station and does not hold the funds. You waive the escrow '
        'guarantee for these transactions in exchange for instant dispatch. '
        'Quality complaints route to the supplying station per the Direct-Sync '
        'addendum.',
  ),
  _Section(
    '7. Acceptable use',
    'You will not: impersonate others, sell prohibited goods (firearms, '
        'controlled drugs, counterfeit currency, child sexual abuse material, '
        'wildlife products), abuse the dispute system, scrape the app, or '
        'reverse-engineer the escrow ledger.',
  ),
  _Section(
    '8. Suspension + termination',
    'We may suspend or terminate accounts for material breach of these Terms '
        'or for fraud-detection signals. You may close your account at any '
        'time from Profile → Security → Delete account.',
  ),
  _Section(
    '9. Liability',
    'To the maximum extent permitted by Nigerian law, iGobi is not liable '
        'for indirect, incidental or consequential losses. Our aggregate '
        'liability is capped at the total fees we collected from you in the '
        'twelve months before the claim.',
  ),
  _Section(
    '10. Governing law',
    'These Terms are governed by the laws of the Federal Republic of '
        'Nigeria. Disputes go to the courts of Lagos State, Nigeria, except '
        'where consumer-protection law gives you the right to bring a claim '
        'in your home court.',
  ),
];

// ---- Inline link widget used by sign-up + profile ------------------------

/// Two tappable links (Privacy + Terms) for inline consent rows. Pushes the
/// in-app screens via go_router; never opens external browser, so Apple's
/// review bot can see the content.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      color: AppColors.slate,
      fontSize: compact ? 11 : 12,
      height: 1.5,
    );
    final link = TextStyle(
      color: AppColors.emerald,
      fontSize: compact ? 11 : 12,
      fontWeight: FontWeight.w700,
      height: 1.5,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(
            text: 'Terms',
            style: link,
            recognizer: _Tap(() => context.push('/legal/terms')),
          ),
          const TextSpan(text: ' and acknowledge our '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: _Tap(() => context.push('/legal/privacy')),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

class _Tap extends TapGestureRecognizer {
  _Tap(VoidCallback handler) {
    onTap = handler;
  }
}
