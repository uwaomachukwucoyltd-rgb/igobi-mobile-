import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';
import '../data/inbox_api.dart';

final inboxApiProvider = Provider<InboxApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.notificationBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return InboxApi(client);
});

final inboxProvider = FutureProvider<InboxPage>((ref) async {
  return ref.watch(inboxApiProvider).list();
});
