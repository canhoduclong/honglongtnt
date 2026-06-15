import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/sale_service.dart';
import '../../utils/formatters.dart';

class SaleDashboardScreen extends StatefulWidget {
  const SaleDashboardScreen({super.key});

  @override
  State<SaleDashboardScreen> createState() => _SaleDashboardScreenState();
}

class _SaleDashboardScreenState extends State<SaleDashboardScreen> {
  late Future<Map<String, dynamic>> _future;
  final Set<int> _submitting = {};

  SaleService get _service => Get.find<SaleService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _service.dashboard();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _DashboardMessage(
            icon: Icons.error_outline,
            title: 'Không tải được Dashboard',
            subtitle: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data = snapshot.data ?? const <String, dynamic>{};
        final stats = data['stats'] is Map
            ? Map<String, dynamic>.from(data['stats'] as Map)
            : <String, dynamic>{};
        final adjustments = (data['pending_adjustments'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
            children: [
              _statsGrid(stats),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    Icons.notification_important_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu điều chỉnh đơn từ kho',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Badge(label: Text('${adjustments.length}')),
                ],
              ),
              const SizedBox(height: 10),
              if (adjustments.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.task_alt, size: 40, color: Colors.green),
                        SizedBox(height: 8),
                        Text(
                          'Không có yêu cầu đang chờ duyệt.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final adjustment in adjustments) ...[
                  _adjustmentCard(adjustment),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _statsGrid(Map<String, dynamic> stats) {
    final cards = [
      ('Doanh thu', Formatters.money(_number(stats['total_revenue']))),
      (
        'Hoa hồng tháng',
        Formatters.money(_number(stats['commission_this_month'])),
      ),
      ('Đơn tháng này', '${stats['orders_this_month'] ?? 0}'),
      ('Khách hàng', '${stats['total_customers'] ?? 0}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: [
        for (final card in cards)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(card.$1, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  Text(
                    card.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _adjustmentCard(Map<String, dynamic> adjustment) {
    final id = int.tryParse('${adjustment['id']}') ?? 0;
    final changes = (adjustment['changes'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final loading = _submitting.contains(id);

    return Card(
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: .24),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${adjustment['code']} · ${adjustment['customer_name']}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (loading)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${adjustment['warehouse_name']} · ${_date(adjustment['requested_at'])}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Lý do: ${adjustment['note'].toString().trim().isEmpty ? 'Chưa cập nhật' : adjustment['note']}',
            ),
            const Divider(height: 22),
            for (final change in changes)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${change['product_name']}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'SKU: ${change['sku'].toString().isEmpty ? '---' : change['sku']} · SL ${change['old_quantity']} → ${change['new_quantity']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${change['change_label']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : () => _reject(id),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: loading ? null : () => _confirm(id),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(int id) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt yêu cầu điều chỉnh?'),
        content: const Text(
          'Các thay đổi từ kho sẽ được áp dụng vào đơn hàng và tính lại tổng tiền.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duyệt yêu cầu'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _run(id, () => _service.confirmWarehouseAdjustment(id));
  }

  Future<void> _reject(int id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            hintText: 'Nhập lý do để kho xử lý lại',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    await _run(id, () => _service.rejectWarehouseAdjustment(id, reason));
  }

  Future<void> _run(int id, Future<void> Function() action) async {
    setState(() => _submitting.add(id));
    try {
      await action();
      Get.snackbar('Thành công', 'Đã cập nhật yêu cầu điều chỉnh đơn.');
      await _refresh();
    } catch (error) {
      Get.snackbar('Không thể thực hiện', error.toString());
    } finally {
      if (mounted) setState(() => _submitting.remove(id));
    }
  }

  num _number(dynamic value) =>
      value is num ? value : num.tryParse('$value') ?? 0;

  String _date(dynamic value) {
    final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
    return parsed == null
        ? 'Chưa có thời gian gửi'
        : DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
