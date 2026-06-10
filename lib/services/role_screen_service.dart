import 'api_service.dart';

class RoleScreenService {
  RoleScreenService(this._api);

  final ApiService _api;

  Future<RoleScreenData> load(
    String apiPath, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _api.getJson(apiPath, query: query);
    return RoleScreenData.fromResponse(response);
  }

  Future<void> startPacking(int orderId) async {
    await _api.postJson('/warehouse/orders/$orderId/start-packing');
  }

  Future<void> completePacking(int orderId) async {
    await _api.postJson('/warehouse/orders/$orderId/complete-packing');
  }

  Future<void> assignShipper({
    required int orderId,
    required int shipperId,
  }) async {
    await _api.postJson('/shipper/assignments/$orderId/assign/$shipperId');
  }

  Future<void> unassignShipper(int orderId) async {
    await _api.postJson('/shipper/assignments/$orderId/unassign');
  }

  Future<void> createDeliverySchedules() async {
    await _api.postJson('/shipper/assignments/create-schedules');
  }

  Future<void> receiveReturn(int returnId) async {
    await _api.postJson('/warehouse/returns/$returnId/receive');
  }

  Future<void> updateOrderItemWeight({
    required int orderId,
    required int itemId,
    required double actualWeight,
  }) async {
    await _api.postJson(
      '/warehouse/orders/$orderId/logistics',
      data: {'item_id': itemId, 'item_actual_weight': actualWeight},
    );
  }

  Future<void> updateOrderLogistics({
    required int orderId,
    required bool chargeShippingFee,
    required double shippingFee,
    required bool chargeFoamBoxFee,
    required double foamBoxPrice,
  }) async {
    await _api.postJson(
      '/warehouse/orders/$orderId/logistics',
      data: {
        'charge_shipping_fee': chargeShippingFee,
        'shipping_fee': shippingFee,
        'charge_foam_box_fee': chargeFoamBoxFee,
        'foam_box_price': foamBoxPrice,
      },
    );
  }

  Future<void> updateOrderShippingFee({
    required int orderId,
    required bool chargeShippingFee,
    required double shippingFee,
  }) async {
    await _api.postJson(
      '/warehouse/orders/$orderId/logistics',
      data: {
        'charge_shipping_fee': chargeShippingFee,
        'shipping_fee': shippingFee,
      },
    );
  }

  Future<void> updateOrderFoamBoxFee({
    required int orderId,
    required bool chargeFoamBoxFee,
    required double foamBoxPrice,
  }) async {
    await _api.postJson(
      '/warehouse/orders/$orderId/logistics',
      data: {
        'charge_foam_box_fee': chargeFoamBoxFee,
        'foam_box_price': foamBoxPrice,
      },
    );
  }

  Future<void> requestWarehouseAdjustment({
    required int orderId,
    required String reason,
    required Map<int, int> itemQuantities,
    Map<int, int> newItemQuantities = const {},
  }) async {
    await _api.postJson(
      '/warehouse/orders/$orderId/request-adjustment',
      data: {
        'reason': reason,
        'items': {
          for (final entry in itemQuantities.entries)
            '${entry.key}': {
              'order_item_id': entry.key,
              'quantity': entry.value,
            },
        },
        if (newItemQuantities.isNotEmpty)
          'new_items': [
            for (final entry in newItemQuantities.entries)
              {'product_variant_id': entry.key, 'quantity': entry.value},
          ],
      },
    );
  }

  Future<List<WarehouseProductOption>> warehouseProducts({
    String keyword = '',
  }) async {
    final response = await _api.getJson(
      '/warehouse/products',
      query: {if (keyword.trim().isNotEmpty) 'keyword': keyword.trim()},
    );
    final data = response['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(WarehouseProductOption.fromJson)
        .where((item) => item.id > 0)
        .toList();
  }

  Future<WarehouseDashboardData> warehouseDashboard() async {
    final response = await _api.getJson('/warehouse/dashboard');
    final data = response['data'];
    return WarehouseDashboardData.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }
}

class WarehouseDashboardData {
  const WarehouseDashboardData({
    required this.selectedDate,
    required this.tasks,
    required this.receivingAlert,
    required this.legend,
    required this.workReminders,
    required this.changes,
    required this.inventoryTitle,
    required this.inventoryRows,
    required this.inventoryTotals,
    required this.recentPacked,
  });

