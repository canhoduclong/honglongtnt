import 'api_service.dart';

class NotificationService {
  NotificationService(this._api);

  final ApiService _api;

  Future<NotificationCenterData> load() async {
    final response = await _api.getJson('/notifications');
    final data = response['data'];
    return NotificationCenterData.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  Future<void> markAsRead(String id) async {
    await _api.postJson('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _api.postJson('/notifications/read-all');
  }
}

class NotificationCenterData {
  const NotificationCenterData({
    required this.unreadCount,
    required this.items,
  });

  final int unreadCount;
  final List<AppNotificationItem> items;

  factory NotificationCenterData.fromJson(Map<String, dynamic> json) {
    return NotificationCenterData(
      unreadCount: int.tryParse('${json['unread_count'] ?? 0}') ?? 0,
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AppNotificationItem.fromJson)
          .toList(),
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.routeKey,
    required this.orderId,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String priority;
  final String routeKey;
  final int? orderId;
  final String readAt;
  final String createdAt;

  bool get isUnread => readAt.isEmpty;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Thông báo').toString(),
      message: (json['message'] ?? '').toString(),
      priority: (json['priority'] ?? 'info').toString(),
      routeKey: (json['route_key'] ?? '').toString(),
      orderId: json['order_id'] == null
          ? null
          : int.tryParse('${json['order_id']}'),
      readAt: (json['read_at'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
