import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for telemetry. Read once at boot and kept in memory so the
/// Sentry beforeSend hook (which is synchronous) can check the latest state.
///
/// Defaults: crash reporting ON, analytics OFF.
/// Crash reporting is treated as service-essential (it's how we ship reliable
/// software) and is disclosed in the privacy policy with an in-app toggle —
/// this matches both Apple's App Privacy guidance and Google's Data Safety
/// form. Analytics defaults OFF until we ship a real analytics SDK and a
/// proper consent prompt.
class ConsentService {
  ConsentService._();

  static const _crashReportingKey = 'consent.crash_reporting';
  static const _analyticsKey = 'consent.analytics';

  static bool _crashReportingEnabled = true;
  static bool _analyticsEnabled = false;
  static bool _loaded = false;

  /// Synchronously readable. Returns the cached value loaded by [load]; if
  /// [load] hasn't completed yet, returns the default (true). Sentry's
  /// beforeSend hook calls this on every event so it must not block.
  static bool get crashReportingEnabled => _crashReportingEnabled;
  static bool get analyticsEnabled => _analyticsEnabled;
  static bool get isLoaded => _loaded;

  /// Hydrate the in-memory flags from shared_preferences. Call once from main()
  /// before SentryFlutter.init so the first events honour the user's choice.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _crashReportingEnabled = prefs.getBool(_crashReportingKey) ?? true;
    _analyticsEnabled = prefs.getBool(_analyticsKey) ?? false;
    _loaded = true;
  }

  static Future<void> setCrashReporting(bool value) async {
    _crashReportingEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crashReportingKey, value);
  }

  static Future<void> setAnalytics(bool value) async {
    _analyticsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsKey, value);
  }
}

class ConsentState {
  const ConsentState({
    required this.crashReporting,
    required this.analytics,
  });

  final bool crashReporting;
  final bool analytics;

  ConsentState copyWith({bool? crashReporting, bool? analytics}) =>
      ConsentState(
        crashReporting: crashReporting ?? this.crashReporting,
        analytics: analytics ?? this.analytics,
      );
}

class ConsentController extends StateNotifier<ConsentState> {
  ConsentController()
      : super(ConsentState(
          crashReporting: ConsentService.crashReportingEnabled,
          analytics: ConsentService.analyticsEnabled,
        ));

  Future<void> setCrashReporting(bool value) async {
    await ConsentService.setCrashReporting(value);
    state = state.copyWith(crashReporting: value);
  }

  Future<void> setAnalytics(bool value) async {
    await ConsentService.setAnalytics(value);
    state = state.copyWith(analytics: value);
  }
}

final consentControllerProvider =
    StateNotifierProvider<ConsentController, ConsentState>((ref) {
  return ConsentController();
});