  final String selectedDate;
  final List<WarehouseDashboardTask> tasks;
  final WarehouseDashboardAlert receivingAlert;
  final List<WarehouseDashboardLegend> legend;
  final List<WarehouseDashboardReminder> workReminders;
  final List<WarehouseDashboardChange> changes;
  final String inventoryTitle;
  final List<WarehouseInventorySummaryRow> inventoryRows;
  final Map<String, int> inventoryTotals;
  final List<WarehouseRecentPackedOrder> recentPacked;

  factory WarehouseDashboardData.fromJson(Map<String, dynamic> json) {
    final inventory = json['inventory_summary'] is Map<String, dynamic>
        ? json['inventory_summary'] as Map<String, dynamic>
        : <String, dynamic>{};
    final totals = inventory['totals'] is Map
        ? inventory['totals'] as Map
        : const {};

    return WarehouseDashboardData(
      selectedDate: (json['selected_date'] ?? '').toString(),
      tasks: _list(json['tasks']).map(WarehouseDashboardTask.fromJson).toList(),
      receivingAlert: WarehouseDashboardAlert.fromJson(
        json['receiving_alert'] is Map<String, dynamic>
            ? json['receiving_alert'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      legend: _list(
        json['legend'],
      ).map(WarehouseDashboardLegend.fromJson).toList(),
      workReminders: _list(
        json['work_reminders'],
      ).map(WarehouseDashboardReminder.fromJson).toList(),
      changes: _list(
        json['changes'],
      ).map(WarehouseDashboardChange.fromJson).toList(),
      inventoryTitle: (inventory['title'] ?? '').toString(),
      inventoryRows: _list(
        inventory['rows'],
      ).map(WarehouseInventorySummaryRow.fromJson).toList(),
      inventoryTotals: {
        'opening': _int(totals['opening']),
        'import': _int(totals['import']),
        'reserved': _int(totals['reserved']),
        'export': _int(totals['export']),
        'closing': _int(totals['closing']),
      },
      recentPacked: _list(
        json['recent_packed'],
      ).map(WarehouseRecentPackedOrder.fromJson).toList(),
    );
  }
}

class WarehouseDashboardTask {
  const WarehouseDashboardTask({
    required this.sequence,
    required this.label,
    required this.total,
    required this.done,
    required this.percent,
    required this.status,
    required this.color,
    required this.routeKey,
  });

  final int sequence;
  final String label;
  final int total;
  final int done;
  final int percent;
  final String status;
  final String color;
  final String routeKey;

  bool get isDone => status == 'done';

  factory WarehouseDashboardTask.fromJson(Map<String, dynamic> json) {
    return WarehouseDashboardTask(
      sequence: _int(json['sequence']),
      label: (json['label'] ?? '').toString(),
      total: _int(json['total']),
      done: _int(json['done']),
      percent: _int(json['percent']),
      status: (json['status'] ?? '').toString(),
      color: (json['color'] ?? '#b0b0b0').toString(),
      routeKey: (json['route_key'] ?? '').toString(),
    );
  }
}

class WarehouseDashboardAlert {
  const WarehouseDashboardAlert({
    required this.show,
    required this.count,
    required this.message,
    required this.routeKey,
  });

  final bool show;
  final int count;
  final String message;
  final String routeKey;

  factory WarehouseDashboardAlert.fromJson(Map<String, dynamic> json) {
    return WarehouseDashboardAlert(
      show: json['show'] == true,
      count: _int(json['count']),
      message: (json['message'] ?? '').toString(),
      routeKey: (json['route_key'] ?? '').toString(),
    );
  }
}

class WarehouseDashboardLegend {
  const WarehouseDashboardLegend({required this.label, required this.color});

  final String label;
  final String color;

  factory WarehouseDashboardLegend.fromJson(Map<String, dynamic> json) {
    return WarehouseDashboardLegend(
      label: (json['label'] ?? '').toString(),
      color: (json['color'] ?? '#b0b0b0').toString(),
    );
  }
}

class WarehouseDashboardReminder {
  const WarehouseDashboardReminder({
    required this.label,
    required this.percent,
    required this.message,
  });

  final String label;
  final int percent;
  final String message;

  factory WarehouseDashboardReminder.fromJson(Map<String, dynamic> json) {
    return WarehouseDashboardReminder(
      label: (json['label'] ?? '').toString(),
      percent: _int(json['percent']),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class WarehouseDashboardChange {
  const WarehouseDashboardChange({
    required this.icon,
    required this.label,
    required this.badge,
    required this.color,
    required this.badgeColor,
  });

  final String icon;
  final String label;
  final String badge;
  final String color;
  final String badgeColor;

  factory WarehouseDashboardChange.fromJson(Map<String, dynamic> json) {
    return WarehouseDashboardChange(
      icon: (json['icon'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      badge: (json['badge'] ?? '').toString(),
      color: (json['color'] ?? '#64748b').toString(),
      badgeColor: (json['badge_color'] ?? '#64748b').toString(),
    );
  }
}

class WarehouseInventorySummaryRow {
  const WarehouseInventorySummaryRow({
    required this.productId,
    required this.name,
    required this.unit,
    required this.opening,
    required this.imported,
    required this.reserved,
    required this.exported,
    required this.closing,
    required this.variants,
  });

  final int productId;
  final String name;
  final String unit;
  final int opening;
  final int imported;
  final int reserved;
  final int exported;
  final int closing;
  final List<WarehouseInventorySummaryVariant> variants;

  factory WarehouseInventorySummaryRow.fromJson(Map<String, dynamic> json) {
    return WarehouseInventorySummaryRow(
      productId: _int(json['product_id']),
      name: (json['name'] ?? '').toString(),
      unit: (json['unit'] ?? '—').toString(),
      opening: _int(json['opening']),
      imported: _int(json['import']),
      reserved: _int(json['reserved']),
      exported: _int(json['export']),
      closing: _int(json['closing']),
      variants: _list(
        json['variants'],
      ).map(WarehouseInventorySummaryVariant.fromJson).toList(),
    );
  }
}

class WarehouseInventorySummaryVariant {
  const WarehouseInventorySummaryVariant({
    required this.name,
    required this.unit,
    required this.opening,
    required this.imported,
    required this.reserved,
    required this.exported,
    required this.closing,
  });

  final String name;
  final String unit;
  final int opening;
  final int imported;
  final int reserved;
  final int exported;
  final int closing;

  factory WarehouseInventorySummaryVariant.fromJson(Map<String, dynamic> json) {
    return WarehouseInventorySummaryVariant(
      name: (json['name'] ?? '').toString(),
      unit: (json['unit'] ?? '—').toString(),
      opening: _int(json['opening']),
      imported: _int(json['import']),
      reserved: _int(json['reserved']),
      exported: _int(json['export']),
      closing: _int(json['closing']),
    );
  }
}

class WarehouseRecentPackedOrder {
  const WarehouseRecentPackedOrder({
    required this.sequence,
    required this.code,
    required this.customerName,
    required this.total,
    required this.updatedTime,
  });

  final int sequence;
  final String code;
  final String customerName;
  final double total;
  final String updatedTime;

  factory WarehouseRecentPackedOrder.fromJson(Map<String, dynamic> json) {
    return WarehouseRecentPackedOrder(
      sequence: _int(json['sequence']),
      code: (json['code'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '—').toString(),
      total: double.tryParse('${json['total'] ?? 0}') ?? 0,
      updatedTime: (json['updated_time'] ?? '').toString(),
    );
  }
}

List<Map<String, dynamic>> _list(Object? raw) {
  return (raw as List? ?? const []).whereType<Map<String, dynamic>>().toList();
}

int _int(Object? raw) => int.tryParse('${raw ?? 0}') ?? 0;

class WarehouseProductOption {
  const WarehouseProductOption({
    required this.id,
    required this.name,
    required this.sku,
    required this.productName,
  });

  final int id;
  final String name;
  final String sku;
  final String productName;

  String get label {
    final parts = [
      if (productName.isNotEmpty) productName,
      if (name.isNotEmpty) name,
      if (sku.isNotEmpty) sku,
    ];
    return parts.isEmpty ? '#$id' : parts.join(' - ');
  }

  factory WarehouseProductOption.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map ? json['product'] as Map : const {};
    return WarehouseProductOption(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      productName: (product['name'] ?? '').toString(),
    );
  }
}

class RoleScreenData {
  const RoleScreenData({required this.cards, required this.items});

  final List<RoleCardData> cards;
  final List<RoleListItemData> items;

  factory RoleScreenData.fromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return RoleScreenData(
        cards: const [],
        items: data.map(RoleListItemData.fromAny).toList(),
      );
    }

    if (data is Map<String, dynamic>) {
      final cards = (data['cards'] as List? ?? const [])
          .map(RoleCardData.fromAny)
          .toList();
      final items = (data['items'] as List? ?? const [])
          .map(RoleListItemData.fromAny)
          .toList();
      if (items.isEmpty && data['orders'] is List) {
        return RoleScreenData(
          cards: cards,
          items: (data['orders'] as List)
              .map(RoleListItemData.fromAny)
              .toList(),
        );
      }
      if (cards.isEmpty && items.isEmpty) {
        final metricCards = data.entries
            .where((entry) => entry.value is num)
            .map(
              (entry) => RoleCardData(
                label: _metricLabel(entry.key),
                value: entry.value as Object,
              ),
            )
            .toList();
        return RoleScreenData(cards: metricCards, items: const []);
      }
      return RoleScreenData(cards: cards, items: items);
    }

    return const RoleScreenData(cards: [], items: []);
  }
}

String _metricLabel(String key) {
  return switch (key) {
    'ready_to_pack' => 'Đơn cần đóng gói',
    'packing' => 'Đang đóng gói',
    'packed_waiting_pickup' => 'Chờ shipper nhận',
    'returning' => 'Đơn đang trả',
    'returns_today' => 'Đơn trả hôm nay',
    'tasks_pending' => 'Nhiệm vụ chờ xử lý',
    'today_total' => 'Tổng đơn hôm nay',
    'available' => 'Có thể nhận',
    'delivering' => 'Đang giao',
    'delivered_today' => 'Đã giao hôm nay',
    _ => key.replaceAll('_', ' '),
  };
}

class RoleCardData {
  const RoleCardData({required this.label, required this.value});

  final String label;
  final Object value;

  factory RoleCardData.fromAny(Object? raw) {
    final map = raw is Map ? raw : const {};
    return RoleCardData(
      label: (map['label'] ?? '').toString(),
      value: map['value'] ?? 0,
    );
  }
}

class RoleListItemData {
  const RoleListItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.amount,
    required this.updatedAt,
    required this.raw,
  });

  final int id;
  final String title;
  final String subtitle;
  final String status;
  final double amount;
  final String updatedAt;
  final Map<String, dynamic> raw;

  factory RoleListItemData.fromAny(Object? raw) {
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final customer = map['customer'] is Map ? map['customer'] as Map : const {};
    final order = map['order'] is Map ? map['order'] as Map : const {};
    final warehouse = map['warehouse'] is Map
        ? map['warehouse'] as Map
        : const {};
    final sourceWarehouse = map['source_warehouse'] is Map
        ? map['source_warehouse'] as Map
        : const {};
    final targetWarehouse = map['target_warehouse'] is Map
        ? map['target_warehouse'] as Map
        : const {};

    final title =
        (map['title'] ??
                map['code'] ??
                map['document_number'] ??
                map['transfer_code'] ??
                order['code'] ??
                '#${map['id'] ?? ''}')
            .toString();

    final subtitle =
        (map['subtitle'] ??
                customer['name'] ??
                warehouse['name'] ??
                [sourceWarehouse['name'], targetWarehouse['name']]
                    .where(
                      (value) => value != null && value.toString().isNotEmpty,
                    )
                    .join(' -> '))
            .toString();

    return RoleListItemData(
      id: int.tryParse('${map['id'] ?? 0}') ?? 0,
      title: title.isEmpty ? '#${map['id'] ?? ''}' : title,
      subtitle: subtitle,
      status: (map['status'] ?? '').toString(),
      amount: double.tryParse('${map['amount'] ?? map['total'] ?? 0}') ?? 0,
      updatedAt:
          (map['updated_at'] ?? map['created_at'] ?? map['document_date'] ?? '')
              .toString(),
      raw: map,
    );
  }
}
