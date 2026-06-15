import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/order_service.dart';

class DeliveryStatisticsScreen extends StatefulWidget {
  const DeliveryStatisticsScreen({super.key});

  @override
  State<DeliveryStatisticsScreen> createState() =>
      _DeliveryStatisticsScreenState();
}

class _DeliveryStatisticsScreenState extends State<DeliveryStatisticsScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now.subtract(Duration(days: now.weekday - 1));
    _toDate = _fromDate.add(const Duration(days: 6));
    _load();
  }

  void _load() {
    _future = Get.find<OrderService>().deliveryStatistics(
      fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
      toDate: DateFormat('yyyy-MM-dd').format(_toDate),
    );
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (range == null) return;
    setState(() {
      _fromDate = range.start;
      _toDate = range.end.difference(range.start).inDays > 31
          ? range.start.add(const Duration(days: 31))
          : range.end;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê giao hàng')),
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
          final dates = (data['dates'] as List? ?? const [])
              .map((date) => date.toString())
              .toList();
          final rows = (data['rows'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  '${DateFormat('dd/MM').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khoảng lọc tối đa 32 ngày. Vuốt ngang để xem các ngày.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Chưa có đơn giao thành công trong khoảng này',
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Khách hàng')),
                        for (final date in dates)
                          DataColumn(
                            numeric: true,
                            label: Text(
                              DateFormat('dd/MM').format(DateTime.parse(date)),
                            ),
                          ),
                        const DataColumn(numeric: true, label: Text('Tổng')),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              DataCell(Text('${row['customer_name'] ?? ''}')),
                              for (final date in dates)
                                DataCell(
                                  Text('${(row['days'] as Map?)?[date] ?? 0}'),
                                ),
                              DataCell(Text('${row['total'] ?? 0}')),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
