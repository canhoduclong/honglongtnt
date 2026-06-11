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
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Có thể nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Chưa hoàn thành'),
              Tab(text: 'Hoàn thành'),
              Tab(text: 'Trả hàng'),
            ],
          ),
          actions: [
            MobileHeaderActions(onOpenNotification: _openNotificationRoute),
          ],
        ),
        body: Obx(() {
          final allOrders = _uniqueOrders([
            ...controller.availableOrders,
            ...controller.myOrders,
            ...controller.historyOrders,
          ]);

          final available =
              allOrders.where((order) => order.isReadyToShip).toList()
                ..sort(_prioritySort);
          final delivering =
              allOrders.where((order) => order.isDelivering).toList()
                ..sort(_prioritySort);

          final unfinished =
              allOrders
                  .where(
                    (order) =>
                        !order.isReadyToShip &&
                        !order.isDelivering &&
                        !order.isDelivered &&
                        order.status != 'completed' &&
                        !order.isReturning &&
                        order.status != 'returned_completed',
                  )
                  .toList()
                ..sort(_prioritySort);

          final completed =
              allOrders
                  .where(
                    (order) => order.isDelivered || order.status == 'completed',
                  )
                  .toList()
                ..sort(_prioritySort);

          final returning =
              allOrders
                  .where(
                    (order) =>
                        order.isReturning ||
                        order.status == 'returned_completed',
                  )
                  .toList()
                ..sort(_prioritySort);

          return TabBarView(
            children: [
              _OrderList(
                orders: available,
                emptyTitle: 'Không có đơn có thể nhận',
                emptySubtitle: 'Đơn sẵn sàng giao sẽ hiển thị tại đây.',
                actionBuilder: (order) {
                  final accepting = controller.acceptingOrderIds.contains(
                    order.id,
                  );
                  return FilledButton.icon(
                    onPressed: accepting
                        ? null
                        : () => controller.accept(order),
                    icon: accepting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.handshake_rounded, size: 18),
                    label: Text(accepting ? 'Đang nhận...' : 'Nhận đơn'),
                  );
                },
              ),
              _OrderList(
                orders: delivering,
                emptyTitle: 'Chưa có đơn đang giao',
                emptySubtitle: 'Đơn đang vận chuyển sẽ hiển thị tại đây.',
                actionBuilder: (order) => FilledButton.icon(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.orderDetail, arguments: order),
                  icon: const Icon(Icons.local_shipping_rounded, size: 18),
                  label: const Text('Giao hàng'),
                ),
              ),
              _OrderList(
                orders: unfinished,
                emptyTitle: 'Chưa có đơn chưa hoàn thành',
                emptySubtitle:
                    'Các đơn cần tiếp tục xử lý sẽ hiển thị tại đây.',
              ),
              _OrderList(
                orders: completed,
                emptyTitle: 'Chưa có đơn hoàn thành',
                emptySubtitle: 'Đơn đã hoàn tất sẽ hiển thị tại đây.',
              ),
              _OrderList(
                orders: returning,
                emptyTitle: 'Chưa có đơn trả hàng',
                emptySubtitle: 'Đơn đang trả hoặc đã trả sẽ hiển thị tại đây.',
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

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.actionBuilder,
  });

  final List<OrderModel> orders;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(OrderModel order)? actionBuilder;

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
        itemBuilder: (_, index) => OrderCard(
          order: orders[index],
          trailing: actionBuilder?.call(orders[index]),
        ),
      ),
    );
  }
}
