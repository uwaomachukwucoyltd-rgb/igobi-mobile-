import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../state/job_state.dart';

/// Thin data layer for the artisan hub. Talks to vendor-service under
/// /api/v1/artisan-jobs and /api/v1/artisan-services with the authed
/// [ApiClient].
class ArtisanJobsApi {
  ArtisanJobsApi(this._client);

  final ApiClient _client;

  Future<List<ArtisanJob>> listJobs() async {
    final json = await _client.getJson('/api/v1/artisan-jobs');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(ArtisanJob.fromJson).toList(growable: false);
  }

  Future<ArtisanJob> getJob(String id) async {
    final json = await _client.getJson('/api/v1/artisan-jobs/$id');
    return ArtisanJob.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<DirectService>> listDirectServices() async {
    final json = await _client.getJson('/api/v1/artisan-services');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(DirectService.fromJson).toList(growable: false);
  }

  Future<ArtisanJob> createBroadcast({
    required String serviceTitle,
    required String description,
    required String address,
    required Urgency urgency,
    int? budgetNgn,
  }) async {
    final json = await _client.postJson('/api/v1/artisan-jobs', {
      'serviceTitle': serviceTitle,
      'description': description,
      'address': address,
      'urgency': urgency.name,
      if (budgetNgn != null) 'budgetNgn': budgetNgn,
    });
    return ArtisanJob.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ArtisanJob> bookDirect({
    required String serviceId,
    required String address,
  }) async {
    final json = await _client.postJson('/api/v1/artisan-jobs/direct-book', {
      'serviceId': serviceId,
      'address': address,
    });
    return ArtisanJob.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ArtisanJob> acceptBid(String jobId, String bidId) =>
      _mutate('/api/v1/artisan-jobs/$jobId/accept-bid', jobId, {'bidId': bidId});

  Future<ArtisanJob> advance(String jobId) =>
      _mutate('/api/v1/artisan-jobs/$jobId/advance', jobId, const {});

  Future<ArtisanJob> confirm(String jobId) =>
      _mutate('/api/v1/artisan-jobs/$jobId/confirm', jobId, const {});

  Future<ArtisanJob> cancel(String jobId) =>
      _mutate('/api/v1/artisan-jobs/$jobId/cancel', jobId, const {});

  /// POSTs an action, then returns the updated job. If the endpoint echoes a
  /// full job in `data` we use it directly; otherwise we re-fetch by id.
  Future<ArtisanJob> _mutate(
    String path,
    String jobId,
    Map<String, dynamic> body,
  ) async {
    final json = await _client.postJson(path, body);
    final data = json['data'];
    if (data is Map<String, dynamic> && data['status'] != null) {
      return ArtisanJob.fromJson(data);
    }
    return getJob(jobId);
  }
}

final artisanJobsApiProvider = Provider<ArtisanJobsApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return ArtisanJobsApi(client);
});
