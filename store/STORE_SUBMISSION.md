# IGOBI Mobile — Store Submission Checklist

> **Honest timeline:** Public release on Play Store + App Store this weekend (May 16–17) is not realistic. Apple Developer enrollment, App Store review, and Google Play first-app review each have hard floors. Use **TestFlight + Play Internal Testing** to ship to invited testers within 24–48h; plan public release for the following week.

## Identity

| Field             | Value                                                  |
| ----------------- | ------------------------------------------------------ |
| Display name      | IGOBI                                                  |
| Full name         | IGOBI — Trusted commerce                               |
| Tagline           | Empowering Women. Enabling Better Living.              |
| Android package   | `app.igobi.customer`                                   |
| iOS bundle id     | `app.igobi.customer`                                   |
| Primary category  | Shopping (Android) · Shopping (iOS)                    |
| Secondary         | Lifestyle                                              |
| Content rating    | 4+ (no objectionable content)                          |

## Required assets

| Asset                                | Size                               | Status |
| ------------------------------------ | ---------------------------------- | ------ |
| App icon                             | 1024×1024 PNG (no transparency)    | ⬜ TODO |
| Android adaptive icon foreground/bg  | 432×432 PNG each                   | ⬜ TODO |
| iOS launch screen / storyboard       | (Flutter generates from theme)     | ✅ Auto |
| Feature graphic (Play)               | 1024×500                           | ⬜ TODO |
| Phone screenshots ×8 (per OS)        | 1080×1920 portrait minimum         | ⬜ TODO |
| Tablet screenshots ×6 (Play)         | 1920×1200                          | ⬜ optional |
| Privacy policy URL                   | Public, hosted (e.g. igobi.app/privacy) | ⬜ TODO |
| Terms of service URL                 | Public                             | ⬜ TODO |
| Support URL                          | Public                             | ⬜ TODO |

## Backend prerequisites (mandatory before reviewers will approve)

