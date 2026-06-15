import '../models/dashboard_stats.dart';
import '../models/delivery_schedule_model.dart';
import '../models/order_model.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';

class OrderService {
  OrderService(this._api);

  final ApiService _api;

  Future<DashboardStats> dashboard() async {
    final response = await _api.getJson('/shipper/dashboard');
    return DashboardStats.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<OrderModel>> availableOrders({int page = 1}) async {
    return _fetchAllOrders('/shipper/available-orders');
  }

  Future<List<OrderModel>> acceptedOrders({int page = 1}) async {
    return _fetchAllOrders('/shipper/accepted-orders');
  }

  Future<DeliveryScheduleModel> deliverySchedule({String? date}) async {
    final response = await _api.getJson(
      '/shipper/delivery-schedules',
      query: {if (date != null && date.isNotEmpty) 'date': date},
    );
    return DeliveryScheduleModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<void> confirmDeliverySchedule({
    required List<int> orderIds,
    String? date,
  }) async {
    await _api.postJson(
      '/shipper/delivery-schedules/confirm',
      data: {
        'order_ids': orderIds,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
  }

  Future<void> rejectDeliverySchedule({
    required List<int> orderIds,
    required String reason,
    String? date,
  }) async {
    await _api.postJson(
      '/shipper/delivery-schedules/reject',
      data: {
        'order_ids': orderIds,
        'reason': reason,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
  }

  Future<List<OrderModel>> myOrders({int page = 1}) async {
    return _fetchAllOrders('/shipper/my-orders');
  }

  Future<List<OrderModel>> history({int page = 1}) async {
    return _fetchAllOrders('/shipper/history');
  }

  Future<Map<String, dynamic>> customers({
    required String date,
    required String sort,
    required String direction,
  }) async {
    final response = await _api.getJson(
      '/shipper/customers',
      query: {'date': date, 'sort': sort, 'direction': direction},
    );
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<Map<String, dynamic>> deliveryStatistics({
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _api.getJson(
      '/shipper/delivery-statistics',
      query: {'from_date': fromDate, 'to_date': toDate},
    );
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<void> acceptOrder(int orderId) async {
    await _api.postJson('/shipper/orders/$orderId/accept');
  }

  Future<List<WarehouseOption>> warehouses() async {
    final response = await _api.getJson('/shipper/warehouses');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(WarehouseOption.fromJson)
        .toList();
  }

  Future<void> returnOrder({
    required int orderId,
    required int warehouseId,
    required String reason,
    String note = '',
  }) async {
    await _api.postJson(
      '/shipper/orders/$orderId/return',
      data: {
        'return_warehouse_id': warehouseId,
        'return_reason': reason,
        'return_note': note,
      },
    );
  }

  Future<OrderModel> updateStatus({
    required int orderId,
    required String status,
    double? collectedAmount,
    String? returnReason,
    String? shipperNote,
  }) async {
    await _api.postJson(
      '/shipper/orders/$orderId/status',
      data: {
        'status': status,
        'collected_amount': ?collectedAmount,
        'return_reason': ?returnReason,
        'shipper_note': ?shipperNote,
      },
    );
    final current = await myOrders();
    return current.firstWhere(
      (order) => order.id == orderId,
      orElse: () => throw StateError('Order not found'),
    );
  }

  Future<void> completeDelivery({
    required int orderId,
    double? collectedAmount,
    required bool hasPartialReturn,
    required Map<int, int> deliveredQuantities,
    required Map<int, double> deliveredWeights,
    int? returnWarehouseId,
    String? returnReason,
  }) async {
    await _api.postJson(
      '/shipper/orders/$orderId/complete-delivery',
      data: {
        'collected_amount': ?collectedAmount,
        'has_partial_return': hasPartialReturn ? 1 : 0,
        'delivered_qty': deliveredQuantities.map(
          (key, value) => MapEntry('$key', value),
        ),
        'partial_weight': deliveredWeights.map(
          (key, value) => MapEntry('$key', value),
        ),
        'actual_weight': deliveredWeights.map(
          (key, value) => MapEntry('$key', value),
        ),
        'return_warehouse_id': ?returnWarehouseId,
        'partial_return_reason': ?returnReason,
      },
    );
  }

  Future<void> uploadProof(int orderId, String filePath) async {
    await _api.postForm(
      '/shipper/orders/$orderId/upload-proof',
      FormData.fromMap({'proof_image': await MultipartFile.fromFile(filePath)}),
    );
  }

  List<OrderModel> _ordersFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<List<OrderModel>> _fetchAllOrders(String path) async {
    var page = 1;
    var lastPage = 1;
    final all = <OrderModel>[];

    do {
      final response = await _api.getJson(path, query: {'page': page});
      all.addAll(_ordersFromResponse(response));

      final meta = response['meta'];
      if (meta is Map<String, dynamic>) {
        final parsedLastPage = int.tryParse('${meta['last_page'] ?? 1}') ?? 1;
        lastPage = parsedLastPage < 1 ? 1 : parsedLastPage;
      } else {
        lastPage = 1;
      }

      page++;
    } while (page <= lastPage && page <= 100);

    return all;
  }
}

class WarehouseOption {
  const WarehouseOption({required this.id, required this.name});

  final int id;
  final String name;

  factory WarehouseOption.fromJson(Map<String, dynamic> json) {
    return WarehouseOption(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}
