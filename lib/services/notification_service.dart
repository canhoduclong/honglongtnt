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
    required this.products,
    required this.total,
    required this.note,
  });

  final String id;
  final String title;
  final String message;
  final String priority;
  final String routeKey;
  final int? orderId;
  final String readAt;
  final String createdAt;
  final List<AppNotificationProduct> products;
  final double total;
  final String note;

  bool get isUnread => readAt.isEmpty;
  bool get isNewOrder => products.isNotEmpty;

  List<String> get detailLines => [
    if (message.isNotEmpty) message,
    for (final product in products)
      '${product.name}: ${_compact(product.quantity)} × ${_money(product.price)} = ${_money(product.lineTotal)}',
    if (isNewOrder) 'Tổng tiền: ${_money(total)}',
    if (isNewOrder) 'Ghi chú: ${note.isEmpty ? 'Không có' : note}',
  ];

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
      products: (json['products'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AppNotificationProduct.fromJson)
          .toList(),
      total: double.tryParse('${json['total'] ?? 0}') ?? 0,
      note: (json['note'] ?? '').toString(),
    );
  }
}

class AppNotificationProduct {
  const AppNotificationProduct({
    required this.name,
    required this.quantity,
    required this.price,
    required this.lineTotal,
  });

  final String name;
  final double quantity;
  final double price;
  final double lineTotal;

  factory AppNotificationProduct.fromJson(Map<String, dynamic> json) {
    return AppNotificationProduct(
      name: (json['name'] ?? 'Sản phẩm').toString(),
      quantity: double.tryParse('${json['quantity'] ?? 0}') ?? 0,
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      lineTotal: double.tryParse('${json['line_total'] ?? 0}') ?? 0,
    );
  }
}

String _compact(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _money(double value) {
  final digits = value.round().toString();
  return '${digits.replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
}
