# IGOBI Mobile

The primary IGOBI product. Flutter, Android-first, offline-capable. This scaffold renders the full first-run flow (splash → onboarding → sign in/up → home with marketplace, orders, Vanguard AI chat, profile) using seeded data — no backend required to view the UI.

## What works right now

| Surface           | Status                                                                          |
| ----------------- | ------------------------------------------------------------------------------- |
| Splash            | ✅ Animated, gradient brand mark                                                 |
| Onboarding        | ✅ 3-slide carousel with trust / AI / delivery messaging                         |
| Sign in / sign up | ✅ Validated forms, Google placeholder, navigates to home                        |
| Marketplace home  | ✅ Categories grid, escrow banner, verified vendors carousel, trending products  |
| Vendor detail     | ✅ Profile, trust stats, listings grid                                           |
| Orders            | ✅ Status pills (in-escrow / in-production / out-for-delivery) with ETAs         |
| Vanguard AI       | ✅ Chat UI with AI gradient brand, prefilled conversation                        |
| Profile           | ✅ KYC badge, account sections, sign-out                                         |

## Run it

### Prerequisite

Install the Flutter SDK: <https://docs.flutter.dev/get-started/install>. Verify with `flutter doctor`.

### Easiest: Flutter web (Chrome)

```bash
cd apps/igobi-mobile
flutter pub get
flutter run -d chrome
```

A Chrome tab opens with the running app. Hot-reload with `r`, hot-restart with `R`.

### Android emulator

```bash
flutter emulators           # list emulators
flutter emulators --launch <id>
flutter run                 # picks the running emulator
```

### Windows desktop

```bash
flutter config --enable-windows-desktop
flutter run -d windows
```

## Project layout

```
lib/
├── main.dart                      # entrypoint, ProviderScope
├── app.dart                       # MaterialApp.router + theme
├── core/
│   ├── router/app_router.dart     # go_router config
│   └── theme/
│       ├── app_colors.dart        # brand palette
│       └── app_theme.dart         # ThemeData (light + dark)
└── features/
    ├── splash/                    # 1.5s brand intro
    ├── onboarding/                # 3-slide carousel
    ├── auth/                      # sign in / sign up
    ├── home/home_shell.dart       # bottom-nav shell
    ├── marketplace/               # main shopping surface + widgets
    ├── orders/                    # order tracking
    ├── vanguard/                  # AI account-officer chat
    └── profile/                   # account & settings
```

## Design tokens

| Token            | Hex       | Usage                              |
| ---------------- | --------- | ---------------------------------- |
| `emerald`        | `#047857` | Primary brand, CTAs, escrow surfaces |
| `gold`           | `#D4A24C` | Accents, ratings                   |
| `charcoal`       | `#1F2937` | Body text                          |
| `softWhite`      | `#FAFAF7` | Backgrounds                        |
| `aiBlue`         | `#4F46E5` | Anything AI-driven (Vanguard, ISO) |

## Next steps

- [ ] Wire sign-in/up to `services/auth-service` (Dio client + secure token storage)
- [ ] Replace seed data with a real `vendor-service` client
- [ ] Offline-first cache (Drift or Isar) for product lists and order state
- [ ] Push notifications (FCM) for order status changes
- [ ] i18n scaffolding (English first, Yoruba/Hausa/Igbo next)
- [ ] Map-backed delivery tracking on the Orders screen
"# igobi-mobile-" 
