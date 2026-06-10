import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'app_notification_card.dart';
import 'shipper_account_menu.dart';

class MobileHeaderActions extends StatelessWidget {
  const MobileHeaderActions({
    super.key,
    this.onOpenNotification,
    this.accountMenu = const AccountMenu(),
  });

  final Future<void> Function(AppNotificationItem item)? onOpenNotification;
  final Widget accountMenu;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final workspaces = auth.user.value?.workspaces ?? const <WorkspaceModel>[];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NotificationActionButton(onOpenNotification: onOpenNotification),
        if (workspaces.length > 1)
          IconButton(
            tooltip: 'Chuyển vai trò',
            onPressed: () => _showRoleSwitcher(context),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        accountMenu,
      ],
    );
  }

  Future<void> _showRoleSwitcher(BuildContext context) async {
    final auth = Get.find<AuthController>();
    final user = auth.user.value;
    final workspaces = user?.workspaces ?? const <WorkspaceModel>[];
    if (workspaces.length <= 1) return;

    final selected = await showModalBottomSheet<WorkspaceModel>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chuyển vai trò',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final workspace in workspaces)
                ListTile(
                  leading: Icon(_workspaceIcon(workspace.layout)),
                  title: Text(workspace.label),
                  subtitle: Text(workspace.role),
                  trailing: workspace.layout == user?.layout
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF198754),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(workspace),
                ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected.layout != user?.layout) {
      await auth.switchWorkspace(selected);
    }
  }
}

class _NotificationActionButton extends StatefulWidget {
  const _NotificationActionButton({this.onOpenNotification});

  final Future<void> Function(AppNotificationItem item)? onOpenNotification;

  @override
  State<_NotificationActionButton> createState() =>
      _NotificationActionButtonState();
}

class _NotificationActionButtonState extends State<_NotificationActionButton> {
  late Future<NotificationCenterData> _future;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(_load);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _load() {
    _future = Get.find<NotificationService>().load();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotificationCenterData>(
      future: _future,
      builder: (context, snapshot) {
        final count = snapshot.data?.unreadCount ?? 0;

        return IconButton(
          tooltip: 'Thông báo',
          onPressed: () => _showNotificationCenter(context),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        );
      },
    );
  }

  Future<void> _showNotificationCenter(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, controller) => _NotificationSheet(
          controller: controller,
          onChanged: _refresh,
          onOpenNotification: widget.onOpenNotification,
        ),
      ),
    );
    if (mounted) await _refresh();
  }
}

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet({
    required this.controller,
    required this.onChanged,
    this.onOpenNotification,
  });

  final ScrollController controller;
  final Future<void> Function() onChanged;
  final Future<void> Function(AppNotificationItem item)? onOpenNotification;

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  late Future<NotificationCenterData> _future;

  @override
  void initState() {
    super.initState();
    _future = Get.find<NotificationService>().load();
  }

  Future<void> _reload() async {
    setState(() => _future = Get.find<NotificationService>().load());
    await _future;
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotificationCenterData>(
      future: _future,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            const NotificationCenterData(unreadCount: 0, items: []);

        return ListView(
          controller: widget.controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thông báo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: data.unreadCount == 0
                      ? null
                      : () async {
                          await Get.find<NotificationService>().markAllAsRead();
                          await _reload();
                        },
                  child: const Text('Đánh dấu tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (data.items.isEmpty)
              const _NotificationEmptyState()
            else
              for (final item in data.items) ...[
                AppNotificationCard(
                  item: item,
                  onTap: () async {
                    if (item.isUnread) {
                      await Get.find<NotificationService>().markAsRead(item.id);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                    if (widget.onOpenNotification != null) {
                      await widget.onOpenNotification!(item);
                    }
                    await widget.onChanged();
                  },
                ),
                const SizedBox(height: 6),
              ],
          ],
        );
      },
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 42,
            color: Color(0xFF64748B),
          ),
          SizedBox(height: 12),
          Text(
            'Chưa có thông báo',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Thông báo từ hệ thống sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

IconData _workspaceIcon(String layout) {
  return switch (layout) {
    'warehouse' => Icons.inventory_2_rounded,
    'manager_shipper' => Icons.supervisor_account_rounded,
    'shipper' => Icons.local_shipping_rounded,
    'sale' => Icons.receipt_long_rounded,
    'accounting' => Icons.account_balance_rounded,
    'ceo' => Icons.query_stats_rounded,
    _ => Icons.apps_rounded,
  };
}
