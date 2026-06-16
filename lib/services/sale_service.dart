import 'package:dio/dio.dart';

import 'api_service.dart';

class SaleService {
  SaleService(this._api);

  final ApiService _api;

  Future<Map<String, dynamic>> dashboard() async {
    return _data(await _api.getJson('/sale/dashboard'));
  }

  Future<void> confirmWarehouseAdjustment(int orderId) async {
    await _api.postJson('/sale/order-adjustments/$orderId/confirm');
  }

  Future<void> rejectWarehouseAdjustment(int orderId, String reason) async {
    await _api.postJson(
      '/sale/order-adjustments/$orderId/reject',
      data: {'reject_reason': reason},
    );
  }

  Future<SaleListData> customers({
    String search = '',
    String tab = 'all',
    String sortBy = 'id',
    String sortDir = 'desc',
  }) async {
    return _list(
      '/sale/customers',
      query: {
        'search': search,
        'tab': tab,
        'sort_by': sortBy,
        'sort_dir': sortDir,
        'per_page': 50,
      },
    );
  }

  Future<Map<String, dynamic>> customer(int id) async {
    return _data(await _api.getJson('/sale/customers/$id'));
  }

  Future<Map<String, dynamic>> customerOptions({int? provinceId}) async {
    return _data(
      await _api.getJson(
        '/sale/customers/form-options',
        query: {'province_id': ?provinceId},
      ),
    );
  }

  Future<Map<String, dynamic>> checkCustomerDuplicate({
    required String name,
    required String phone,
    required String email,
  }) async {
    final response = await _api.getJson(
      '/sale/customers/check-duplicate',
      query: {'name': name, 'phone': phone, 'email': email},
    );
    return response['data'] is Map<String, dynamic>
        ? _data(response)
        : response;
  }

  Future<int?> saveCustomer(Map<String, dynamic> data, {int? id}) async {
    final response = id == null
        ? await _api.postJson('/sale/customers', data: data)
        : await _api.putJson('/sale/customers/$id', data: data);
    return int.tryParse('${_data(response)['customer_id'] ?? ''}');
  }

  Future<void> deleteCustomer(int id) async {
    await _api.deleteJson('/sale/customers/$id');
  }

  Future<void> restoreCustomer(int id) async {
    await _api.postJson('/sale/customers/$id/restore');
  }

  Future<SaleListData> products({String search = ''}) {
    return _list('/sale/products', query: {'search': search});
  }

  Future<int?> createOrder(int customerId, Map<String, dynamic> data) async {
    final response = await _api.postJson(
      '/sale/customers/$customerId/orders',
      data: data,
    );
    return int.tryParse('${_data(response)['order_id'] ?? ''}');
  }

  Future<SaleListData> orders({
    String search = '',
    String status = '',
    String paymentStatus = '',
    bool trash = false,
    String sortBy = 'created_at',
    String sortDir = 'desc',
  }) {
    return _list(
      '/sale/orders',
      query: {
        'search': search,
        'status': status,
        'payment_status': paymentStatus,
        'trash': trash ? 1 : 0,
        'sort_by': sortBy,
        'sort_dir': sortDir,
        'per_page': 50,
      },
    );
  }

  Future<Map<String, dynamic>> order(int id) async {
    return _data(await _api.getJson('/sale/orders/$id'));
  }

  Future<SaleListData> draftOrders() {
    return _list('/sale/draft-orders', query: {'per_page': 50});
  }

  Future<void> parseDraftOrders(String text) async {
    await _api.postJson('/sale/draft-orders/parse', data: {'text': text});
  }

  Future<void> confirmDraftOrder(int id) async {
    await _api.postJson('/sale/draft-orders/$id/confirm');
  }

  Future<void> copyDraftOrder(int id) async {
    await _api.postJson('/sale/draft-orders/$id/copy');
  }

  Future<void> copyConfirmDraftOrder(int id) async {
    await _api.postJson('/sale/draft-orders/$id/copy-confirm');
  }

  Future<void> deleteDraftOrder(int id) async {
    await _api.deleteJson('/sale/draft-orders/$id');
  }

  Future<void> updateOrder(int id, Map<String, dynamic> data) async {
    await _api.putJson('/sale/orders/$id', data: data);
  }

  Future<void> updateOrderCustomerFeedback(
    int id, {
    required String status,
    required String note,
    String saleReview = '',
    bool reset = false,
    List<String> imagePaths = const [],
  }) async {
    if (imagePaths.isEmpty) {
      await _api.postJson(
        '/sale/orders/$id/customer-feedback',
        data: {
          'customer_feedback_status': status,
          'customer_feedback_note': note,
          'customer_feedback_sale_review': saleReview,
          'reset_feedback': reset ? 1 : 0,
        },
      );
      return;
    }

    await _api.postForm(
      '/sale/orders/$id/customer-feedback',
      FormData.fromMap({
        'customer_feedback_status': status,
        'customer_feedback_note': note,
        'customer_feedback_sale_review': saleReview,
        'reset_feedback': reset ? 1 : 0,
        'customer_feedback_images[]': [
          for (final path in imagePaths) await MultipartFile.fromFile(path),
        ],
      }),
    );
  }

  Future<int?> copyOrder(int id) async {
    final response = await _api.postJson('/sale/orders/$id/copy');
    return int.tryParse('${_data(response)['order_id'] ?? ''}');
  }

  Future<void> confirmCopy(int id) async {
    await _api.postJson('/sale/orders/$id/confirm-copy');
  }

  Future<void> cancelOrder(int id, String reason) async {
    await _api.postJson(
      '/sale/orders/$id/cancel',
      data: {'cancel_reason': reason},
    );
  }

  Future<void> trashOrder(int id) async {
    await _api.postJson('/sale/orders/$id/trash');
  }

  Future<SaleListData> approvals(
    String scope, {
    String search = '',
    String status = '',
  }) {
    return _list(
      '/sale/approvals/$scope',
      query: {'search': search, 'status': status},
    );
  }

  Future<void> approve(int id, String note) async {
    await _api.postJson('/sale/approvals/$id/approve', data: {'note': note});
  }

  Future<Map<String, dynamic>> approveAll(
    String scope,
    String note, {
    String search = '',
    String status = '',
  }) async {
    return _data(
      await _api.postJson(
        '/sale/approvals/$scope/approve-all',
        data: {'note': note},
        query: {'search': search, 'status': status},
      ),
    );
  }

  Future<void> reject(int id, String note) async {
    await _api.postJson('/sale/approvals/$id/reject', data: {'note': note});
  }

  Future<SaleListData> _list(String path, {Map<String, dynamic>? query}) async {
    final response = await _api.getJson(path, query: query);
    return SaleListData.fromResponse(response);
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}

class SaleListData {
  const SaleListData({required this.items, required this.meta});

  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> meta;

  factory SaleListData.fromResponse(Map<String, dynamic> response) {
    return SaleListData(
      items: (response['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      meta: response['meta'] is Map<String, dynamic>
          ? response['meta'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }
}
