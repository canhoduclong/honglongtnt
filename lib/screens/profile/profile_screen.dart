import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../services/update_service.dart';
import '../../utils/app_config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final updateService = Get.find<UpdateService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: Obx(() {
        final user = auth.user.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .12),
                      child: Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Shipper',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '-',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          if ((user?.phone ?? '').isNotEmpty)
                            Text(
                              user!.phone,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.verified_user_rounded,
                    label: 'Role',
                    value: user?.role ?? '-',
                  ),
                  const Divider(height: 1),
                  _Tile(
                    icon: Icons.view_quilt_rounded,
                    label: 'Layout',
                    value: user?.layout ?? '-',
                  ),
                  if ((user?.warehouseName ?? '').isNotEmpty) ...[
                    const Divider(height: 1),
                    _Tile(
                      icon: Icons.warehouse_rounded,
                      label: 'Kho',
                      value: user!.warehouseName,
                    ),
                  ],
                  const Divider(height: 1),
                  _Tile(
                    icon: Icons.link_rounded,
                    label: 'API',
                    value: AppConfig.baseUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.system_update_rounded),
                    title: const Text('Cập nhật ứng dụng'),
                    subtitle: const Text('Kiểm tra và tải bản APK mới nhất'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => updateService.checkForUpdate(manual: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: auth.isLoading.value ? null : auth.logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
