import 'order_model.dart';

class DeliveryScheduleModel {
  const DeliveryScheduleModel({
    required this.date,
    required this.code,
    required this.status,
    required this.ordersCount,
    required this.totalCod,
    required this.orders,
    this.id,
    this.notes,
    this.confirmedAt,
  });

  final String date;
  final int? id;
  final String code;
  final String status;
  final int ordersCount;
  final double totalCod;
  final String? notes;
  final String? confirmedAt;
  final List<OrderModel> orders;

  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isWaiting => status == 'waiting' || status == 'changed';
  bool get hasOrders => orders.isNotEmpty;

  factory DeliveryScheduleModel.fromJson(Map<String, dynamic> json) {
    final ordersJson = json['orders'];
    final orders = ordersJson is List
        ? ordersJson
              .whereType<Map<String, dynamic>>()
              .map(OrderModel.fromJson)
              .toList()
        : <OrderModel>[];

    return DeliveryScheduleModel(
      date: (json['date'] ?? '').toString(),
      id: json['id'] == null ? null : int.tryParse('${json['id']}'),
      code: (json['code'] ?? '').toString(),
      status: (json['status'] ?? 'none').toString(),
      ordersCount:
          int.tryParse('${json['orders_count'] ?? orders.length}') ??
          orders.length,
      totalCod: double.tryParse('${json['total_cod'] ?? 0}') ?? 0,
      notes: json['notes']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
      orders: orders,
    );
  }

  static const empty = DeliveryScheduleModel(
    date: '',
    code: '',
    status: 'none',
    ordersCount: 0,
    totalCod: 0,
    orders: [],
  );
}
