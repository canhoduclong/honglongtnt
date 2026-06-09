import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn Hàng'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Có thể nhận'),
              Tab(text: 'Đã nhận'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: controller.loadAll,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Obx(() {
          final available = controller.availableOrders.toList()
            ..sort(_prioritySort);
          final accepted = controller.acceptedOrders.toList()
            ..sort(_prioritySort);
          final total = available.length + accepted.length;

          return TabBarView(
            children: [
              _OrderTab(
                orders: available,
                totalCount: total,
                availableCount: available.length,
                acceptedCount: accepted.length,
                emptyTitle: 'Không có đơn sẵn sàng',
                emptySubtitle: 'Không có đơn sẵn sàng giao trong ngày hôm nay.',
                trailingBuilder: (order) => FilledButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.accept(order),
                  icon: const Icon(Icons.handshake_rounded, size: 18),
                  label: const Text('Nhận'),
                ),
              ),
              _OrderTab(
                orders: accepted,
                totalCount: total,
                availableCount: available.length,
                acceptedCount: accepted.length,
                emptyTitle: 'Chưa có đơn đã nhận',
                emptySubtitle:
                    'Các đơn trong cột Đơn đã nhận ở trang shipper sẽ hiển thị tại đây.',
                trailingBuilder: (order) => FilledButton.icon(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.orderDetail, arguments: order),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.local_shipping_rounded, size: 18),
                  label: const Text('Giao hàng'),
                ),
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
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({
    required this.orders,
    required this.totalCount,
    required this.availableCount,
    required this.acceptedCount,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.trailingBuilder,
  });

  final List<OrderModel> orders;
  final int totalCount;
  final int availableCount;
  final int acceptedCount;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(OrderModel order)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();
    return RefreshIndicator(
      onRefresh: controller.loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderSummary(
            totalCount: totalCount,
            availableCount: availableCount,
            acceptedCount: acceptedCount,
          ),
          const SizedBox(height: 12),
          if (controller.isLoading.value && orders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: EmptyState(title: emptyTitle, subtitle: emptySubtitle),
            )
          else
            ...orders.asMap().entries.map((entry) {
              final index = entry.key;
              final order = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == orders.length - 1 ? 0 : 12,
                ),
                child: OrderCard(
                  order: order,
                  priorityNumber: order.dailySequence ?? index + 1,
                  trailing: trailingBuilder?.call(order),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.totalCount,
    required this.availableCount,
    required this.acceptedCount,
  });

  final int totalCount;
  final int availableCount;
  final int acceptedCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
          label: 'Tổng đơn',
          count: totalCount,
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
        ),
        _SummaryChip(
          label: 'Có thể nhận',
          count: availableCount,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        _SummaryChip(
          label: 'Đã nhận',
          count: acceptedCount,
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.black,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final int count;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: backgroundColor,
      label: Text(
        '$label: $count',
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w800),
      ),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
