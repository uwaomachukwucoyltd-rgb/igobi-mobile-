import '../../../core/api/api_client.dart';

class InboxApi {
  InboxApi(this._client);

  final ApiClient _client;

  Future<InboxPage> list({int limit = 50}) async {
    final json = await _client.getJson('/api/v1/notifications?limit=$limit');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return InboxPage(
      items: data.map(InboxNotification.fromMap).toList(growable: false),
      total: (meta['total'] as int?) ?? data.length,
      unread: (meta['unread'] as int?) ?? 0,
    );
  }

  Future<void> markRead(String id) async {
    await _client.postJson('/api/v1/notifications/$id/read', const {});
  }

  Future<void> markAllRead() async {
    await _client.postJson('/api/v1/notifications/read-all', const {});
  }
}

class InboxPage {
  const InboxPage({
    required this.items,
    required this.total,
    required this.unread,
  });
  final List<InboxNotification> items;
  final int total;
  final int unread;
}

class InboxNotification {
  InboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.status,
    required this.createdAt,
    required this.readAt,
  });

  factory InboxNotification.fromMap(Map<String, dynamic> data) {
    return InboxNotification(
      id: data['id'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      data: (data['data'] as Map<String, dynamic>?) ?? const {},
      status: data['status'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      readAt: data['readAt'] != null ? DateTime.parse(data['readAt'] as String) : null,
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}
