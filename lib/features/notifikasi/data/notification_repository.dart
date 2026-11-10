import '../../../core/api/api_client.dart';

class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.targetType,
    this.targetId,
    this.createdAt,
    this.readAt,
  });
  final int id;
  final String title, body, category, targetType;
  final int? targetId;
  final DateTime? createdAt, readAt;
  bool get unread => readAt == null;
  factory CustomerNotification.fromJson(Map<String, dynamic> json) =>
      CustomerNotification(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? '',
        targetType: json['target_type'] as String? ?? '',
        targetId: (json['target_id'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      );
}

class NotificationList {
  const NotificationList({
    required this.items,
    this.page = 1,
    this.lastPage = 1,
    this.unread = 0,
    this.latestId = 0,
  });
  final List<CustomerNotification> items;
  final int page, lastPage, unread, latestId;
}

class NotificationRepository {
  NotificationRepository(this._client);
  final ApiClient _client;
  Future<int> unread() async =>
      ((await _client.get('/notifikasi/ringkasan')).asMap['unread_count']
              as num?)
          ?.toInt() ??
      0;
  Future<NotificationList> list({int page = 1}) async {
    final response = await _client.get(
      '/notifikasi',
      queryParameters: {'page': page, 'per_page': 20},
    );
    return NotificationList(
      items: response.asList
          .whereType<Map>()
          .map(
            (e) => CustomerNotification.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      page: (response.meta['page'] as num?)?.toInt() ?? page,
      lastPage: (response.meta['last_page'] as num?)?.toInt() ?? 1,
      unread: (response.meta['unread_count'] as num?)?.toInt() ?? 0,
      latestId: (response.meta['latest_id'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> read(int id) async {
    await _client.post('/notifikasi/$id/baca');
  }

  Future<void> readAll(int throughId) async {
    await _client.post(
      '/notifikasi/baca-semua',
      body: {'through_id': throughId},
    );
  }
}
