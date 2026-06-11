import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/consent/consent_service.dart';
import 'core/push/push_service.dart';

// Compile-time injected. Build with:
//   flutter build appbundle --release --dart-define=SENTRY_DSN=https://...
// When empty, Sentry stays disabled — useful for local dev so we don't ship
// a debug DSN that pollutes the project.
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Hydrate the user's telemetry preferences BEFORE Sentry initialises so the
  // beforeSend hook sees the right value on the first event of the session.
  await ConsentService.load();

  // Best-effort. PushService.init fails soft if Firebase isn't configured —
  // the app still boots, push is just disabled. See FCM_SETUP.md.
  await PushService.init();

  const app = ProviderScope(child: IgobiApp());

  if (_sentryDsn.isEmpty) {
    runApp(app);
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      // Strip request bodies / form data — payment payloads can contain
      // amounts and emails. Sentry's PII scrubbing is on by default but we
      // belt-and-brace here for the buyer surface.
      options.sendDefaultPii = false;
      // Honour the user's in-app toggle. Returning null drops the event.
      options.beforeSend = (event, hint) {
        return ConsentService.crashReportingEnabled ? event : null;
      };
    },
    appRunner: () => runApp(app),
  );
}
