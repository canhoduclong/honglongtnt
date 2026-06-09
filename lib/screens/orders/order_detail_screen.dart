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
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
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
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Lý do trả hàng',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => controller.markReturning(
                        order,
                        reason: _reasonController.text.trim(),
                      ),
                      icon: const Icon(Icons.assignment_return_rounded),
                      label: const Text('Trả hàng'),
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
