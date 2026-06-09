import 'customer_model.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.code,
    required this.status,
    required this.total,
    required this.customer,
    required this.updatedAt,
    this.shipperId,
    this.collectedAmount,
    this.returnReason,
    this.note,
    this.deliveryTime,
    this.dailySequence,
    this.itemCount,
    this.items = const [],
    this.deliverySchedule,
  });

  final int id;
  final String code;
  final String status;
  final double total;
  final CustomerModel customer;
  final String updatedAt;
  final int? shipperId;
  final double? collectedAmount;
  final String? returnReason;
  final String? note;
  final String? deliveryTime;
  final int? dailySequence;
  final int? itemCount;
  final List<OrderItemModel> items;
  final OrderDeliverySchedule? deliverySchedule;

  bool get isReadyToShip => status == 'packed_waiting_pickup';
  bool get isDelivering => status == 'delivering';
  bool get isDelivered => status == 'delivered';
  bool get isReturning => status == 'returning';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      code: (json['code'] ?? '#${json['id'] ?? ''}').toString(),
      status: (json['status'] ?? '').toString(),
      total: double.tryParse('${json['total'] ?? 0}') ?? 0,
      customer: CustomerModel.fromJson(
        json['customer'] is Map<String, dynamic>
            ? json['customer'] as Map<String, dynamic>
            : null,
      ),
      updatedAt: (json['updated_at'] ?? json['created_at'] ?? '').toString(),
      shipperId: json['shipper_id'] == null
          ? null
          : int.tryParse('${json['shipper_id']}'),
      collectedAmount: json['collected_amount'] == null
          ? null
          : double.tryParse('${json['collected_amount']}'),
      returnReason: json['return_reason']?.toString(),
      note: json['note']?.toString(),
      deliveryTime: json['delivery_time']?.toString(),
      dailySequence: json['daily_sequence'] == null
          ? null
          : int.tryParse('${json['daily_sequence']}'),
      itemCount: _itemCount(json['items']),
      items: _items(json['items']),
      deliverySchedule: json['delivery_schedule'] is Map<String, dynamic>
          ? OrderDeliverySchedule.fromJson(
              json['delivery_schedule'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static int? _itemCount(Object? items) {
    if (items is! List) return null;

    return items.fold<int>(0, (total, item) {
      if (item is! Map) return total;
      return total + (double.tryParse('${item['quantity'] ?? 0}') ?? 0).round();
    });
  }

  static List<OrderItemModel> _items(Object? items) {
    if (items is! List) return const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(OrderItemModel.fromJson)
        .toList();
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.productName,
    required this.variantName,
    required this.size,
    required this.quantity,
  });

  final String productName;
  final String variantName;
  final String size;
  final double quantity;

  String get displayName {
    if (productName.isNotEmpty && variantName.isNotEmpty) {
      return '$productName - $variantName';
    }
    return variantName.isNotEmpty ? variantName : productName;
  }

  String get quantityLabel {
    final rounded = quantity.roundToDouble();
    if ((quantity - rounded).abs() < 0.001) return rounded.toInt().toString();
    return quantity.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final variant = json['variant'] is Map<String, dynamic>
        ? json['variant'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return OrderItemModel(
      productName: (product['name'] ?? '').toString(),
      variantName: (variant['name'] ?? '').toString(),
      size: (variant['size'] ?? json['size'] ?? '').toString(),
      quantity: double.tryParse('${json['quantity'] ?? 0}') ?? 0,
    );
  }
}

class OrderDeliverySchedule {
  const OrderDeliverySchedule({
    required this.id,
    required this.code,
    required this.status,
    this.confirmedAt,
  });

  final int id;
  final String code;
  final String status;
  final String? confirmedAt;

  factory OrderDeliverySchedule.fromJson(Map<String, dynamic> json) {
    return OrderDeliverySchedule(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      code: (json['code'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      confirmedAt: json['confirmed_at']?.toString(),
    );
  }
}
