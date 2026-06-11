import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mobile_header_actions.dart';

class DeliveryScheduleScreen extends StatelessWidget {
  const DeliveryScheduleScreen({super.key, this.onConfirmed});

  final VoidCallback? onConfirmed;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình giao hàng'),
        actions: [
          MobileHeaderActions(onOpenNotification: _openNotificationRoute),
        ],
      ),
      body: Obx(() {
        final schedule = controller.deliverySchedule.value;

        if (controller.isLoading.value && !schedule.hasOrders) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!schedule.hasOrders && schedule.status == 'none') {
          return const EmptyState(
            title: 'Chưa có lộ trình',
            subtitle: 'Lộ trình sẽ xuất hiện khi manager gửi lịch giao hàng.',
          );
        }

        if (!schedule.hasOrders) {
          return RefreshIndicator(
            onRefresh: controller.loadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ScheduleHeader(
                  date: schedule.date,
                  code: schedule.code,
                  status: schedule.status,
                  count: schedule.ordersCount,
                  totalCod: schedule.totalCod,
                  notes: schedule.notes,
                ),
                const SizedBox(height: 12),
                const EmptyState(
                  title: 'Không có đơn cần xác nhận',
                  subtitle:
                      'Lộ trình đã xử lý hoặc chưa có thay đổi mới từ manager.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: schedule.orders.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ScheduleHeader(
                  date: schedule.date,
                  code: schedule.code,
                  status: schedule.status,
                  count: schedule.ordersCount,
                  totalCod: schedule.totalCod,
                  notes: schedule.notes,
                );
              }

              final order = schedule.orders[index - 1];
              return _ScheduleOrderCard(
                order: order,
                position: index,
                total: schedule.orders.length,
              );
            },
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final schedule = controller.deliverySchedule.value;
        if (!schedule.hasOrders) return const SizedBox.shrink();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        controller.isConfirmingSchedule.value ||
                            !schedule.isWaiting
                        ? null
                        : controller.rejectDeliverySchedule,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        controller.isConfirmingSchedule.value ||
                            !schedule.isWaiting
                        ? null
                        : () async {
                            final confirmed = await controller
                                .confirmDeliverySchedule();
                            if (confirmed) onConfirmed?.call();
                          },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      schedule.isConfirmed ? 'Đã xác nhận' : 'Xác nhận',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.date,
    required this.code,
    required this.status,
    required this.count,
    required this.totalCod,
    this.notes,
  });

  final String date;
  final String code;
  final String status;
  final int count;
  final double totalCod;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'confirmed' => ('Đã xác nhận', Colors.grey, Icons.check_circle_rounded),
      'rejected' => ('Đã từ chối', Colors.red, Icons.cancel_rounded),
      'changed' => ('Có thay đổi', Colors.orange, Icons.sync_problem_rounded),
      'waiting' => (
        'Chờ xác nhận',
        const Color(0xFF1E3A8A),
        Icons.schedule_rounded,
      ),
      _ => ('Chưa xác nhận', Colors.blueGrey, Icons.info_rounded),
    };
    final isNew = status == 'waiting' || status == 'changed';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: .12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code.isEmpty ? '$count đơn trong lộ trình' : code,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date.isEmpty ? 'Hôm nay' : date,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (isNew) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Mới'),
                    avatar: Icon(Icons.fiber_new_rounded, size: 18),
                    backgroundColor: Color(0xFFFEE2E2),
                    side: BorderSide(color: Color(0xFFFCA5A5)),
                    labelStyle: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                Chip(
                  label: Text(label),
                  avatar: Icon(icon, size: 18, color: color),
                  side: BorderSide(color: color.withValues(alpha: .25)),
                  backgroundColor: color.withValues(alpha: .08),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.receipt_long_rounded,
              text: '$count đơn | Tổng COD ${Formatters.money(totalCod)}',
            ),
            if (notes?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.notes_rounded, text: notes!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleOrderCard extends StatelessWidget {
  const _ScheduleOrderCard({
    required this.order,
    required this.position,
    required this.total,
  });

  final OrderModel order;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      'packed_waiting_pickup' => const Color(0xFF64748B),
      'delivering' => const Color(0xFFF59E0B),
      'delivered' || 'completed' => const Color(0xFF16A34A),
      'returning' || 'returned_completed' => const Color(0xFFDC2626),
      _ => Theme.of(context).colorScheme.primary,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor,
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.customer.name.isEmpty
                            ? 'Khách hàng chưa cập nhật'
                            : order.customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.deliveryTime?.isNotEmpty == true
                      ? order.deliveryTime!
                      : '--:--',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.place_rounded,
              text: order.customer.address.isEmpty
                  ? 'Chưa có địa chỉ'
                  : order.customer.address,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.shopping_bag_rounded,
              text:
                  '${order.itemCount ?? 0} sản phẩm | ${Formatters.money(order.total)} | Đơn $position/$total',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }
}
