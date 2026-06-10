import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../models/order_model.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = Get.arguments as OrderModel;
    final controller = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(title: Text(order.code)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.code,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Khách hàng',
                    value: order.customer.name,
                  ),
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    label: 'SĐT',
                    value: order.customer.phone,
                  ),
                  _InfoRow(
                    icon: Icons.place_rounded,
                    label: 'Địa chỉ',
                    value: order.customer.address,
                  ),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Cập nhật',
                    value: Formatters.dateTime(order.updatedAt),
                  ),
                  const Divider(height: 26),
                  Text(
                    'Giá trị đơn: ${Formatters.money(order.total)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (order.isReadyToShip) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => controller.accept(order),
              icon: const Icon(Icons.handshake_rounded),
              label: const Text('Nhận đơn'),
            ),
          ],
          if (order.isDelivering) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cập nhật giao hàng',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền thu hộ (nếu có)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final amount = double.tryParse(
                          _amountController.text.trim(),
                        );
                        controller.markDelivered(
                          order,
                          collectedAmount: amount,
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Hoàn thành giao hàng'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showReturnDialog(controller, order),
                      icon: const Icon(Icons.assignment_return_rounded),
                      label: const Text('Tạo phiếu trả hàng về kho'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showReturnDialog(
    OrderController controller,
    OrderModel order,
  ) async {
    final warehouses = await controller.warehouses();
    if (!mounted) return;
    if (warehouses.isEmpty) {
      Get.snackbar('Không có kho', 'Chưa có kho nhận hàng trả.');
      return;
    }

    var warehouseId = warehouses.first.id;
    var reason = 'customer_refused';
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo phiếu trả hàng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: warehouseId,
                  decoration: const InputDecoration(labelText: 'Kho nhận trả'),
                  items: [
                    for (final warehouse in warehouses)
                      DropdownMenuItem(
                        value: warehouse.id,
                        child: Text(warehouse.name),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => warehouseId = value ?? warehouseId),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Lý do trả'),
                  items: const [
                    DropdownMenuItem(
                      value: 'customer_refused',
                      child: Text('Khách từ chối nhận'),
                    ),
                    DropdownMenuItem(
                      value: 'no_contact',
                      child: Text('Không liên lạc được'),
                    ),
                    DropdownMenuItem(
                      value: 'wrong_address',
                      child: Text('Sai địa chỉ'),
                    ),
                    DropdownMenuItem(
                      value: 'damaged',
                      child: Text('Hàng hỏng / không đủ điều kiện'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => reason = value ?? reason),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo phiếu trả'),
            ),
          ],
        ),
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (confirmed != true) return;

    await controller.markReturning(
      order,
      warehouseId: warehouseId,
      reason: reason,
      note: note,
    );
    if (mounted) Navigator.of(context).pop();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
