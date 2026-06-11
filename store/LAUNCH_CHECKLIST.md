# IGOBI Mobile — Store Launch Checklist

Living status of what's done vs. what only YOU can do (accounts, money, hosting).
Generated during local bring-up. Items marked ✅ were completed in the repo;
🟡 = needs your action; 🔴 = hard blocker for store approval.

---

## A. Done in the repo (code/config)

- ✅ Backend `/auth/account/delete` route implemented + tested (App Store 5.1.1(v) / Play account-deletion policy).
- ✅ Android: Firebase `google-services` plugin made conditional (builds without `google-services.json`); `POST_NOTIFICATIONS` permission added (Android 13+).
- ✅ iOS: `PrivacyInfo.xcprivacy` privacy manifest added; `Runner.entitlements` (Sign in with Apple + push) created and wired into the Xcode project.
- ✅ Backend running locally against your MongoDB Atlas cluster; auth + account-delete verified end-to-end.
- ✅ Env wired: root `.env`, admin `.env`, all 5 service `.env`, Firebase service-account key.

---

## B. YOU must do — accounts & credentials

- 🟡 **Rotate the secrets you pasted in chat** (Paystack `sk_live`, Flutterwave secret, Mongo Atlas password, Firebase service-account key). They are in the transcript — treat as compromised.
- 🟡 **Use Paystack/Flutterwave TEST keys** for all non-production builds. Never ship `sk_live` in a debug/QA build.
- 🟡 **Firebase mobile config files** (separate from the admin service-account key):
  - Android: `flutterfire configure` → writes `android/app/google-services.json`.
  - iOS: same command → writes `ios/Runner/GoogleService-Info.plist` and the Google reversed-client-id URL scheme.
- 🟡 **Apple Developer** ($99/yr — you've paid): create App ID `app.igobi.igobi`, enable **Sign in with Apple** + **Push Notifications** capabilities, create the APNs key, and a distribution provisioning profile.
- 🟡 **Google Play Console** ($25 — you've paid): create the app, set up **Play App Signing**, generate an **upload keystore** and `android/key.properties`.

---

## C. YOU must do — store listings

- 🔴 **Hosted Privacy Policy URL + Terms URL** (e.g. `https://igobi.app/privacy`, `/terms`). Required by both stores. In-app legal copy still has `[YOUR_LEGAL_TEXT]` placeholders (`lib/features/legal/legal_screens.dart`) — replace with real text.
- 🔴 **Screenshots** (per device class), **app icon 1024²**, **feature graphic 1024×500** (Play). None present in `store/` yet.
- 🟡 **App Privacy "nutrition label"** (App Store Connect) and **Data Safety form** (Play) — answers must match `PrivacyInfo.xcprivacy` / data the app collects.
- 🟡 **Content/age rating** questionnaires (both stores).
- 🟡 Resolve display-name casing: native shows `iGobi mobile App`; store name should be `IGOBI`.
- 🟡 iOS bundle-id consistency: project uses `app.igobi.igobi` (store doc once said `app.igobi.customer`) — pick one and match the App Store Connect record.

---

## D. Product gaps to decide before launch (from the audit)

- 🔴 **6 of 8 commerce hubs are simulated** (Community, Artisan, McCoy Parts/Mechanic use random pools; Farm/FMCG/Convenience/Energy are hardcoded). Either wire to real services or remove/hide before review — stores reject apps advertising non-functional features.
- 🔴 **"Concierge" AI tab is a keyword script**, not an LLM, but marketed as "Flash/Pro AI models". Wire a real AI backend (you have an `ANTHROPIC_API_KEY` slot in root `.env`) or stop advertising it as AI.
- 🟡 **No automated tests** on the money paths (cart/escrow/auth) — risky for a payments app.

---

## E. Production backend (separate from local dev)

The local run uses your Atlas cluster + `node --env-file`. For production `api.igobi.app` you still need:

- 🔴 A deployment + **single-origin gateway** (the app calls one host but there are 5 services, and `/notifications` is claimed by two of them). No gateway/k8s/Terraform exists in the repo yet.
- 🟡 Domain `api.igobi.app` + TLS, the 5 services deployed (Dockerfiles exist), shared `JWT_ACCESS_SECRET`, Firebase Admin, live payment keys, SMTP.

### Local-dev fixes applied that need a proper version for prod
- `@prisma/client` runtime resolution was symlinked per-service to the generated client (`prisma/client`). Proper fix: import the generated client directly or add a postinstall link step — symlinks don't survive `pnpm install`.
- `express` was symlinked into `payment-service` (it imports `express` but doesn't declare it). Proper fix: add `express` to `payment-service/package.json`.
- Remove the cleartext `<domain-config>` (incl. `192.168.1.8`) from `android/app/src/main/res/xml/network_security_config.xml` before release.
