import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/order_service.dart';
import '../../utils/formatters.dart';

class ShipperCustomersScreen extends StatefulWidget {
  const ShipperCustomersScreen({super.key});

  @override
  State<ShipperCustomersScreen> createState() => _ShipperCustomersScreenState();
}

class _ShipperCustomersScreenState extends State<ShipperCustomersScreen> {
  DateTime _date = DateTime.now();
  String _sort = 'delivery_time';
  String _direction = 'asc';
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Get.find<OrderService>().customers(
      date: DateFormat('yyyy-MM-dd').format(_date),
      sort: _sort,
      direction: _direction,
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value == null) return;
    setState(() {
      _date = value;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khách hàng')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data ?? const {};
          final fixed = (data['fixed'] as List? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final unassigned = (data['unassigned'] as List? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    'Ngày giao ${DateFormat('dd/MM/yyyy').format(_date)}',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sort,
                        decoration: const InputDecoration(labelText: 'Sắp xếp'),
                        items: const [
                          DropdownMenuItem(
                            value: 'delivery_time',
                            child: Text('Giờ giao'),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Tên khách'),
                          ),
                          DropdownMenuItem(
                            value: 'orders_count',
                            child: Text('Số đơn'),
                          ),
                          DropdownMenuItem(
                            value: 'total',
                            child: Text('Tổng tiền'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _sort = value ?? _sort;
                          _load();
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Đổi thứ tự',
                      onPressed: () => setState(() {
                        _direction = _direction == 'asc' ? 'desc' : 'asc';
                        _load();
                      }),
                      icon: Icon(
                        _direction == 'asc'
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CustomerSection(
                  title: 'Được gán cố định',
                  color: Colors.green,
                  customers: fixed,
                ),
                const SizedBox(height: 16),
                _CustomerSection(
                  title: 'Chưa gán cố định',
                  color: Colors.blueGrey,
                  customers: unassigned,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.title,
    required this.color,
    required this.customers,
  });

  final String title;
  final Color color;
  final List<Map<String, dynamic>> customers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Chip(
              label: Text('${customers.length}'),
              backgroundColor: color.withValues(alpha: .12),
            ),
          ],
        ),
        if (customers.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Không có khách hàng trong ngày này')),
            ),
          )
        else
          for (final customer in customers)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: .12),
                  child: Icon(Icons.person_rounded, color: color),
                ),
                title: Text(
                  '${customer['name'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${customer['delivery_time'] ?? '—'} | ${customer['phone'] ?? ''}\n${customer['address'] ?? ''}',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${customer['orders_count'] ?? 0} đơn'),
                    Text(
                      Formatters.money(
                        double.tryParse('${customer['orders_total'] ?? 0}') ??
                            0,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
