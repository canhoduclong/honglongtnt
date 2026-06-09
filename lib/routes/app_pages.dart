import 'package:get/get.dart';

import '../screens/auth/login_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/role/role_layout.dart';
import '../screens/role/unsupported_role_screen.dart';
import '../screens/shipper/shipper_layout.dart';
import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.shipperHome, page: () => const ShipperLayout()),
    GetPage(
      name: AppRoutes.managerShipperHome,
      page: () =>
          const RoleLayout(layout: 'manager_shipper', title: 'Shipper Manager'),
    ),
    GetPage(
      name: AppRoutes.warehouseHome,
      page: () => const RoleLayout(layout: 'warehouse', title: 'Kho'),
    ),
    GetPage(
      name: AppRoutes.packageHome,
      page: () => const RoleLayout(layout: 'package', title: 'Đóng hàng'),
    ),
    GetPage(
      name: AppRoutes.saleHome,
      page: () => const RoleLayout(layout: 'sale', title: 'Sale'),
    ),
    GetPage(
      name: AppRoutes.accountingHome,
      page: () => const RoleLayout(layout: 'accounting', title: 'Accounting'),
    ),
    GetPage(
      name: AppRoutes.ceoHome,
      page: () => const RoleLayout(layout: 'ceo', title: 'CEO'),
    ),
    GetPage(
      name: AppRoutes.unsupported,
      page: () => const UnsupportedRoleScreen(),
    ),
    GetPage(name: AppRoutes.orderDetail, page: () => const OrderDetailScreen()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
  ];
}
