import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/dashboard_stats.dart';
import '../models/delivery_schedule_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/api_exception.dart';

class OrderController extends GetxController {
  OrderController(this._orderService);

  final OrderService _orderService;

  final stats = DashboardStats.empty.obs;
  final deliverySchedule = DeliveryScheduleModel.empty.obs;
  final availableOrders = <OrderModel>[].obs;
  final acceptedOrders = <OrderModel>[].obs;
  final myOrders = <OrderModel>[].obs;
  final historyOrders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        _orderService.dashboard(),
        _orderService.deliverySchedule(),
        _orderService.availableOrders(),
        _orderService.myOrders(),
        _orderService.history(),
      ]);
      stats.value = results[0] as DashboardStats;
      deliverySchedule.value = results[1] as DeliveryScheduleModel;
      availableOrders.assignAll(results[2] as List<OrderModel>);
      myOrders.assignAll(results[3] as List<OrderModel>);
      historyOrders.assignAll(results[4] as List<OrderModel>);

      try {
        acceptedOrders.assignAll(await _orderService.acceptedOrders());
      } catch (_) {
        acceptedOrders.assignAll(myOrders.where((order) => order.isDelivering));
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Khong tai duoc du lieu don hang.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> accept(OrderModel order) async {
    await _perform(() async {
      await _orderService.acceptOrder(order.id);
      await loadAll();
    }, success: 'Da nhan don ${order.code}');
  }

  Future<void> confirmDeliverySchedule() async {
    final schedule = deliverySchedule.value;
    if (schedule.orders.isEmpty) return;

    await _perform(() async {
      await _orderService.confirmDeliverySchedule(
        orderIds: schedule.orders.map((order) => order.id).toList(),
        date: schedule.date,
      );
      await loadAll();
    }, success: 'Da xac nhan lo trinh giao hang');
  }

  Future<void> rejectDeliverySchedule() async {
    final schedule = deliverySchedule.value;
    if (schedule.orders.isEmpty) return;

    final reason = await _askRejectReason();
    if (reason == null || reason.trim().isEmpty) return;

    await _perform(() async {
      await _orderService.rejectDeliverySchedule(
        orderIds: schedule.orders.map((order) => order.id).toList(),
        reason: reason.trim(),
        date: schedule.date,
      );
      await loadAll();
    }, success: 'Da tu choi lo trinh giao hang');
  }

  Future<void> markDelivered(
    OrderModel order, {
    double? collectedAmount,
  }) async {
    await _perform(() async {
      await _orderService.updateStatus(
        orderId: order.id,
        status: 'delivered',
        collectedAmount: collectedAmount,
      );
      await loadAll();
    }, success: 'Da cap nhat don ${order.code}');
  }

  Future<void> markReturning(
    OrderModel order, {
    required int warehouseId,
    required String reason,
    String note = '',
  }) async {
    await _perform(() async {
      await _orderService.returnOrder(
        orderId: order.id,
        warehouseId: warehouseId,
        reason: reason,
        note: note,
      );
      await loadAll();
    }, success: 'Da gui yeu cau tra hang ${order.code}');
  }

  Future<List<WarehouseOption>> warehouses() => _orderService.warehouses();

  Future<void> _perform(
    Future<void> Function() action, {
    required String success,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await action();
      Get.snackbar('Thanh cong', success, snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (error) {
      Get.snackbar('Loi', error.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar(
        'Loi',
        'Thao tac that bai.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> _askRejectReason() async {
    final textController = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Lý do từ chối'),
        content: TextField(
          controller: textController,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do từ chối lộ trình',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<String>(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = textController.text.trim();
              if (value.isEmpty) {
                Get.snackbar(
                  'Thiếu lý do',
                  'Vui lòng nhập lý do từ chối.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              Get.back<String>(result: value);
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    textController.dispose();
    return result;
  }
}