- [ ] `auth-service`, `payment-service`, `escrow-service`, `vendor-service`, `notification-service` deployed at `https://api.igobi.app` (or staging URL accessible to reviewers)
- [ ] MongoDB (Atlas or self-hosted replica set) + Redis running in production cloud
- [ ] HTTPS certificate (Let's Encrypt + Caddy/Nginx is fine for v1)
- [ ] Flutterwave **production** keys configured; webhook URL + `FLUTTERWAVE_WEBHOOK_HASH` whitelisted
- [ ] At least one seeded test account so Apple/Google reviewers can sign in
- [ ] App fed all base URLs + `SENTRY_DSN` at build time (see build commands below)
- [ ] Sentry project created and DSN injected into the mobile build and each service `.env`
- [ ] Firebase project created and `flutterfire configure` run — see [`FCM_SETUP.md`](../FCM_SETUP.md). Required before push works; not required for first TestFlight upload.

## Privacy / legal

- [ ] **Privacy policy** at `https://igobi.app/privacy` — must mention: email, phone, KYC docs, payment metadata, location-on-delivery, push tokens.
- [ ] **Terms of service** at `https://igobi.app/terms` — escrow rules, dispute process, refund policy.
- [ ] **Apple App Privacy Disclosure** (filled in App Store Connect) — data types: contact info, identifiers, payment info, location.
- [ ] **Google Play Data Safety form** — same categories, no third-party-sharing claims that aren't true.
- [ ] **NDPR compliance** (Nigeria) — register with NITDA if required, ensure data resides per policy.

## Developer accounts

- [ ] **Google Play Console** — $25 one-time, account active. Verification: ~hours.
- [ ] **Apple Developer Program** — $99/year. Individual: ~24h. Organisation: D-U-N-S number lookup + manual review, **can take 1–2 weeks** for new orgs.
- [ ] Tax + banking info filled in both consoles (required to publish even free apps).

## Build & sign

### Android
```bash
cd apps/igobi-mobile
# Keystore (do this once, store on a hardware key)
keytool -genkey -v -keystore ~/igobi-release.keystore -alias igobi \
  -keyalg RSA -keysize 4096 -validity 10000
# Configure android/key.properties (gitignored) — see Flutter docs.
# Once Firebase is set up (FCM_SETUP.md) uncomment the google-services
# plugin in android/app/build.gradle.kts.
flutter build appbundle --release \
  --dart-define=AUTH_BASE_URL=https://api.igobi.app \
  --dart-define=PAYMENT_BASE_URL=https://api.igobi.app \
  --dart-define=ESCROW_BASE_URL=https://api.igobi.app \
  --dart-define=VENDOR_BASE_URL=https://api.igobi.app \
  --dart-define=NOTIFICATION_BASE_URL=https://api.igobi.app \
  --dart-define=SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project>
# Upload android/app/build/outputs/bundle/release/app-release.aab to Play Console
```

### iOS
Requires macOS + Xcode. From a Mac:
```bash
cd apps/igobi-mobile
flutter build ipa --release \
  --dart-define=AUTH_BASE_URL=https://api.igobi.app \
  --dart-define=PAYMENT_BASE_URL=https://api.igobi.app \
  --dart-define=ESCROW_BASE_URL=https://api.igobi.app \
  --dart-define=VENDOR_BASE_URL=https://api.igobi.app \
  --dart-define=NOTIFICATION_BASE_URL=https://api.igobi.app \
  --dart-define=SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project>
# Open build/ios/archive/Runner.xcarchive in Xcode → Distribute → App Store Connect
```

## Realistic weekend plan

**Friday**
- Buy and configure `igobi.app` domain, point DNS to a small VPS (Hetzner CX22 or DigitalOcean basic).
- Deploy `auth-service` + `payment-service` + `escrow-service` behind Caddy with auto-TLS.
- Stand up a Postgres + Redis (managed or self-hosted).
- Apply for **Apple Developer Program** today — clock is ticking.
- Register for **Google Play Console** (faster).

**Saturday**
- Generate icons + 8 screenshots (use Figma → Inkscape → resize, or Flutter's `flutter_launcher_icons` package).
- Publish privacy policy + terms (simple Next.js static page deployed to Vercel).
- Build signed AAB; upload to **Play Internal Testing** track.
- If Apple Dev account approved, build IPA and upload to **TestFlight**.

**Sunday**
- Invite internal testers (emails) to TestFlight + Play Internal Testing.
- Have testers exercise: sign up → browse marketplace → simulate Flutterwave test payment → escrow hold → confirm release.
- Fix any P0 bugs.

**Following week**
- Submit for **public** Play Store + App Store review (Mon–Tue).
- Approval likely Wed–Fri for Play; longer for App Store given payment surface area.

## Code status

Done:

- [x] Real Flutterwave checkout wired (`lib/features/cart/cart_sheet.dart` → `payment-service`)
- [x] **Split commerce model live**: PHYSICAL products pay the vendor directly (no escrow — `payment-service` credits `vendor-service` payout obligations on SUCCESS). SERVICE products use escrow. Mixed-type carts are blocked at checkout. See `memory/trust_model.md`.
- [x] Customer rating system live: 1-5 stars + optional complaint POSTed to `vendor-service`. ≤2 stars with complaint counts as unresolved; 3 unresolved auto-suspends the vendor. Reactivation when the filing customer marks resolved.
- [x] Auto-release scheduler in `escrow-service` (5-min cron) drains expired service escrows to the vendor.
- [x] Real marketplace data via `vendor-service` (port 3004). Buyer home + vendor-detail screens read from API; seed script populates 6 vendors + 12 products (10 PHYSICAL + 2 SERVICE).
- [x] Sentry crash reporting (mobile + 4 services). Enabled when `--dart-define=SENTRY_DSN=…` is passed at build time.
- [x] Privacy & data consent toggles in Profile (gates Sentry at runtime via `beforeSend`)
- [x] FCM push scaffolding (`lib/core/push/push_service.dart`). **Needs `flutterfire configure` and Gradle plugin uncommented before push works** — see [`FCM_SETUP.md`](../FCM_SETUP.md).
- [x] Bundle id `app.igobi.customer` on Android (+ iOS once Xcode project is regenerated).
- [x] Universal links: `https://igobi.app` intent-filter wired in `AndroidManifest.xml`.
- [x] ProGuard rules cover dio, secure_storage, webview, Sentry, FCM.

Outstanding (cannot fix in code alone):

- [ ] Onboard real vendors via `vendor-service` admin endpoints (or `pnpm seed` with revised data). The seed script's current 6 vendors are fictional placeholders — replace with real partner businesses before public submission. Each vendor must also have `payoutBankCode`, `payoutAccountNumber`, `payoutAccountName` filled before they can receive money.
- [ ] **Vendor payout settlement automation.** `vendor-service` tracks `pendingPayoutMinor` per vendor and inserts `Payout` rows for each PHYSICAL SUCCESS. Settlement to real bank accounts is currently manual via `POST /payouts/:id/settle`. Wire the Flutterwave Transfer API for a nightly batch payout job before going live.
- [ ] Per-vendor split for multi-vendor carts. Currently we credit the first item's vendor; needs a future orders-service that splits the payment by line item.
- [x] Notification-service token registration — wired in `lib/core/push/device_registration.dart`. Fires on `AuthSignedIn` transitions (`lib/app.dart`) and on first frame of `HomeShell` for restored sessions. Token refreshes re-register automatically.
- [ ] Real product photography in `vendor-service` (`imageUrl` field) and a `media-service` upload pipeline.
- [ ] In-app review prompt (consider `in_app_review` package after first stable release).
- [ ] Legal copy review — `lib/features/legal/legal_screens.dart` contains `[YOUR_LEGAL_TEXT]` placeholders. Replace with counsel-reviewed text before submission.
