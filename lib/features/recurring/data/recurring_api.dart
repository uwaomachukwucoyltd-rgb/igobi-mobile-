import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';

// =====================================================================
// Models
// =====================================================================

class RecurringPlan {
  const RecurringPlan({
    required this.id,
    required this.label,
    required this.cadenceDays,
    this.nextRunAt,
  });

  factory RecurringPlan.fromJson(Map<String, dynamic> json) {
    return RecurringPlan(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      cadenceDays: (json['cadenceDays'] as num?)?.toInt() ?? 0,
      nextRunAt:
          DateTime.tryParse((json['nextRunAt'] ?? '').toString())?.toLocal(),
    );
  }

  final String id;
  final String label;
  final int cadenceDays;
  final DateTime? nextRunAt;
}

class Reminder {
  const Reminder({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.dueAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      kind: (json['kind'] ?? 'CUSTOM').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      dueAt: DateTime.tryParse((json['dueAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }

  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime dueAt;
}

// =====================================================================
// API
// =====================================================================

class RecurringApi {
  RecurringApi(this._client);

  final ApiClient _client;

  // ---- Recurring plans ----

  Future<List<RecurringPlan>> listPlans() async {
    final json = await _client.getJson('/api/v1/recurring/plans');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(RecurringPlan.fromJson).toList(growable: false);
  }

  Future<void> createPlan({
    required String label,
    required int cadenceDays,
  }) async {
    await _client.postJson('/api/v1/recurring/plans', {
      'label': label,
      'payloadJson': <String, dynamic>{},
      'cadenceDays': cadenceDays,
    });
  }

  Future<void> deletePlan(String id) async {
    await _client.deleteVoid('/api/v1/recurring/plans/$id');
  }

  // ---- Reminders ----

  Future<List<Reminder>> listReminders() async {
    final json = await _client.getJson('/api/v1/reminders');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Reminder.fromJson).toList(growable: false);
  }

  Future<void> createReminder({
    required String kind,
    required String title,
    required String body,
    required DateTime dueAt,
  }) async {
    await _client.postJson('/api/v1/reminders', {
      'kind': kind,
      'title': title,
      'body': body,
      'dueAt': dueAt.toUtc().toIso8601String(),
    });
  }

  Future<void> deleteReminder(String id) async {
    await _client.deleteVoid('/api/v1/reminders/$id');
  }
}

// =====================================================================
// Providers
// =====================================================================

final recurringApiProvider = Provider<RecurringApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.paymentBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return RecurringApi(client);
});

final recurringPlansProvider =
    FutureProvider<List<RecurringPlan>>((ref) async {
  final api = ref.watch(recurringApiProvider);
  return api.listPlans();
});

final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final api = ref.watch(recurringApiProvider);
  return api.listReminders();
});
