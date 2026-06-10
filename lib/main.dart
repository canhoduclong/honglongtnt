import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'controllers/auth_controller.dart';
import 'controllers/order_controller.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/order_service.dart';
import 'services/notification_service.dart';
import 'services/role_screen_service.dart';
import 'services/sale_service.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  Get.put<StorageService>(storage, permanent: true);
  Get.put<ApiService>(ApiService(storage), permanent: true);
  Get.put<UpdateService>(UpdateService(), permanent: true);
  Get.put<AuthService>(
    AuthService(Get.find<ApiService>(), storage),
    permanent: true,
  );
  Get.put<OrderService>(OrderService(Get.find<ApiService>()), permanent: true);
  Get.put<NotificationService>(
    NotificationService(Get.find<ApiService>()),
    permanent: true,
  );
  Get.put<RoleScreenService>(
    RoleScreenService(Get.find<ApiService>()),
    permanent: true,
  );
  Get.put<SaleService>(SaleService(Get.find<ApiService>()), permanent: true);
  Get.put<AuthController>(
    AuthController(Get.find<AuthService>()),
    permanent: true,
  );
  Get.put<OrderController>(
    OrderController(Get.find<OrderService>()),
    permanent: true,
  );

  runApp(const HoangLongTntApp());
}
