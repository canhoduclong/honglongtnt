import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mobile_header_actions.dart';
import '../../widgets/order_card.dart';

class AvailableOrdersScreen extends StatelessWidget {
  const AvailableOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn có thể nhận'),
        actions: [
          MobileHeaderActions(onOpenNotification: _openNotificationRoute),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.availableOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.availableOrders.isEmpty) {
          return const EmptyState(
            title: 'Không có đơn sẵn sàng',
            subtitle: 'Danh sách sẽ tự cập nhật khi backend có đơn được gán.',
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.availableOrders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = controller.availableOrders[index];
              return OrderCard(
                order: order,
                trailing: FilledButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.accept(order),
                  icon: const Icon(Icons.handshake_rounded, size: 18),
                  label: const Text('Nhận'),
                ),
              );
            },
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
      return 2;
    }
    if (normalized == 'delivery_schedules' || normalized == 'schedule') {
      return 3;
    }
    if (normalized == 'my_orders' ||
        normalized == 'orders' ||
        orderId != null) {
      return 1;
    }
    return 0;
  }
}
