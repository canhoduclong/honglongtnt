import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/user_model.dart';
import '../../services/sale_service.dart';
import '../../utils/formatters.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key, required this.menu});

  final MenuItemModel menu;

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  late Future<SaleListData> _future;
  String _filter = '';
  String _sort = 'created_at';
  bool _trash = false;

  SaleService get _service => Get.find<SaleService>();
  bool get _customers => widget.menu.key == 'customers';
  bool get _orders => widget.menu.key == 'my_orders';
  bool get _approvals => !_customers && !_orders;

  @override
  void initState() {
    super.initState();
    if (_customers) _sort = 'id';
    _load();
  }

  @override
  void didUpdateWidget(covariant SaleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu.key != widget.menu.key) {
      _search.clear();
      _filter = '';
      _trash = false;
      _sort = _customers ? 'id' : 'created_at';
      _load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _load() {
    if (_customers) {
      _future = _service.customers(
        search: _search.text,
        tab: _trash
            ? 'trash'
            : _filter.isEmpty
            ? 'all'
            : _filter,
        sortBy: _sort,
      );
    } else if (_orders) {
      _future = _service.orders(
        search: _search.text,
        status: _filter,
        trash: _trash,
        sortBy: _sort,
      );
    } else {
      _future = _service.approvals(
        widget.menu.key == 'team_approvals' ? 'leader' : 'manager',
        search: _search.text,
        status: _filter,
      );
    }
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _toolbar(),
            Expanded(
              child: FutureBuilder<SaleListData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _EmptyState(
                      icon: Icons.error_outline,
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }
                  final items = snapshot.data?.items ?? const [];
                  if (items.isEmpty) {
                    return _EmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'Không có dữ liệu phù hợp.',
                      onRetry: _refresh,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 92),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _customers
                          ? _customerCard(items[index])
                          : _orderCard(items[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_customers)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openCustomerForm(),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Thêm khách'),
            ),
          ),
      ],
    );
  }

  Widget _toolbar() {
    final filters = _customers
        ? const {'': 'Tất cả', 'processing': 'Đang chăm sóc'}
        : const {
            '': 'Tất cả',
            'pending_leader_approval': 'Chờ Leader',
            'pending_manager_approval': 'Chờ Manager',
            'approved': 'Đã duyệt',
            'rejected': 'Từ chối',
            'cancelled': 'Đã hủy',
          };
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          children: [
            TextField(
              controller: _search,
              onChanged: _searchChanged,
              decoration: InputDecoration(
                hintText: _customers
                    ? 'Tìm tên, điện thoại, email'
                    : 'Tìm mã đơn, khách hàng',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _search.clear();
                    _refresh();
                  },
                  icon: const Icon(Icons.close),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bộ lọc',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: filters.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filter = value ?? '';
                        _load();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Sắp xếp',
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() {
                      _sort = value;
                      _load();
                    });
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'created_at',
                      child: Text('Mới nhất'),
                    ),
                    if (_customers) ...const [
                      PopupMenuItem(value: 'name', child: Text('Tên khách')),
                      PopupMenuItem(value: 'size', child: Text('Quy mô')),
                      PopupMenuItem(
                        value: 'production',
                        child: Text('Sản lượng'),
                      ),
                    ],
                    if (!_customers)
                      const PopupMenuItem(
                        value: 'total',
                        child: Text('Tổng tiền'),
                      ),
                  ],
                ),
                if (!_approvals)
                  FilterChip(
                    selected: _trash,
                    label: const Text('Thùng rác'),
                    avatar: const Icon(Icons.delete_outline, size: 18),
                    onSelected: (value) {
                      setState(() {
                        _trash = value;
                        _load();
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(Map<String, dynamic> customer) {
    final deleted = customer['deleted_at'] != null;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCustomer(customer),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${customer['name'] ?? 'Khách hàng'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _Status('${customer['status'] ?? ''}'),
                ],
              ),
              const SizedBox(height: 8),
              _Info(Icons.phone_outlined, '${customer['phone'] ?? '-'}'),
              _Info(
                Icons.location_on_outlined,
                '${customer['address'] ?? '-'}',
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text('${customer['orders_count'] ?? 0} đơn hàng'),
                  ),
                  Text(
                    'Công nợ ${Formatters.money(_num(customer['total_debt']))}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _customerAction(value, customer),
                    itemBuilder: (_) => [
                      if (!deleted) ...const [
                        PopupMenuItem(value: 'order', child: Text('Tạo đơn')),
                        PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                        PopupMenuItem(
                          value: 'care',
                          child: Text('Ghi nhật ký chăm sóc'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Xóa')),
                      ] else
                        const PopupMenuItem(
                          value: 'restore',
                          child: Text('Khôi phục'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final customer = _map(order['customer']);
    final items = _list(order['items']);
    final customerName =
        '${customer['name'] ?? order['recipient_name'] ?? 'Khách hàng'}';
    final orderCode = '${order['code'] ?? '#${order['id']}'}';
    final priority = _num(order['daily_sequence']).toInt();
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrder(order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orderCode.toLowerCase(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (priority > 0) ...[
                    _PriorityBadge(priority),
                    const SizedBox(width: 8),
                  ],
                  _Status('${order['status'] ?? ''}'),
                ],
              ),
              const SizedBox(height: 8),
              _Info(
                Icons.schedule_outlined,
                'Lên đơn: ${Formatters.dateTime('${order['created_at'] ?? ''}')}',
              ),
              const SizedBox(height: 4),
              _Info(
                Icons.local_shipping_outlined,
                'Ngày giao: ${order['delivery_date'] ?? 'Chưa cập nhật'}',
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final item in items) _OrderItemSummary(item: item),
              ],
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Formatters.money(_num(order['total'])),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_approvals && order['can_approve'] == true) ...[
                    FilledButton.tonal(
                      onPressed: () => _approvalAction(order, false),
                      child: const Text('Từ chối'),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () => _approvalAction(order, true),
                      child: const Text('Duyệt'),
                    ),
                  ] else if (_orders)
                    PopupMenuButton<String>(
                      onSelected: (value) => _orderAction(value, order),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy đơn'),
                        ),
                        if (!_trash && order['can_edit'] == true)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Chỉnh sửa'),
                          ),
                        if (!_trash && order['can_cancel'] == true)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Text('Hủy đơn'),
                          ),
                        if (!_trash && order['can_trash'] == true)
                          const PopupMenuItem(
                            value: 'trash',
                            child: Text('Chuyển vào thùng rác'),
                          ),
                        if (order['copied_from_order_id'] != null)
                          const PopupMenuItem(
                            value: 'confirm_copy',
                            child: Text('Xác nhận đơn copy'),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _customerAction(
    String action,
    Map<String, dynamic> customer,
  ) async {
    final id = _num(customer['id']).toInt();
    if (action == 'edit') return _openCustomerForm(customer);
    if (action == 'order') return _openOrderForm(customer: customer);
    if (action == 'care') {
      final note = await _askText('Nhật ký chăm sóc', required: true);
      if (note == null) return;
      return _run(() async {
        await _service.saveCustomer({'care_note': note}, id: id);
      });
    }
    if (!await _confirm(
      action == 'delete' ? 'Xóa khách hàng này?' : 'Khôi phục khách hàng này?',
    )) {
      return;
    }
    await _run(
      () => action == 'delete'
          ? _service.deleteCustomer(id)
          : _service.restoreCustomer(id),
    );
  }

  Future<void> _orderAction(String action, Map<String, dynamic> order) async {
    final id = _num(order['id']).toInt();
    if (action == 'edit') {
      final detail = await _service.order(id);
      return _openOrderForm(customer: _map(detail['customer']), order: detail);
    }
    if (action == 'copy') {
      await _run(() async {
        final copyId = await _service.copyOrder(id);
        if (copyId != null) {
          final copy = await _service.order(copyId);
          if (mounted) {
            await _openOrderForm(customer: _map(copy['customer']), order: copy);
          }
        }
      });
      return;
    }
    if (action == 'cancel') {
      final reason = await _askText('Lý do hủy đơn', required: false);
      if (reason == null) return;
      return _run(() => _service.cancelOrder(id, reason));
    }
    if (!await _confirm(
      action == 'trash' ? 'Chuyển đơn vào thùng rác?' : 'Xác nhận đơn copy?',
    )) {
      return;
    }
    await _run(
      () => action == 'trash'
          ? _service.trashOrder(id)
          : _service.confirmCopy(id),
    );
  }

  Future<void> _approvalAction(Map<String, dynamic> order, bool approve) async {
    final note = await _askText(
      approve ? 'Ghi chú duyệt' : 'Lý do từ chối',
      required: !approve,
    );
    if (note == null) return;
    final id = _num(order['id']).toInt();
    await _run(
      () => approve ? _service.approve(id, note) : _service.reject(id, note),
    );
  }

  Future<void> _showCustomer(Map<String, dynamic> customer) async {
    final detail = await _service.customer(_num(customer['id']).toInt());
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .94,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Text(
              '${detail['name']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _Info(Icons.phone_outlined, '${detail['phone'] ?? '-'}'),
            _Info(Icons.email_outlined, '${detail['email'] ?? '-'}'),
            _Info(Icons.location_on_outlined, '${detail['address'] ?? '-'}'),
            _Info(Icons.schedule_outlined, '${detail['delivery_time'] ?? '-'}'),
            _Info(Icons.factory_outlined, '${detail['production'] ?? '-'}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openOrderForm(customer: detail);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Tạo đơn hàng'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openCustomerForm(detail);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa khách hàng'),
            ),
            const Divider(height: 28),
            Text(
              'Đơn hàng gần đây',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final order in _list(detail['orders']))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${order['code'] ?? '#${order['id']}'}'),
                subtitle: Text('${order['status'] ?? ''}'),
                trailing: Text(Formatters.money(_num(order['total']))),
              ),
            if (_list(detail['care_logs']).isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Nhật ký chăm sóc',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final log in _list(detail['care_logs']))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text('${log['note'] ?? log['action_type'] ?? ''}'),
                  subtitle: Text(
                    Formatters.dateTime('${log['created_at'] ?? ''}'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showOrder(Map<String, dynamic> order) async {
    final detail = await _service.order(_num(order['id']).toInt());
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
        maxChildSize: .95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${detail['code'] ?? '#${detail['id']}'}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _Status('${detail['status'] ?? ''}'),
              ],
            ),
            const SizedBox(height: 12),
            _Info(Icons.person_outline, '${detail['recipient_name'] ?? '-'}'),
            _Info(Icons.phone_outlined, '${detail['recipient_phone'] ?? '-'}'),
            _Info(
              Icons.location_on_outlined,
              '${detail['recipient_address'] ?? '-'}',
            ),
            _Info(Icons.notes_outlined, '${detail['note'] ?? '-'}'),
            const Divider(height: 28),
            Text('Sản phẩm', style: Theme.of(context).textTheme.titleMedium),
            for (final item in _list(detail['items']))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_itemName(item)),
                subtitle: Text(
                  '${item['quantity'] ?? 0} × ${Formatters.money(_num(item['price']))}',
                ),
                trailing: Text(
                  Formatters.money(
                    _num(item['total'] ?? item['subtotal'] ?? item['price']) *
                        (_num(item['total'] ?? item['subtotal']) > 0
                            ? 1
                            : _num(item['quantity'])),
                  ),
                ),
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tổng: ${Formatters.money(_num(detail['total']))}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (_list(detail['approvals']).isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Lịch sử duyệt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final approval in _list(detail['approvals']))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(
                    '${_map(approval['step'])['name'] ?? approval['status'] ?? ''}',
                  ),
                  subtitle: Text(
                    '${approval['note'] ?? approval['reason'] ?? ''}',
                  ),
                  trailing: _Status('${approval['status'] ?? ''}'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCustomerForm([Map<String, dynamic>? customer]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
    );
    await _refresh();
  }

  Future<void> _openOrderForm({
    required Map<String, dynamic> customer,
    Map<String, dynamic>? order,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleOrderFormScreen(customer: customer, order: order),
      ),
    );
    await _refresh();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      Get.snackbar('Thành công', 'Đã cập nhật dữ liệu.');
      await _refresh();
    } catch (error) {
      Get.snackbar('Không thể thực hiện', error.toString());
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _askText(String title, {required bool required}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final Map<String, dynamic>? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _key = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  Map<String, dynamic> _options = {};
  int? _provinceId;
  int? _wardId;
  int? _stationId;
  int? _routeId;
  bool _useStation = false;
  bool _saving = false;

  static const _names = [
    'name',
    'phone',
    'email',
    'address',
    'delivery_time',
    'size',
    'production',
    'company_name',
    'tax_code',
    'company_address',
    'company_email',
    'truck_station_address',
    'truck_station_phone',
    'truck_receive_time',
    'truck_return_time',
    'truck_fee',
  ];

  @override
  void initState() {
    super.initState();
    final customer = widget.customer ?? {};
    for (final name in _names) {
      _fields[name] = TextEditingController(text: '${customer[name] ?? ''}');
    }
    _provinceId = _id(customer['province_id']);
    _wardId = _id(customer['ward_id']);
    _stationId = _id(customer['truck_station_id']);
    _routeId = _id(customer['truck_route_id']);
    _useStation = customer['use_truck_station'] == true;
    _loadOptions();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final options = await Get.find<SaleService>().customerOptions(
      provinceId: _provinceId,
    );
    if (mounted) setState(() => _options = options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer == null ? 'Thêm khách hàng' : 'Sửa khách hàng',
        ),
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('name', 'Tên khách hàng', required: true),
            _field('phone', 'Điện thoại', keyboard: TextInputType.phone),
            _field('email', 'Email', keyboard: TextInputType.emailAddress),
            _field('address', 'Địa chỉ', lines: 2),
            _select('Tỉnh/Thành', _provinceId, _options['provinces'], (value) {
              setState(() {
                _provinceId = value;
                _wardId = null;
              });
              _loadOptions();
            }),
            _select('Phường/Xã', _wardId, _options['wards'], (value) {
              setState(() => _wardId = value);
            }),
            _field('delivery_time', 'Thời gian giao hàng'),
            _field('size', 'Quy mô'),
            _field('production', 'Sản lượng'),
            const Divider(height: 28),
            _field('company_name', 'Tên công ty'),
            _field('tax_code', 'Mã số thuế'),
            _field('company_address', 'Địa chỉ công ty'),
            _field('company_email', 'Email công ty'),
            const Divider(height: 28),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _useStation,
              title: const Text('Giao qua nhà xe'),
              onChanged: (value) => setState(() => _useStation = value),
            ),
            if (_useStation) ...[
              _select('Nhà xe', _stationId, _options['truck_stations'], (
                value,
              ) {
                setState(() => _stationId = value);
              }),
              _select('Tuyến xe', _routeId, _options['truck_routes'], (value) {
                setState(() => _routeId = value);
              }),
              _field('truck_station_address', 'Địa chỉ nhà xe'),
              _field('truck_station_phone', 'Điện thoại nhà xe'),
              _field('truck_receive_time', 'Giờ nhận hàng'),
              _field('truck_return_time', 'Giờ trả hàng'),
              _field('truck_fee', 'Phí nhà xe', keyboard: TextInputType.number),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Lưu khách hàng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String name,
    String label, {
    bool required = false,
    int lines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[name],
        maxLines: lines,
        keyboardType: keyboard,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập $label'
                  : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _select(
    String label,
    int? value,
    dynamic source,
    ValueChanged<int?> changed,
  ) {
    final items = _list(source);
    final validValue = items.any((item) => _id(item['id']) == value)
        ? value
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: validValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: _id(item['id']),
                child: Text('${item['name'] ?? ''}'),
              ),
            )
            .toList(),
        onChanged: changed,
      ),
    );
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      'province_id': _provinceId,
      'ward_id': _wardId,
      'use_truck_station': _useStation,
      'truck_station_id': _useStation ? _stationId : null,
      'truck_route_id': _useStation ? _routeId : null,
    };
    try {
      if (widget.customer == null) {
        final duplicate = await Get.find<SaleService>().checkCustomerDuplicate(
          name: _fields['name']!.text.trim(),
          phone: _fields['phone']!.text.trim(),
          email: _fields['email']!.text.trim(),
        );
        if (duplicate['duplicate'] == true && mounted) {
          final priority = await _priorityDialog(duplicate);
          if (priority == null) {
            setState(() => _saving = false);
            return;
          }
          payload['duplicate_customer_id'] = duplicate['id'];
          payload['duplicate_priority_level'] = priority;
        }
      }
      await Get.find<SaleService>().saveCustomer(
        payload,
        id: _id(widget.customer?['id']),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      Get.snackbar('Không thể lưu', error.toString());
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<int?> _priorityDialog(Map<String, dynamic> duplicate) {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khách hàng đã tồn tại'),
        content: Text(
          '${duplicate['name'] ?? ''} · ${duplicate['phone'] ?? ''}\nChọn mức ưu tiên chăm sóc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          if (duplicate['is_free'] == true)
            TextButton(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('Priority 1'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text('Priority 2'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 3),
            child: const Text('Priority 3'),
          ),
        ],
      ),
    );
  }
}

class SaleOrderFormScreen extends StatefulWidget {
  const SaleOrderFormScreen({super.key, required this.customer, this.order});

  final Map<String, dynamic> customer;
  final Map<String, dynamic>? order;

  @override
  State<SaleOrderFormScreen> createState() => _SaleOrderFormScreenState();
}

class _SaleOrderFormScreenState extends State<SaleOrderFormScreen> {
  final _key = GlobalKey<FormState>();
  final _productSearch = TextEditingController();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _delivery;
  late final TextEditingController _note;
  late final TextEditingController _shipperNote;
  late final TextEditingController _discount;
  final List<_OrderLine> _lines = [];
  bool _saving = false;
  String _discountType = 'decrease';

  @override
  void initState() {
    super.initState();
    final source = widget.order ?? widget.customer;
    _name = TextEditingController(
      text: '${source['recipient_name'] ?? widget.customer['name'] ?? ''}',
    );
    _phone = TextEditingController(
      text: '${source['recipient_phone'] ?? widget.customer['phone'] ?? ''}',
    );
    _email = TextEditingController(
      text: '${source['recipient_email'] ?? widget.customer['email'] ?? ''}',
    );
    _address = TextEditingController(
      text:
          '${source['recipient_address'] ?? widget.customer['address'] ?? ''}',
    );
    _delivery = TextEditingController(text: '${source['delivery_time'] ?? ''}');
    _note = TextEditingController(text: '${source['note'] ?? ''}');
    _shipperNote = TextEditingController(
      text: '${source['shipper_note'] ?? ''}',
    );
    _discount = TextEditingController(text: '${source['order_discount'] ?? 0}');
    _discountType = '${source['order_discount_type'] ?? 'decrease'}';
    for (final item in _list(widget.order?['items'])) {
      _lines.add(_OrderLine.fromItem(item));
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _productSearch,
      _name,
      _phone,
      _email,
      _address,
      _delivery,
      _note,
      _shipperNote,
      _discount,
    ]) {
      controller.dispose();
    }
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Tạo đơn hàng' : 'Chỉnh sửa đơn'),
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${widget.customer['name'] ?? 'Khách hàng'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _required(_name, 'Người nhận'),
            _required(_phone, 'Điện thoại'),
            _field(_email, 'Email'),
            _required(_address, 'Địa chỉ nhận', lines: 2),
            _field(_delivery, 'Thời gian giao'),
            _field(_note, 'Ghi chú đơn', lines: 2),
            _field(_shipperNote, 'Ghi chú shipper', lines: 2),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sản phẩm',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _pickProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            if (_lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Chưa chọn sản phẩm')),
              ),
            for (final line in _lines) _lineCard(line),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(child: _field(_discount, 'Điều chỉnh đơn')),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _discountType,
                    decoration: const InputDecoration(
                      labelText: 'Loại',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'decrease', child: Text('Giảm')),
                      DropdownMenuItem(value: 'increase', child: Text('Tăng')),
                    ],
                    onChanged: (value) =>
                        setState(() => _discountType = value ?? 'decrease'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(widget.order == null ? 'Tạo đơn' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineCard(_OrderLine line) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _lines.remove(line));
                    line.dispose();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(line.quantity, 'Số lượng')),
                const SizedBox(width: 8),
                Expanded(child: _field(line.discount, 'Điều chỉnh/SP')),
                const SizedBox(width: 8),
                Expanded(child: _field(line.weight, 'Kg/SP')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _required(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Vui lòng nhập $label'
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _pickProduct() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProductPicker(search: _productSearch),
    );
    if (selected == null) return;
    final id = _id(selected['id']) ?? 0;
    if (_lines.any((line) => line.variantId == id)) return;
    setState(() => _lines.add(_OrderLine.fromProduct(selected)));
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_lines.isEmpty) {
      Get.snackbar('Thiếu sản phẩm', 'Đơn hàng phải có ít nhất một sản phẩm.');
      return;
    }
    setState(() => _saving = true);
    final payload = {
      'customer_id': _id(widget.customer['id']),
      'recipient_name': _name.text.trim(),
      'recipient_phone': _phone.text.trim(),
      'recipient_email': _email.text.trim(),
      'recipient_address': _address.text.trim(),
      'delivery_time': _delivery.text.trim(),
      'note': _note.text.trim(),
      'shipper_note': _shipperNote.text.trim(),
      'order_discount': _num(_discount.text),
      'order_discount_type': _discountType,
      'items': [
        for (final line in _lines)
          {
            'variant_id': line.variantId,
            'quantity': _num(line.quantity.text).toInt(),
            'price': line.price,
            'base_price': line.price,
          },
      ],
      'item_discount': {
        for (final line in _lines)
          '${line.variantId}': _num(line.discount.text),
      },
      'item_discount_type': {
        for (final line in _lines) '${line.variantId}': line.discountType,
      },
      'item_weight': {
        for (final line in _lines) '${line.variantId}': _num(line.weight.text),
      },
    };
    try {
      final service = Get.find<SaleService>();
      final orderId = _id(widget.order?['id']);
      if (orderId == null) {
        await service.createOrder(_id(widget.customer['id'])!, payload);
      } else {
        await service.updateOrder(orderId, payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      Get.snackbar('Không thể lưu đơn', error.toString());
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.search});

  final TextEditingController search;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  late Future<SaleListData> _future;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Get.find<SaleService>().products(search: widget.search.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      maxChildSize: .96,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: widget.search,
              autofocus: true,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  setState(_load);
                });
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm sản phẩm hoặc SKU',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<SaleListData>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: controller,
                  itemCount: snapshot.data!.items.length,
                  itemBuilder: (_, index) {
                    final product = snapshot.data!.items[index];
                    return ListTile(
                      title: Text('${product['name'] ?? 'Sản phẩm'}'),
                      subtitle: Text(
                        '${product['sku'] ?? ''} · Tồn ${product['available_stock'] ?? 0}',
                      ),
                      trailing: Text(Formatters.money(_num(product['price']))),
                      onTap: () => Navigator.pop(context, product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLine {
  _OrderLine({
    required this.variantId,
    required this.name,
    required this.price,
    required String quantity,
    required String discount,
    required String weight,
    this.discountType = 'decrease',
  }) : quantity = TextEditingController(text: quantity),
       discount = TextEditingController(text: discount),
       weight = TextEditingController(text: weight);

  final int variantId;
  final String name;
  final num price;
  final TextEditingController quantity;
  final TextEditingController discount;
  final TextEditingController weight;
  final String discountType;

  factory _OrderLine.fromProduct(Map<String, dynamic> product) => _OrderLine(
    variantId: _id(product['id']) ?? 0,
    name: '${product['name'] ?? 'Sản phẩm'}',
    price: _num(product['price']),
    quantity: '1',
    discount: '0',
    weight: '${product['kg'] ?? 0}',
  );

  factory _OrderLine.fromItem(Map<String, dynamic> item) {
    return _OrderLine(
      variantId: _id(item['product_variant_id'] ?? item['variant_id']) ?? 0,
      name: _itemName(item),
      price: _num(item['price']),
      quantity: '${item['quantity'] ?? 1}',
      discount: '${item['discount'] ?? item['unit_discount'] ?? 0}',
      weight: '${item['weight'] ?? item['unit_weight'] ?? 0}',
      discountType: '${item['discount_type'] ?? 'decrease'}',
    );
  }

  void dispose() {
    quantity.dispose();
    discount.dispose();
    weight.dispose();
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: Text(
        'Ưu tiên #$number',
        style: const TextStyle(
          color: Color(0xFF9A3412),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderItemSummary extends StatelessWidget {
  const _OrderItemSummary({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final variant = _map(item['variant']);
    final size = '${variant['size'] ?? item['size'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              [
                _productName(item),
                'Size ${size.isEmpty ? '-' : size}',
                'SL ${item['quantity'] ?? 0}',
                'Giá ${Formatters.money(_num(item['price']))}',
              ].join(' | '),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final text = value.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 52),
          const SizedBox(height: 12),
          Center(child: Text(message, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<Map<String, dynamic>> _list(dynamic value) =>
    (value as List? ?? const []).whereType<Map<String, dynamic>>().toList();

num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;

int? _id(dynamic value) {
  final id = int.tryParse('$value');
  return id == null || id <= 0 ? null : id;
}

String _itemName(Map<String, dynamic> item) {
  final variant = _map(item['variant']);
  final product = _map(item['product']);
  return '${variant['name'] ?? product['name'] ?? item['name'] ?? 'Sản phẩm'}';
}

String _productName(Map<String, dynamic> item) {
  final product = _map(item['product']);
  final variant = _map(item['variant']);
  return '${product['name'] ?? variant['name'] ?? item['name'] ?? 'Sản phẩm'}';
}
