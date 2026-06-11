import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_refresh.dart';
import '../../core/config/api_config.dart';
import 'state/auth_controller.dart';

/// Wraps auth-service /users/me/religious-org. Used by sign-up + profile to
/// link the user to a religious organisation (curated id) or a free-text
/// name they typed under "Other". Donation flow is informational on the
/// receipt — even an Other-typed name gets recorded for impact reporting.
class ReligiousOrgService {
  ReligiousOrgService(this._client);
  final ApiClient _client;

  Future<void> setForCurrentUser({
    String? orgSlugOrId,
    String? freeTextName,
  }) async {
    final body = <String, dynamic>{};
    if (orgSlugOrId != null && orgSlugOrId.isNotEmpty) {
      body['orgId'] = orgSlugOrId;
    } else if (freeTextName != null && freeTextName.trim().isNotEmpty) {
      body['orgName'] = freeTextName.trim();
    } else {
      // Both null = clear.
      body['orgId'] = null;
      body['orgName'] = null;
    }
    await _client.dio.post<dynamic>(
      '/api/v1/users/me/religious-org',
      data: body,
    );
  }
}

final religiousOrgServiceProvider = Provider<ReligiousOrgService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ReligiousOrgService(
    ApiClient(
      baseUrl: ApiConfig.authBaseUrl,
      tokenStorage: storage,
      onUnauthorized: () => refreshAccessToken(storage),
    ),
  );
});
