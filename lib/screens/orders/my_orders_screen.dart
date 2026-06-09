import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mobile_header_actions.dart';
import '../../widgets/order_card.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn của tôi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đang giao'),
              Tab(text: 'Chưa hoàn thiện'),
              Tab(text: 'Lịch sử'),
            ],
          ),
          actions: [
            MobileHeaderActions(onOpenNotification: _openNotificationRoute),
          ],
        ),
        body: Obx(() {
          final allOrders = _uniqueOrders([
            ...controller.myOrders,
            ...controller.historyOrders,
          ]);

          final delivering =
              allOrders.where((order) => order.isDelivering).toList()
                ..sort(_prioritySort);

          final unfinished =
              allOrders.where((order) => order.isReturning).toList()
                ..sort(_prioritySort);

          final history =
              allOrders
                  .where(
                    (order) =>
                        order.isDelivered ||
                        order.status == 'completed' ||
                        order.status == 'returned_completed',
                  )
                  .toList()
                ..sort(_prioritySort);

          return TabBarView(
            children: [
              _OrderList(
                orders: delivering,
                emptyTitle: 'Chưa có đơn đang giao',
                emptySubtitle: 'Đơn đang vận chuyển sẽ hiển thị tại đây.',
              ),
              _OrderList(
                orders: unfinished,
                emptyTitle: 'Chưa có đơn chưa hoàn thiện',
                emptySubtitle:
                    'Các đơn đã bấm Giao hàng hoặc Trả hàng nhưng chưa chốt sẽ hiển thị tại đây.',
              ),
              _OrderList(
                orders: history,
                emptyTitle: 'Chưa có đơn lịch sử',
                emptySubtitle:
                    'Đơn giao xong hoặc trả hàng hoàn tất sẽ hiển thị tại đây.',
              ),
            ],
          );
        }),
      ),
    );
  }

  static int _prioritySort(OrderModel a, OrderModel b) {
    final aSeq = a.dailySequence ?? 999999;
    final bSeq = b.dailySequence ?? 999999;
    if (aSeq != bSeq) return aSeq.compareTo(bSeq);
    return a.id.compareTo(b.id);
  }

  static List<OrderModel> _uniqueOrders(List<OrderModel> orders) {
    final byId = <int, OrderModel>{};
    for (final order in orders) {
      byId[order.id] = order;
    }
    return byId.values.toList();
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

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<OrderModel> orders;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();
    if (controller.isLoading.value && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) {
      return EmptyState(title: emptyTitle, subtitle: emptySubtitle);
    }
    return RefreshIndicator(
      onRefresh: controller.loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => OrderCard(order: orders[index]),
      ),
    );
  }
}
