import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/push/device_registration.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/state/auth_controller.dart';

class IgobiApp extends ConsumerWidget {
  const IgobiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Auth-driven device registration. Whenever the user transitions to
    // signed-in, register the device with notification-service; on sign-out,
    // reset the in-memory flag so the next sign-in (possibly with a
    // different account) re-registers cleanly.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthSignedIn && previous is! AuthSignedIn) {
        ref.read(deviceRegistrationProvider).registerOnSignIn();
      } else if (next is AuthSignedOut && previous is AuthSignedIn) {
        ref.read(deviceRegistrationProvider).reset();
      }
    });

    return MaterialApp.router(
      title: 'iGobi mobile App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Forced light until the dark theme is properly designed. Dark-mode
      // bleed-through was causing input text + brand labels to be invisible
      // (white text on white fill, charcoal text on dark background).
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
