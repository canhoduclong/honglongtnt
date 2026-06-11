import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../role/role_layout.dart';
import '../orders/my_orders_screen.dart';
import 'delivery_schedule_screen.dart';
import 'shipper_home_screen.dart';

class ShipperLayout extends StatefulWidget {
  const ShipperLayout({super.key});

  @override
  State<ShipperLayout> createState() => _ShipperLayoutState();
}

class _ShipperLayoutState extends State<ShipperLayout> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _syncIndexFromArguments();
    Future.microtask(() => Get.find<OrderController>().loadAll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIndexFromArguments();
  }

  void _syncIndexFromArguments() {
    final args = Get.arguments;
    if (args is! Map) return;
    final tab = int.tryParse('${args['tab'] ?? ''}');
    if (tab == null || tab < 0 || tab >= 3 || tab == _index) {
      return;
    }
    setState(() => _index = tab);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final screens = [
      ShipperHomeScreen(onScheduleConfirmed: () => setState(() => _index = 1)),
      const MyOrdersScreen(),
      DeliveryScheduleScreen(onConfirmed: () => setState(() => _index = 1)),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: Obx(() {
        final workspaces = auth.user.value?.workspaces ?? const [];
        if (workspaces.length <= 1) return const SizedBox.shrink();

        return FloatingActionButton.small(
          tooltip: 'Chuyển vai trò',
          onPressed: () => showWorkspaceSwitcher(context),
          child: const Icon(Icons.swap_horiz_rounded),
        );
      }),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '177C Chiến Lược, Bình Trị Đông, Hồ Chí Minh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_shipping_rounded),
                  label: 'Đơn hàng',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_rounded),
                  label: 'Thống kê',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
