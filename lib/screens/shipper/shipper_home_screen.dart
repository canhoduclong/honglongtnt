import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../widgets/mobile_header_actions.dart';

class ShipperHomeScreen extends StatelessWidget {
  const ShipperHomeScreen({super.key, this.onScheduleConfirmed});

  final VoidCallback? onScheduleConfirmed;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Shipper'),
        actions: [
          MobileHeaderActions(onOpenNotification: _openNotificationRoute),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadAll,
        child: Obx(() {
          final stats = controller.stats.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hôm nay',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    label: 'Tổng đơn',
                    value: stats.todayTotal,
                    icon: Icons.today_rounded,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    label: 'Có thể nhận',
                    value: stats.available,
                    icon: Icons.inventory_rounded,
                    color: Colors.teal,
                  ),
                  _StatCard(
                    label: 'Đang giao',
                    value: stats.delivering,
                    icon: Icons.local_shipping_rounded,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    label: 'Đã giao',
                    value: stats.deliveredToday,
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lộ trình giao hàng mới nhất',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.deliverySchedule.value.code.isEmpty
                            ? '${controller.deliverySchedule.value.ordersCount} đơn cần xác nhận'
                            : controller.deliverySchedule.value.code,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Trạng thái: ${controller.deliverySchedule.value.status}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      if (controller.deliverySchedule.value.hasOrders) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    controller.isConfirmingSchedule.value ||
                                        !controller
                                            .deliverySchedule
                                            .value
                                            .isWaiting
                                    ? null
                                    : controller.rejectDeliverySchedule,
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Từ chối'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    controller.isConfirmingSchedule.value ||
                                        !controller
                                            .deliverySchedule
                                            .value
                                            .isWaiting
                                    ? null
                                    : () async {
                                        final confirmed = await controller
                                            .confirmDeliverySchedule();
                                        if (confirmed) {
                                          onScheduleConfirmed?.call();
                                        }
                                      },
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text('Xác nhận'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red.shade50,
                        child: Icon(
                          Icons.assignment_return_rounded,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đơn trả hàng',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${stats.returning} đơn đang xử lý',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Future<void> _openNotificationRoute(AppNotificationItem item) async {
    final tab = _tabForRouteKey(item.routeKey, item.orderId);
    if (tab == null) return;
    Get.offAllNamed(AppRoutes.shipperHome, arguments: {'tab': tab});
  }

  int? _tabForRouteKey(String routeKey, int? orderId) {
    final normalized = routeKey.trim().toLowerCase();
    if (normalized == 'available_orders' || normalized == 'available') {
      return 1;
    }
    if (normalized == 'delivery_schedules' || normalized == 'schedule') {
      return 2;
    }
    if (normalized == 'my_orders' ||
        normalized == 'orders' ||
        orderId != null) {
      return 1;
    }
    return 0;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            Text(
              '$value',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
