import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_refresh.dart';
import '../../../core/config/api_config.dart';
import '../../auth/state/auth_controller.dart';

/// One turn of chat history sent to the backend.
class ChatTurn {
  const ChatTurn({required this.role, required this.content});
  final String role; // 'user' | 'assistant'
  final String content;
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Result of a concierge/vanguard chat call.
class ChatResult {
  const ChatResult({
    required this.reply,
    required this.model,
    required this.configured,
    required this.suggestions,
  });
  final String reply;
  final String model; // 'flash' | 'pro'
  final bool configured;
  final List<String> suggestions;
}

/// Data layer for the Claude-backed Concierge + Vanguard chats. Talks to
/// vendor-service POST /api/v1/concierge/chat with the authed [ApiClient].
class ConciergeApi {
  ConciergeApi(this._client);
  final ApiClient _client;

  Future<ChatResult> chat({
    required String message,
    required List<ChatTurn> history,
    required String persona, // 'concierge' | 'vanguard'
  }) async {
    final json = await _client.postJson('/api/v1/concierge/chat', {
      'message': message,
      'history': history.map((t) => t.toJson()).toList(),
      'persona': persona,
    });
    final data = json['data'] as Map<String, dynamic>;
    return ChatResult(
      reply: data['reply'] as String? ?? '',
      model: data['model'] as String? ?? 'pro',
      configured: data['configured'] as bool? ?? false,
      suggestions:
          (data['suggestions'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}

final conciergeApiProvider = Provider<ConciergeApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    baseUrl: ApiConfig.vendorBaseUrl,
    tokenStorage: storage,
    onUnauthorized: () => refreshAccessToken(storage),
  );
  return ConciergeApi(client);
});
