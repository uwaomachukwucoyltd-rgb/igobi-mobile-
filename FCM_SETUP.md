# FCM Setup — igobi-mobile

The push-notification code in `lib/core/push/push_service.dart` is already
wired into `main.dart`. It will silently no-op until Firebase Cloud Messaging
is configured for both platforms. This file is the checklist for that.

The app will continue to build and run **without** these steps — push just
stays disabled. You should complete this before public release.

---

## 1. Create the Firebase project

1. Open https://console.firebase.google.com → **Add project**.
2. Project name: `igobi-customer` (or whatever matches your account-naming).
   Disable Google Analytics for the project unless you have an opted-in
   consent flow ready — Apple App Privacy disclosure penalises any SDK that
   collects without consent.
3. Inside the project → **Project settings → General** → note the project ID.

## 2. Install the FlutterFire CLI

One-time, on your dev machine:

```bash
dart pub global activate flutterfire_cli
# Make sure the pub global bin is on PATH:
#   macOS / Linux  →  export PATH="$PATH:$HOME/.pub-cache/bin"
#   Windows        →  the installer prints the right entry; usually
#                     %LOCALAPPDATA%\Pub\Cache\bin
```

You'll also need the Firebase CLI logged in:

```bash
npm i -g firebase-tools
firebase login
```

## 3. Configure both platforms

From the `apps/igobi-mobile/` directory:

```bash
flutterfire configure \
  --project=<firebase-project-id> \
  --platforms=android,ios \
  --android-package-name=app.igobi.customer \
  --ios-bundle-id=app.igobi.customer
```

This creates / writes three things:

| File                                                | What                                                          |
| --------------------------------------------------- | ------------------------------------------------------------- |
| `lib/firebase_options.dart`                         | Per-platform Firebase config the Dart side optionally reads.  |
| `android/app/google-services.json`                  | Android Firebase config consumed by the Gradle plugin.        |
| `ios/Runner/GoogleService-Info.plist`               | iOS Firebase config bundled into the Runner target.           |

> **Do not commit** the JSON / plist — they hold your API keys. Add them to
> `.gitignore` if not already, and feed them into CI from secret storage at
> build time.

## 4. Enable the Android Gradle plugin

In `android/app/build.gradle.kts`, uncomment the line you'll find marked
TODO:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // <-- uncomment this
}
```

The plugin is already declared (but not applied) in
`android/settings.gradle.kts`, so no version bump is needed.

## 5. iOS: push capability + APNs key

`flutterfire configure` does not modify the Xcode project. You have to:

1. In Xcode, open the regenerated `Runner.xcworkspace`.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** → add **Push Notifications**. This appends
   `aps-environment` to `Runner.entitlements`.
4. Click **+ Capability** → add **Background Modes**. Tick
   **Remote notifications** (the matching key is already in `Info.plist`).
5. In the Apple Developer portal:
   - Create an **APNs Auth Key** (one per team is fine; reusable across apps).
   - Download the `.p8` file.
6. Back in the Firebase console: **Project settings → Cloud Messaging**.
   Upload the `.p8`, plus the Key ID and your Team ID. This is what lets
   Firebase mint pushes that APNs accepts.

## 6. Smoke-test from a real device

Simulator / web do **not** receive FCM. You need a physical device.

```bash
flutter run --release --dart-define=AUTH_BASE_URL=https://api.igobi.app
```

After sign-in, the app calls `PushService.requestPermission()` (when wired
into the auth-success flow) and `PushService.getAndStoreToken()`. Copy the
printed token from the device logs:

```bash
flutter logs | grep "FCM token"   # if you add a print statement
```

Send a test push with the Firebase CLI:

```bash
firebase messaging:send \
  --token=<the-token> \
  --notification.title="Hello from IGOBI" \
  --notification.body="Push works."
