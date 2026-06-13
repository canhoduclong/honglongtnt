import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../services/update_service.dart';

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final user = auth.user.value;
      final title = (user?.name ?? '').trim().isEmpty
          ? 'Tài khoản'
          : user!.name.trim();
      final roleLabel = _roleLabel(user?.layout ?? user?.role ?? '');
      final warehouseName = (user?.warehouseName ?? '').trim();
      final showWarehouse =
          (user?.layout == 'warehouse' || user?.role == 'warehouse') &&
          warehouseName.isNotEmpty;

      return PopupMenuButton<_AccountAction>(
        tooltip: 'Tài khoản',
        onSelected: (action) {
          switch (action) {
            case _AccountAction.profile:
              Get.toNamed(AppRoutes.profile);
            case _AccountAction.update:
              Get.find<UpdateService>().checkForUpdate(manual: true);
            case _AccountAction.logout:
              auth.logout();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: _AccountHeader(
              name: title,
              role: roleLabel,
              warehouseName: showWarehouse ? warehouseName : '',
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _AccountAction.profile,
            child: ListTile(
              leading: Icon(Icons.person_outline_rounded),
              title: Text('Chỉnh sửa profile'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: _AccountAction.update,
            child: ListTile(
              leading: Icon(Icons.system_update_rounded),
              title: Text('Cập nhật ứng dụng'),
              subtitle: Text('Kiểm tra và cập nhật bản mới'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _AccountAction.logout,
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.red),
              title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_rounded),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.name,
    required this.role,
    required this.warehouseName,
  });

  final String name;
  final String role;
  final String warehouseName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: const Icon(Icons.person_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(role, style: const TextStyle(color: Color(0xFF64748B))),
              if (warehouseName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Kho: $warehouseName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _roleLabel(String value) {
  return switch (value) {
    'warehouse' => 'Kho',
    'manager_shipper' => 'Shipper Manager',
    'shipper' => 'Shipper',
    'sale' => 'Sale',
    'accounting' => 'Accounting',
    'ceo' => 'CEO',
    _ => value.isEmpty ? 'Tài khoản' : value,
  };
}

class ShipperAccountMenu extends AccountMenu {
  const ShipperAccountMenu({super.key});
}

enum _AccountAction { profile, update, logout }