```

You should see the banner appear with the app backgrounded.

## 7. Token registration with notification-service

Done — `lib/core/push/device_registration.dart` registers the token on the
first `AuthSignedIn` transition and re-registers on every `onTokenRefresh`.
You don't need to do anything in the mobile app once Firebase is configured.

The server side is `notification-service` (port 3005). It accepts the token
at `POST /api/v1/devices` and stores it indexed by userId so other services
can address pushes by user.

## 8. Google Sign-In (uses the same Firebase project)

The same Firebase project drives **Google Sign-In** on the auth screen.
Once `flutterfire configure` has run, the client side already has what it
needs — but you must enable the provider in the Firebase console and add
an Android SHA-1 fingerprint, otherwise Google's API rejects sign-in
attempts with `DEVELOPER_ERROR` / `ApiException: 10`.

### Console steps

1. Firebase console → **Authentication → Sign-in method** → enable
   **Google**. Pick a project-support email when prompted.
2. Firebase console → **Project Settings → General** → scroll to your
   Android app → **Add fingerprint** → paste the SHA-1 of your upload
   keystore:
   ```bash
   keytool -list -v -keystore ~/igobi-upload.jks -alias upload | grep SHA1
   ```
   Add the **debug** keystore's SHA-1 too so sign-in works in debug
   builds. The debug keystore lives at `~/.android/debug.keystore`
   (password `android`).
3. Re-download `google-services.json` (it now contains an `oauth_client`
   entry for the OAuth Web client Firebase created behind the scenes) and
   replace the file at `apps/igobi-mobile/android/app/google-services.json`.

### iOS

`flutterfire configure` already registered the iOS bundle id with the
Firebase project. One more step in Xcode:

1. Open `apps/igobi-mobile/ios/Runner.xcworkspace`.
2. Select the **Runner** target → **Info** tab → expand **URL Types** → **+**.
3. Paste the `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist`
   into the **URL Schemes** field. (Required by `google_sign_in` to
   handle the OAuth callback.)
4. Save.

### Server-side

`auth-service` verifies Google ID tokens with **the same** service-account
JSON used by `notification-service` for FCM (next section). Set
`FIREBASE_SERVICE_ACCOUNT_JSON` in `auth-service`'s `.env` to the same
value. Without it, `POST /api/v1/auth/oauth/google` returns
`AUTH_OAUTH_DISABLED` and the mobile button shows a friendly error.

### Smoke test

After all of the above, the "Continue with Google" button on the sign-in
screen should open Google's account picker. Pick an account → app
navigates to `/home` → a new user row exists in Mongo with
`passwordHash: null` and an `OAuthAccount` row linking it to the Google UID.

If you see `PlatformException(sign_in_failed, ApiException: 10, …)` on
Android, the SHA-1 fingerprint isn't registered in Firebase (or you
downloaded `google-services.json` before adding it).

## 9. Server-side: Firebase Admin credentials

Both `notification-service` (for FCM dispatch) and `auth-service` (for
Google ID-token verification) need a **service account** to talk to
Firebase as an admin. This is separate from the client config you
generated in step 3.

1. Firebase console → **Project Settings → Service accounts** →
   **Generate new private key**. Download the JSON.
2. Pick one of:
   - **Inline JSON (recommended for VPS):** copy the entire JSON onto one
     line and set `FIREBASE_SERVICE_ACCOUNT_JSON=…` in
     `services/notification-service/.env`. Easier to manage with secret
     stores; no file to mount.
   - **File path (Google convention):** drop the JSON onto the host,
     `chmod 600`, set `GOOGLE_APPLICATION_CREDENTIALS=/path/to/file.json`.
3. Restart notification-service. The log should read
   `Firebase Admin initialised`. If you see `Firebase Admin disabled —
   set FIREBASE_SERVICE_ACCOUNT_JSON or GOOGLE_APPLICATION_CREDENTIALS`,
   double-check the env var spelling.
4. Smoke test via the dispatch endpoint — see
   `services/notification-service/README.md` for the curl commands.

> Keep the service-account JSON out of git. It's a credential. If it leaks,
> rotate immediately in Firebase console.

---

## Why the build still succeeds without this

- `PushService.init()` catches the `Firebase.initializeApp` failure that
  fires when no config file is present, logs it, and returns. The app boots
  normally and `isAvailable` stays false.
- The Android Gradle plugin is **not applied** until you uncomment it; an
  unapplied plugin doesn't look for `google-services.json`.
- The iOS project doesn't gate the build on `GoogleService-Info.plist` —
  Firebase's iOS SDK only checks at runtime.

This lets the rest of the team ship code while one person sets up the
Firebase project.
