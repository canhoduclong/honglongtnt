import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../services/role_screen_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_notification_card.dart';
import '../../widgets/shipper_account_menu.dart';
import '../sale/sale_screen.dart';
import '../sale/sale_dashboard_screen.dart';

class RoleLayout extends StatefulWidget {
  const RoleLayout({super.key, required this.layout, required this.title});

  final String layout;
  final String title;

  @override
  State<RoleLayout> createState() => _RoleLayoutState();
}

class _RoleLayoutState extends State<RoleLayout> {
  int _selectedIndex = 0;
  bool _isRefreshingUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserIfMenuMissing();
    });
  }

  @override
  void didUpdateWidget(covariant RoleLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout) {
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshUserIfMenuMissing();
      });
    }
  }

  Future<void> _refreshUserIfMenuMissing() async {
    if (!mounted || _isRefreshingUser) return;
    final auth = Get.find<AuthController>();
    if (_menusForLayout(auth.user.value).isNotEmpty) return;

    setState(() => _isRefreshingUser = true);
    await auth.refreshUser();
    if (!mounted) return;
    setState(() => _isRefreshingUser = false);
  }

  WorkspaceModel? _workspaceForLayout(UserModel? user) {
    if (user == null) return null;
    for (final workspace in user.workspaces) {
      if (workspace.layout == widget.layout) {
        return workspace;
      }
    }
    return null;
  }

  List<MenuItemModel> _menusForLayout(UserModel? user) {
    final workspace = _workspaceForLayout(user);
    final source =
        user?.layout == widget.layout && (user?.menu.isNotEmpty ?? false)
        ? user!.menu
        : (workspace?.menu.isNotEmpty ?? false)
        ? workspace!.menu
        : (user?.menu.isNotEmpty ?? false)
        ? user!.menu
        : const <MenuItemModel>[];

    return source.where((item) => item.api.isNotEmpty).toList();
  }

  void _openNotificationRoute(String routeKey) {
    final key = routeKey.trim();
    if (key.isEmpty) return;

    final auth = Get.find<AuthController>();
    final user = auth.user.value;
    if (user == null) return;

    final currentMenus = _menusForLayout(user);
    final currentIndex = currentMenus.indexWhere((menu) => menu.key == key);
    if (currentIndex >= 0) {
      setState(() => _selectedIndex = currentIndex);
      return;
    }

    WorkspaceModel? target;
    for (final workspace in user.workspaces) {
      if (workspace.menu.any((menu) => menu.key == key)) {
        target = workspace;
        break;
      }
    }

    if (target != null && target.layout != user.layout) {
      Future<void>(() async {
        await auth.switchWorkspace(target!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.user.value;
    final menus = _menusForLayout(user);

    if (menus.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            _NotificationButton(onOpenRoute: _openNotificationRoute),
            if ((user?.workspaces.length ?? 0) > 1)
              IconButton(
                tooltip: 'Chuyển vai trò',
                onPressed: () => showWorkspaceSwitcher(context),
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
            const AccountMenu(),
          ],
        ),
        body: Center(
          child: _isRefreshingUser
              ? const CircularProgressIndicator()
              : const Text('Chưa có menu cho layout này.'),
        ),
      );
    }

    final selected = menus[_selectedIndex.clamp(0, menus.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: Text(selected.label),
        actions: [
          _NotificationButton(onOpenRoute: _openNotificationRoute),
          if ((user?.workspaces.length ?? 0) > 1)
            IconButton(
              tooltip: 'Chuyển vai trò',
              onPressed: () => showWorkspaceSwitcher(context),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          const AccountMenu(),
        ],
      ),
      drawer: _RoleDrawer(
        title: widget.title,
        menus: menus,
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          Navigator.of(context).pop();
          setState(() => _selectedIndex = index);
        },
        onSwitchWorkspace: (user?.workspaces.length ?? 0) > 1
            ? () => showWorkspaceSwitcher(context)
            : null,
      ),
      body: RoleScreen(
        menu: selected,
        onMenuSelected: (key) {
          final index = menus.indexWhere((menu) => menu.key == key);
          if (index >= 0) {
            setState(() => _selectedIndex = index);
          }
        },
      ),
      bottomNavigationBar: menus.length <= 5
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: [
                for (final menu in menus)
                  NavigationDestination(
                    icon: Icon(_icon(menu.icon)),
                    label: menu.label,
                  ),
              ],
            )
          : null,
    );
  }
}

class _NotificationButton extends StatefulWidget {
  const _NotificationButton({required this.onOpenRoute});

  final ValueChanged<String> onOpenRoute;

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
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
          onPressed: () => _showNotifications(context),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        );
      },
    );
  }

  Future<void> _showNotifications(BuildContext context) async {
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
          onOpenRoute: widget.onOpenRoute,
          onChanged: _refresh,
        ),
      ),
    );
    if (mounted) await _refresh();
  }
}

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet({
    required this.controller,
    required this.onOpenRoute,
    required this.onChanged,
  });

  final ScrollController controller;
  final ValueChanged<String> onOpenRoute;
  final Future<void> Function() onChanged;

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
              const _MessageState(
                icon: Icons.notifications_none_rounded,
                title: 'Chưa có thông báo',
                subtitle: 'Thông báo từ hệ thống sẽ hiển thị tại đây.',
              )
            else
              for (final item in data.items) ...[
                AppNotificationCard(
                  item: item,
                  onTap: () async {
                    if (item.isUnread) {
                      await Get.find<NotificationService>().markAsRead(item.id);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                    if (item.routeKey.isNotEmpty) {
                      widget.onOpenRoute(item.routeKey);
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

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key, required this.menu, this.onMenuSelected});

  final MenuItemModel menu;
  final ValueChanged<String>? onMenuSelected;

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  late Future<RoleScreenData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RoleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu.api != widget.menu.api) {
      _load();
    }
  }

  void _load() {
    _future = Get.find<RoleScreenService>().load(widget.menu.api);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.menu.api == '/sale/dashboard') {
      return const SaleDashboardScreen();
    }

    if (widget.menu.api.startsWith('/sale/')) {
      return SaleScreen(menu: widget.menu);
    }

    if (widget.menu.key == 'orders') {
      return WarehouseOrdersScreen(menu: widget.menu);
    }

    if (widget.menu.key == 'dashboard' &&
        widget.menu.api == '/warehouse/dashboard') {
      return WarehouseDashboardScreen(onMenuSelected: widget.onMenuSelected);
    }

    if (widget.menu.key == 'dashboard' &&
        widget.menu.api == '/screens/ceo/dashboard') {
      return CeoDashboardScreen(menu: widget.menu);
    }

    if (widget.menu.api.startsWith('/screens/ceo/') &&
        widget.menu.key != 'dashboard') {
      return CeoReportScreen(menu: widget.menu);
    }

    return FutureBuilder<RoleScreenData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline_rounded,
            title: 'Không tải được dữ liệu',
            subtitle: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data =
            snapshot.data ?? const RoleScreenData(cards: [], items: []);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.cards.isNotEmpty)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    for (final card in data.cards)
                      _MetricCard(label: card.label, value: card.value),
                  ],
                ),
              if (data.cards.isNotEmpty) const SizedBox(height: 16),
              if (widget.menu.key == 'manage_assignments') ...[
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await Get.find<RoleScreenService>()
                          .createDeliverySchedules();
                      await _refresh();
                      Get.snackbar(
                        'Thành công',
                        'Đã gửi lịch trình cho các shipper',
                      );
                    } catch (error) {
                      Get.snackbar('Lỗi', error.toString());
                    }
                  },
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('Hoàn tất và gửi lịch trình'),
                ),
                const SizedBox(height: 16),
              ],
              if (data.items.isEmpty && data.cards.isEmpty)
                const _MessageState(
                  icon: Icons.inbox_rounded,
                  title: 'Chưa có dữ liệu',
                  subtitle:
                      'Dữ liệu sẽ hiển thị theo API của route web tương ứng.',
                )
              else if (data.items.isNotEmpty)
                for (final item in data.items) ...[
                  _RoleListTile(
                    menu: widget.menu,
                    item: item,
                    onChanged: _refresh,
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class CeoReportScreen extends StatefulWidget {
  const CeoReportScreen({super.key, required this.menu});

  final MenuItemModel menu;

  @override
  State<CeoReportScreen> createState() => _CeoReportScreenState();
}

class _CeoReportScreenState extends State<CeoReportScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  late Future<RoleScreenData> _future;
  String _customerSort = 'newest';

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _toDate = today;
    _fromDate = widget.menu.key == 'daily_sales'
        ? today
        : DateTime(today.year, today.month);
    _load();
  }

  @override
  void didUpdateWidget(covariant CeoReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu.api != widget.menu.api) {
      final today = DateUtils.dateOnly(DateTime.now());
      _toDate = today;
      _fromDate = widget.menu.key == 'daily_sales'
          ? today
          : DateTime(today.year, today.month);
      _load();
    }
  }

  String _apiDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  void _load() {
    _future = Get.find<RoleScreenService>().load(
      widget.menu.api,
      query: {
        'from_date': _apiDate(_fromDate),
        'to_date': _apiDate(_toDate),
        if (widget.menu.key == 'customers_list') 'sort': _customerSort,
      },
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: isFrom ? 'Chọn ngày bắt đầu' : 'Chọn ngày kết thúc',
    );
    if (selected == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = selected;
        if (_fromDate.isAfter(_toDate)) _toDate = selected;
      } else {
        _toDate = selected;
        if (_toDate.isBefore(_fromDate)) _fromDate = selected;
      }
      _load();
    });
  }

  bool _isMoneyCard(String label) {
    final normalized = label.toLowerCase();
    return normalized.contains('doanh') ||
        normalized.contains('thu') ||
        normalized.contains('chi') ||
        normalized.contains('dòng tiền') ||
        normalized.contains('lợi nhuận');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RoleScreenData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline_rounded,
            title: 'Không tải được ${widget.menu.label}',
            subtitle: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data =
            snapshot.data ?? const RoleScreenData(cards: [], items: []);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CeoDateButton(
                          label: 'Từ ngày',
                          date: _fromDate,
                          onTap: () => _pickDate(isFrom: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CeoDateButton(
                          label: 'Đến ngày',
                          date: _toDate,
                          onTap: () => _pickDate(isFrom: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.menu.key == 'customers_list') ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _customerSort,
                  decoration: const InputDecoration(
                    labelText: 'Sắp xếp khách hàng',
                    prefixIcon: Icon(Icons.sort_rounded),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('Khách hàng mới nhất'),
                    ),
                    DropdownMenuItem(
                      value: 'debt_desc',
                      child: Text('Công nợ cao nhất'),
                    ),
                    DropdownMenuItem(
                      value: 'sales_desc',
                      child: Text('Doanh số cao nhất'),
                    ),
                    DropdownMenuItem(
                      value: 'name_asc',
                      child: Text('Tên khách hàng A-Z'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _customerSort = value;
                      _load();
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              if (data.cards.isNotEmpty)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    for (final card in data.cards)
                      _CeoReportMetricCard(
                        label: card.label,
                        value: card.value,
                        money: _isMoneyCard(card.label),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              Text(
                widget.menu.key == 'financial_reports'
                    ? 'Theo nhóm giao dịch'
                    : 'Chi tiết gần nhất',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (data.items.isEmpty)
                const _MessageState(
                  icon: Icons.inbox_rounded,
                  title: 'Chưa có dữ liệu',
                  subtitle: 'Hãy chọn một khoảng ngày khác để xem báo cáo.',
                )
              else
                for (final item in data.items) ...[
                  _RoleListTile(
                    menu: widget.menu,
                    item: item,
                    onChanged: _refresh,
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _CeoDateButton extends StatelessWidget {
  const _CeoDateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_rounded),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CeoReportMetricCard extends StatelessWidget {
  const _CeoReportMetricCard({
    required this.label,
    required this.value,
    required this.money,
  });

  final String label;
  final Object value;
  final bool money;

  @override
  Widget build(BuildContext context) {
    final numeric = double.tryParse('$value') ?? 0;
    return Card(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.analytics_outlined, color: Color(0xFF0D7A70)),
            Text(
              money
                  ? Formatters.money(numeric)
                  : Formatters.compactNumber(numeric),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CeoDashboardScreen extends StatefulWidget {
  const CeoDashboardScreen({super.key, required this.menu});

  final MenuItemModel menu;

  @override
  State<CeoDashboardScreen> createState() => _CeoDashboardScreenState();
}

class _CeoDashboardScreenState extends State<CeoDashboardScreen> {
  late Future<RoleScreenData> _future;
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _orderKeys = {};
  final Set<int> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load() {
    _future = Get.find<RoleScreenService>().load(widget.menu.api);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  void _scrollToOrder(int orderId) {
    final context = _orderKeys[orderId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RoleScreenData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline_rounded,
            title: 'Không tải được dashboard CEO',
            subtitle: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data =
            snapshot.data ?? const RoleScreenData(cards: [], items: []);
        final orders =
            data.items.map((item) => OrderModel.fromJson(item.raw)).toList()
              ..sort(
                (a, b) => (a.dailySequence ?? 999999).compareTo(
                  b.dailySequence ?? 999999,
                ),
              );
        for (final order in orders) {
          _orderKeys.putIfAbsent(order.id, GlobalKey.new);
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (data.cards.isNotEmpty)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    for (final card in data.cards)
                      _MetricCard(label: card.label, value: card.value),
                  ],
                ),
              const SizedBox(height: 16),
              if (orders.isNotEmpty) ...[
                _CeoSequenceNavigation(
                  orders: orders,
                  onSelected: _scrollToOrder,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Đơn hàng hôm nay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                for (final order in orders) ...[
                  _CeoQuickOrderCard(
                    key: _orderKeys[order.id],
                    order: order,
                    raw: data.items
                        .firstWhere((item) => item.id == order.id)
                        .raw,
                    expanded: _expandedOrders.contains(order.id),
                    onToggle: () => setState(() {
                      if (!_expandedOrders.add(order.id)) {
                        _expandedOrders.remove(order.id);
                      }
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
              ] else
                const _MessageState(
                  icon: Icons.inbox_rounded,
                  title: 'Chưa có đơn hàng hôm nay',
                  subtitle: 'Danh sách sẽ xuất hiện khi có đơn mới.',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CeoSequenceNavigation extends StatelessWidget {
  const _CeoSequenceNavigation({
    required this.orders,
    required this.onSelected,
  });

  final List<OrderModel> orders;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_list_numbered_rounded, size: 20),
                SizedBox(width: 6),
                Text(
                  'Điều hướng nhanh',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final order in orders) ...[
                    InkWell(
                      onTap: () => onSelected(order.id),
                      borderRadius: BorderRadius.circular(999),
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor: _ceoOrderColor(order.status),
                        foregroundColor: order.status == 'packing'
                            ? const Color(0xFF212529)
                            : Colors.white,
                        child: Text(
                          '${order.dailySequence ?? '—'}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CeoQuickOrderCard extends StatelessWidget {
  const _CeoQuickOrderCard({
    super.key,
    required this.order,
    required this.raw,
    required this.expanded,
    required this.onToggle,
  });

  final OrderModel order;
  final Map<String, dynamic> raw;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final user = raw['user'] is Map ? raw['user'] as Map : const {};
    final team = user['team'] is Map ? user['team'] as Map : const {};
    final rawItems = raw['items'] is List ? raw['items'] as List : const [];
    final color = _ceoOrderColor(order.status);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: order.status == 'packing'
                      ? const Color(0xFF212529)
                      : Colors.white,
                  child: Text(
                    '${order.dailySequence ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customer.name.isEmpty
                            ? order.code
                            : order.customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${order.code} • ${Formatters.dateTime(raw['created_at']?.toString())}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _CeoStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CeoOrderFact(
                    label: 'Giá trị đơn',
                    value: Formatters.money(order.total),
                  ),
                ),
                Expanded(
                  child: _CeoOrderFact(
                    label: 'Sale / Team',
                    value: [user['name'], team['name']]
                        .where((value) => value != null && '$value'.isNotEmpty)
                        .join(' / '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onToggle,
              icon: Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.visibility_outlined,
              ),
              label: Text(expanded ? 'Thu gọn' : 'Xem nhanh'),
            ),
            if (expanded) ...[
              const Divider(height: 24),
              if (rawItems.isEmpty)
                const Text('Không có dữ liệu sản phẩm.')
              else
                for (final item in rawItems) _CeoQuickItem(raw: item),
              if ((order.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Ghi chú: ${order.note}'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CeoOrderFact extends StatelessWidget {
  const _CeoOrderFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _CeoQuickItem extends StatelessWidget {
  const _CeoQuickItem({required this.raw});

  final Object? raw;

  @override
  Widget build(BuildContext context) {
    final item = raw is Map ? raw as Map : const {};
    final product = item['product'] is Map ? item['product'] as Map : const {};
    final variant = item['variant'] is Map ? item['variant'] as Map : const {};
    final quantity = double.tryParse('${item['quantity'] ?? 0}') ?? 0;
    final price = double.tryParse('${item['price'] ?? 0}') ?? 0;
    final quantityLabel = quantity == quantity.roundToDouble()
        ? '${quantity.toInt()}'
        : quantity.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              [product['name'], variant['size']]
                  .where((value) => value != null && '$value'.isNotEmpty)
                  .join(' - '),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text('$quantityLabel × ${Formatters.money(price)}'),
        ],
      ),
    );
  }
}

class _CeoStatusBadge extends StatelessWidget {
  const _CeoStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _ceoOrderColor(status).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _ceoStatusLabel(status),
        style: TextStyle(
          color: _ceoOrderColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _ceoOrderColor(String status) {
  if (status == 'packing') return const Color(0xFFFFC107);
  if (const [
    'packed',
    'packed_waiting_pickup',
    'delivering',
    'delivered',
    'completed',
  ].contains(status)) {
    return const Color(0xFF198754);
  }
  return const Color(0xFF64748B);
}

String _ceoStatusLabel(String status) {
  return switch (status) {
    'packing' => 'Đang đóng',
    'packed' => 'Đã đóng',
    'packed_waiting_pickup' => 'Chờ nhận',
    'delivering' => 'Đang giao',
    'delivered' => 'Đã giao',
    'completed' => 'Hoàn thành',
    'approved' || 'ready_to_pack' => 'Chờ đóng',
    _ => status.replaceAll('_', ' '),
  };
}

class WarehouseDashboardScreen extends StatefulWidget {
  const WarehouseDashboardScreen({super.key, this.onMenuSelected});

  final ValueChanged<String>? onMenuSelected;

  @override
  State<WarehouseDashboardScreen> createState() =>
      _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState extends State<WarehouseDashboardScreen> {
  late Future<WarehouseDashboardData> _future;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(_load);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _load() {
    _future = Get.find<RoleScreenService>().warehouseDashboard();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  void _openMenu(String key) {
    if (key.isEmpty) return;
    widget.onMenuSelected?.call(key);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WarehouseDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline_rounded,
            title: 'Không tải được Dashboard Kho',
            subtitle: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return _MessageState(
            icon: Icons.inbox_rounded,
            title: 'Chưa có dữ liệu',
            subtitle: 'Dashboard Kho sẽ hiển thị dữ liệu từ website.',
            onRetry: _refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _WarehouseSectionTitle(title: 'Tiến độ công việc'),
              const SizedBox(height: 10),
              for (final task in data.tasks) ...[
                _WarehouseTaskRow(task: task, onOpen: _openMenu),
                const SizedBox(height: 12),
              ],
              if (data.receivingAlert.show) ...[
                const SizedBox(height: 4),
                _WarehouseReceivingAlert(
                  alert: data.receivingAlert,
                  onOpen: _openMenu,
                ),
              ],
              const SizedBox(height: 10),
              _WarehouseTaskLegend(items: data.legend),
              const SizedBox(height: 20),
              _WarehouseWorkReport(reminders: data.workReminders),
              const SizedBox(height: 16),
              _WarehouseChangeList(changes: data.changes),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _openMenu('stock_in_create'),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Tạo phiếu nhập kho'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF198754),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _WarehouseSectionTitle(title: 'Thống kê tồn kho'),
              const SizedBox(height: 10),
              _WarehouseInventorySummary(data: data),
              if (data.recentPacked.isNotEmpty) ...[
                const SizedBox(height: 18),
                _WarehouseRecentPackedTable(orders: data.recentPacked),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WarehouseSectionTitle extends StatelessWidget {
  const _WarehouseSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF6B3F19),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 96,
            height: 5,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6B3F19),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseTaskRow extends StatelessWidget {
  const _WarehouseTaskRow({required this.task, required this.onOpen});

  final WarehouseDashboardTask task;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(task.color);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                '${task.sequence}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${task.done}/${task.total}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '${task.percent}%',
              style: const TextStyle(
                color: Color(0xFF0D6EFD),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (task.isDone) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF198754),
                size: 22,
              ),
            ],
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => onOpen(task.routeKey),
              child: const Text('Chi tiết'),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: task.percent.clamp(0, 100) / 100,
            minHeight: 18,
            color: color,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _WarehouseReceivingAlert extends StatelessWidget {
  const _WarehouseReceivingAlert({required this.alert, required this.onOpen});

  final WarehouseDashboardAlert alert;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1AEB5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB02A37)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                color: Color(0xFF842029),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => onOpen(alert.routeKey),
            child: const Text('Xem chi tiết'),
          ),
        ],
      ),
    );
  }
}

class _WarehouseTaskLegend extends StatelessWidget {
  const _WarehouseTaskLegend({required this.items});

  final List<WarehouseDashboardLegend> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _colorFromHex(item.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(item.label, style: const TextStyle(fontSize: 13)),
            ],
          ),
      ],
    );
  }
}

class _WarehouseWorkReport extends StatelessWidget {
  const _WarehouseWorkReport({required this.reminders});

  final List<WarehouseDashboardReminder> reminders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reminders.isEmpty)
          const Text(
            'Chưa có việc được giao',
            style: TextStyle(
              color: Color(0xFF198754),
              fontWeight: FontWeight.w800,
            ),
          )
        else
          for (final reminder in reminders)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: reminder.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: ' hoàn thiện ${reminder.percent}%',
                      style: const TextStyle(color: Color(0xFF0D6EFD)),
                    ),
                    TextSpan(
                      text: ' - ${reminder.message}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _WarehouseChangeList extends StatelessWidget {
  const _WarehouseChangeList({required this.changes});

  final List<WarehouseDashboardChange> changes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final change in changes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  _changeIcon(change.icon),
                  color: _colorFromHex(change.color),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(change.label)),
                _SmallBadge(
                  label: change.badge,
                  color: _colorFromHex(change.badgeColor),
                  darkText:
                      change.badgeColor.toLowerCase() == '#ffc107' ||
                      change.badgeColor.toLowerCase() == '#0dcaf0',
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WarehouseInventorySummary extends StatefulWidget {
  const _WarehouseInventorySummary({required this.data});

  final WarehouseDashboardData data;

  @override
  State<_WarehouseInventorySummary> createState() =>
      _WarehouseInventorySummaryState();
}

class _WarehouseInventorySummaryState
    extends State<_WarehouseInventorySummary> {
  final _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    final rows = widget.data.inventoryRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.data.inventoryTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 720,
            child: Column(
              children: [
                const _InventoryHeaderRow(),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Không có dữ liệu sản phẩm trong danh sách hiện tại.',
                    ),
                  )
                else
                  for (final row in rows) ...[
                    _InventoryProductRow(
                      row: row,
                      expanded: _expanded.contains(row.productId),
                      onToggle: () {
                        setState(() {
                          if (!_expanded.add(row.productId)) {
                            _expanded.remove(row.productId);
                          }
                        });
                      },
                    ),
                    if (_expanded.contains(row.productId))
                      for (final variant in row.variants)
                        _InventoryVariantRow(variant: variant),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InventoryHeaderRow extends StatelessWidget {
  const _InventoryHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6B3F19),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: const Row(
        children: [
          _InventoryCell('Tên sản phẩm / biến thể', flex: 4, header: true),
          _InventoryCell('DVT', header: true),
          _InventoryCell('Tồn đầu', header: true),
          _InventoryCell('Nhập', header: true),
          _InventoryCell('Book', header: true),
          _InventoryCell('Xuất', header: true),
          _InventoryCell('Tồn cuối', header: true),
        ],
      ),
    );
  }
}

class _InventoryProductRow extends StatelessWidget {
  const _InventoryProductRow({
    required this.row,
    required this.expanded,
    required this.onToggle,
  });

  final WarehouseInventorySummaryRow row;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBE7),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      expanded ? '-' : '+',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        row.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _InventoryCell(row.unit),
          _InventoryCell(_compactNumber(row.opening), bold: true),
          _InventoryCell(_compactNumber(row.imported)),
          _InventoryCell(
            _compactNumber(row.reserved),
            color: Color(0xFF1D4ED8),
          ),
          _InventoryCell(_compactNumber(row.exported)),
          _InventoryCell(_compactNumber(row.closing)),
        ],
      ),
    );
  }
}

class _InventoryVariantRow extends StatelessWidget {
  const _InventoryVariantRow({required this.variant});

  final WarehouseInventorySummaryVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCFCFD),
      child: Row(
        children: [
          _InventoryCell('   ${variant.name}', flex: 4),
          _InventoryCell(variant.unit),
          _InventoryCell(_compactNumber(variant.opening)),
          _InventoryCell(_compactNumber(variant.imported)),
          _InventoryCell(
            _compactNumber(variant.reserved),
            color: Color(0xFF1D4ED8),
          ),
          _InventoryCell(_compactNumber(variant.exported)),
          _InventoryCell(_compactNumber(variant.closing)),
        ],
      ),
    );
  }
}

class _InventoryCell extends StatelessWidget {
  const _InventoryCell(
    this.value, {
    this.flex = 1,
    this.header = false,
    this.bold = false,
    this.color,
  });

  final String value;
  final int flex;
  final bool header;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: header ? Colors.white : color,
            fontWeight: header || bold ? FontWeight.w900 : FontWeight.w500,
            fontSize: header ? 12 : 13,
          ),
        ),
      ),
    );
  }
}

class _WarehouseRecentPackedTable extends StatelessWidget {
  const _WarehouseRecentPackedTable({required this.orders});

  final List<WarehouseRecentPackedOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text(
                  'Đơn đóng xong gần đây theo ngày đã chọn',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Mã đơn')),
                DataColumn(label: Text('Khách hàng')),
                DataColumn(label: Text('Tổng tiền')),
                DataColumn(label: Text('Cập nhật lúc')),
              ],
              rows: [
                for (final order in orders)
                  DataRow(
                    cells: [
                      DataCell(Text('${order.sequence}')),
                      DataCell(Text(order.code)),
                      DataCell(Text(order.customerName)),
                      DataCell(Text(Formatters.money(order.total))),
                      DataCell(Text(order.updatedTime)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.color,
    this.darkText = false,
  });

  final String label;
  final Color color;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: darkText ? const Color(0xFF111827) : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class WarehouseOrdersScreen extends StatefulWidget {
  const WarehouseOrdersScreen({super.key, required this.menu});

  final MenuItemModel menu;

  @override
  State<WarehouseOrdersScreen> createState() => _WarehouseOrdersScreenState();
}

class _WarehouseOrdersScreenState extends State<WarehouseOrdersScreen> {
  final _scrollController = ScrollController();
  late Future<RoleScreenData> _future;
  final _keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WarehouseOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu.api != widget.menu.api) {
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load() {
    _future = Get.find<RoleScreenService>().load('/warehouse/orders');
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  void _jumpTo(int orderId) {
    final context = _keys[orderId]?.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RoleScreenData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline_rounded,
            title: 'Không tải được dữ liệu',
            subtitle: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final orders =
            (snapshot.data?.items ?? const <RoleListItemData>[])
                .map(WarehouseOrderData.fromItem)
                .toList()
              ..sort((a, b) {
                final seq = a.sequence.compareTo(b.sequence);
                if (seq != 0) return seq;
                return a.id.compareTo(b.id);
              });

        _keys
          ..clear()
          ..addEntries(orders.map((order) => MapEntry(order.id, GlobalKey())));

        if (orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _MessageState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Không có đơn nào cần xử lý',
                  subtitle: 'Danh sách đơn cần đóng gói sẽ hiển thị tại đây.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _WarehouseOrderSummary(orders: orders)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PriorityNavHeaderDelegate(
                  orders: orders,
                  onSelected: _jumpTo,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return KeyedSubtree(
                      key: _keys[order.id],
                      child: WarehouseOrderCard(
                        order: order,
                        onChanged: _refresh,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WarehouseOrderSummary extends StatelessWidget {
  const _WarehouseOrderSummary({required this.orders});

  final List<WarehouseOrderData> orders;

  @override
  Widget build(BuildContext context) {
    final waiting = orders
        .where((order) => order.priorityState == 'unpacked')
        .length;
    final packing = orders
        .where((order) => order.priorityState == 'packing')
        .length;
    final packed = orders
        .where((order) => order.priorityState == 'packed')
        .length;
    final rejected = orders
        .where((order) => order.adjustmentStatus == 'sale_rejected')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryChip(
            label: 'Tổng đơn',
            count: orders.length,
            color: const Color(0xFF111827),
          ),
          _SummaryChip(
            label: 'Chờ đóng gói',
            count: waiting,
            color: const Color(0xFF64748B),
          ),
          _SummaryChip(
            label: 'Đang đóng',
            count: packing,
            color: const Color(0xFFF59E0B),
            darkText: true,
          ),
          _SummaryChip(
            label: 'Đã đóng',
            count: packed,
            color: const Color(0xFF16A34A),
          ),
          if (rejected > 0)
            _SummaryChip(
              label: 'Sale từ chối',
              count: rejected,
              color: const Color(0xFFDC2626),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    this.darkText = false,
  });

  final String label;
  final int count;
  final Color color;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color,
      side: BorderSide.none,
      label: Text(
        '$label: $count',
        style: TextStyle(
          color: darkText ? const Color(0xFF111827) : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PriorityNavHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PriorityNavHeaderDelegate({
    required this.orders,
    required this.onSelected,
  });

  final List<WarehouseOrderData> orders;
  final ValueChanged<int> onSelected;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: const Color(0xFFF6F8FB),
      elevation: overlapsContent ? 1 : 0,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: orders.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Center(
              child: Text(
                'Điều hướng nhanh:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }

          final order = orders[index - 1];
          return InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => onSelected(order.id),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _priorityColor(order.priorityState),
                shape: BoxShape.circle,
              ),
              child: Text(
                order.sequenceLabel,
                style: TextStyle(
                  color: order.priorityState == 'packing'
                      ? const Color(0xFF111827)
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PriorityNavHeaderDelegate oldDelegate) {
    return oldDelegate.orders != orders;
  }
}

class WarehouseOrderCard extends StatelessWidget {
  const WarehouseOrderCard({
    super.key,
    required this.order,
    required this.onChanged,
  });

  final WarehouseOrderData order;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _PriorityCircle(order: order, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '#${order.sequenceLabel}, ${Formatters.dateTime(order.createdAt)}, ${order.code}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                _StatusPill(order: order),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderInfoLine(
                  icon: Icons.place_rounded,
                  text: order.address.isEmpty
                      ? 'Chưa có địa chỉ'
                      : order.address,
                ),
                const SizedBox(height: 6),
                _OrderInfoLine(
                  icon: Icons.schedule_rounded,
                  text:
                      'Giờ giao: ${order.deliveryTime.isEmpty ? 'Chưa cập nhật' : order.deliveryTime}',
                ),
                if (order.adjustmentStatus == 'pending_sale_confirmation') ...[
                  const SizedBox(height: 10),
                  _OrderAlert(
                    color: const Color(0xFFF59E0B),
                    title: 'Đang chờ sale xác nhận thay đổi đơn',
                    subtitle: order.adjustmentNote,
                  ),
                ],
                if (order.adjustmentStatus == 'sale_rejected') ...[
                  const SizedBox(height: 10),
                  _OrderAlert(
                    color: const Color(0xFFDC2626),
                    title: 'Sale đã từ chối yêu cầu điều chỉnh',
                    subtitle: order.adjustmentRejectedReason,
                  ),
                ],
                const SizedBox(height: 12),
                _OrderItemsTable(order: order, onChanged: onChanged),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _WarehouseOrderActions(order: order, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _PriorityCircle extends StatelessWidget {
  const _PriorityCircle({required this.order, required this.size});

  final WarehouseOrderData order;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _priorityColor(order.priorityState),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _priorityColor(order.priorityState).withValues(alpha: .24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        order.sequenceLabel,
        style: TextStyle(
          color: order.priorityState == 'packing'
              ? const Color(0xFF111827)
              : Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.order});

  final WarehouseOrderData order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _priorityColor(order.priorityState).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _priorityColor(order.priorityState).withValues(alpha: .25),
        ),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: order.priorityState == 'packing'
              ? const Color(0xFF92400E)
              : _priorityColor(order.priorityState),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrderInfoLine extends StatelessWidget {
  const _OrderInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderAlert extends StatelessWidget {
  const _OrderAlert({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }
}

class _OrderItemsTable extends StatefulWidget {
  const _OrderItemsTable({required this.order, required this.onChanged});

  final WarehouseOrderData order;
  final Future<void> Function() onChanged;

  @override
  State<_OrderItemsTable> createState() => _OrderItemsTableState();
}

class _OrderItemsTableState extends State<_OrderItemsTable> {
  final _weightControllers = <int, TextEditingController>{};
  final _savedWeights = <int, String>{};
  late final TextEditingController _shippingController;
  late final TextEditingController _foamController;
  late String _savedShippingFee;
  late String _savedFoamBoxPrice;
  late bool _chargeShippingFee;
  late bool _chargeFoamBoxFee;
  late bool _savedChargeShippingFee;
  late bool _savedChargeFoamBoxFee;
  bool _savingShippingFee = false;
  bool _savingFoamBoxFee = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      final text = _numberInput(item.actualWeight);
      _weightControllers[item.id] = TextEditingController(text: text);
      _savedWeights[item.id] = text;
    }
    _shippingController = TextEditingController(
      text: _numberInput(widget.order.shippingFee),
    );
    _foamController = TextEditingController(
      text: _numberInput(widget.order.foamBoxPrice),
    );
    _savedShippingFee = _shippingController.text;
    _savedFoamBoxPrice = _foamController.text;
    _chargeShippingFee = widget.order.chargeShippingFee;
    _chargeFoamBoxFee = widget.order.chargeFoamBoxFee;
    _savedChargeShippingFee = _chargeShippingFee;
    _savedChargeFoamBoxFee = _chargeFoamBoxFee;
  }

  @override
  void dispose() {
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    _shippingController.dispose();
    _foamController.dispose();
    super.dispose();
  }

  String _numberInput(double? value) =>
      value == null ? '' : _compactNumber(value);

  SaveState _stateFor(String current, String saved) {
    if (current.trim().isEmpty) return SaveState.empty;
    if (current.trim() != saved.trim()) return SaveState.dirty;
    return SaveState.saved;
  }

  @override
  Widget build(BuildContext context) {
    final shippingState = _feeState(
      current: _shippingController.text,
      saved: _savedShippingFee,
      currentToggle: _chargeShippingFee,
      savedToggle: _savedChargeShippingFee,
    );
    final foamState = _feeState(
      current: _foamController.text,
      saved: _savedFoamBoxPrice,
      currentToggle: _chargeFoamBoxFee,
      savedToggle: _savedChargeFoamBoxFee,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in widget.order.items) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (item.sku.isNotEmpty || item.size.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (item.sku.isNotEmpty) item.sku,
                        if (item.size.isNotEmpty) 'Size ${item.size}',
                      ].join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ItemMetric(
                      label: 'Số lượng',
                      value: _compactNumber(item.quantity),
                    ),
                    _ItemMetric(
                      label: 'Định lượng',
                      value: item.weightLabel.isEmpty ? '—' : item.weightLabel,
                    ),
                    _ItemMetric(
                      label: 'Thành tiền',
                      value: item.displayTotal.isEmpty
                          ? Formatters.money(item.lineTotal ?? 0)
                          : item.displayTotal,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SaveInputRow(
                  controller: _weightControllers[item.id]!,
                  label: 'Kg thực tế',
                  suffix: 'kg',
                  state: _stateFor(
                    _weightControllers[item.id]!.text,
                    _savedWeights[item.id] ?? '',
                  ),
                  onChanged: () => setState(() {}),
                  onSave: () => _saveItemWeight(item),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Tính phí ship',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                value: _chargeShippingFee,
                onChanged: (value) =>
                    setState(() => _chargeShippingFee = value),
              ),
              _SaveInputRow(
                controller: _shippingController,
                label: 'Phí ship',
                state: shippingState,
                onChanged: () => setState(() {}),
                onSave: _saveShippingFee,
                isSaving: _savingShippingFee,
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Tính phí thùng xốp',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                value: _chargeFoamBoxFee,
                onChanged: (value) => setState(() => _chargeFoamBoxFee = value),
              ),
              _SaveInputRow(
                controller: _foamController,
                label: 'Phí thùng xốp',
                state: foamState,
                onChanged: () => setState(() {}),
                onSave: _saveFoamBoxFee,
                isSaving: _savingFoamBoxFee,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveItemWeight(WarehouseOrderItemData item) async {
    final controller = _weightControllers[item.id]!;
    final value = double.tryParse(controller.text.trim());
    if (value == null || value < 0) {
      Get.snackbar('Dữ liệu chưa đúng', 'Vui lòng nhập kg thực tế hợp lệ.');
      return;
    }

    await Get.find<RoleScreenService>().updateOrderItemWeight(
      orderId: widget.order.id,
      itemId: item.id,
      actualWeight: value,
    );
    setState(() => _savedWeights[item.id] = controller.text.trim());
    await widget.onChanged();
    Get.snackbar('Đã lưu', 'Đã lưu kg thực tế.');
  }

  Future<void> _saveShippingFee() async {
    final shipping = double.tryParse(
      _shippingController.text.trim().isEmpty
          ? '0'
          : _shippingController.text.trim(),
    );
    if (shipping == null || shipping < 0) {
      Get.snackbar('Dữ liệu chưa đúng', 'Vui lòng nhập phí ship hợp lệ.');
      return;
    }

    setState(() => _savingShippingFee = true);
    try {
      await Get.find<RoleScreenService>().updateOrderShippingFee(
        orderId: widget.order.id,
        chargeShippingFee: _chargeShippingFee,
        shippingFee: shipping,
      );
      setState(() {
        _savedShippingFee = _shippingController.text.trim();
        _savedChargeShippingFee = _chargeShippingFee;
      });
      await widget.onChanged();
      Get.snackbar('Đã lưu', 'Đã lưu phí ship.');
    } finally {
      if (mounted) setState(() => _savingShippingFee = false);
    }
  }

  Future<void> _saveFoamBoxFee() async {
    final foam = double.tryParse(
      _foamController.text.trim().isEmpty ? '0' : _foamController.text.trim(),
    );
    if (foam == null || foam < 0) {
      Get.snackbar('Dữ liệu chưa đúng', 'Vui lòng nhập phí thùng xốp hợp lệ.');
      return;
    }

    setState(() => _savingFoamBoxFee = true);
    try {
      await Get.find<RoleScreenService>().updateOrderFoamBoxFee(
        orderId: widget.order.id,
        chargeFoamBoxFee: _chargeFoamBoxFee,
        foamBoxPrice: foam,
      );
      setState(() {
        _savedFoamBoxPrice = _foamController.text.trim();
        _savedChargeFoamBoxFee = _chargeFoamBoxFee;
      });
      await widget.onChanged();
      Get.snackbar('Đã lưu', 'Đã lưu phí thùng xốp.');
    } finally {
      if (mounted) setState(() => _savingFoamBoxFee = false);
    }
  }

  SaveState _feeState({
    required String current,
    required String saved,
    required bool currentToggle,
    required bool savedToggle,
  }) {
    if (current.trim().isEmpty && !currentToggle) return SaveState.empty;
    if (currentToggle != savedToggle || current.trim() != saved.trim()) {
      return SaveState.dirty;
    }
    return current.trim().isEmpty ? SaveState.empty : SaveState.saved;
  }
}

enum SaveState { empty, dirty, saved }

class _SaveInputRow extends StatelessWidget {
  const _SaveInputRow({
    required this.controller,
    required this.label,
    required this.state,
    required this.onChanged,
    required this.onSave,
    this.suffix = '',
    this.isSaving = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool isSaving;
  final SaveState state;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      SaveState.empty => const Color(0xFF64748B),
      SaveState.dirty => const Color(0xFFF59E0B),
      SaveState.saved => const Color(0xFF16A34A),
    };
    final statusText = switch (state) {
      SaveState.empty => 'Chưa nhập',
      SaveState.dirty => 'Chưa lưu',
      SaveState.saved => 'Đã lưu ✓',
    };

    return Row(
      children: [
        Expanded(
          child: TextField(
            enabled: !isSaving,
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: label,
              suffixText: suffix.isEmpty ? null : suffix,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 86,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Lưu',
          onPressed: !isSaving && state == SaveState.dirty ? onSave : null,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
        ),
      ],
    );
  }
}

class _ItemMetric extends StatelessWidget {
  const _ItemMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _WarehouseOrderActions extends StatelessWidget {
  const _WarehouseOrderActions({required this.order, required this.onChanged});

  final WarehouseOrderData order;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final service = Get.find<RoleScreenService>();

    if (order.canStartPacking) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showAdjustmentDialog(context),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Điều chỉnh mặt hàng'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              await _perform(
                () => service.startPacking(order.id),
                'Đã bắt đầu đóng hàng #${order.sequenceLabel}',
              );
            },
            icon: const Icon(Icons.inventory_2_rounded),
            label: const Text('Đóng hàng'),
          ),
        ],
      );
    }

    if (order.canCompletePacking) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.canUndoStartPacking) ...[
            OutlinedButton.icon(
              onPressed: () async {
                await _perform(
                  () => service.undoStartPacking(order.id),
                  'Đã Undo nhận đơn #${order.sequenceLabel}',
                );
              },
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Undo nhận đơn'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: () async {
              await _perform(
                () => service.completePacking(order.id),
                'Đã hoàn thành đóng gói #${order.sequenceLabel}',
              );
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Hoàn thành đóng gói'),
          ),
        ],
      );
    }

    if (order.adjustmentStatus == 'pending_sale_confirmation') {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top_rounded),
        label: const Text('Đang chờ sale xác nhận thay đổi đơn'),
      );
    }

    if (order.adjustmentStatus == 'sale_rejected') {
      return OutlinedButton.icon(
        onPressed: () => _showAdjustmentDialog(context),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Gửi lại yêu cầu điều chỉnh'),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _perform(Future<void> Function() action, String success) async {
    try {
      await action();
      await onChanged();
      Get.snackbar('Thành công', success, snackPosition: SnackPosition.BOTTOM);
    } catch (error) {
      Get.snackbar(
        'Lỗi',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showAdjustmentDialog(BuildContext context) async {
    final service = Get.find<RoleScreenService>();
    final productOptions = await service.warehouseProducts();
    if (!context.mounted) return;
    final reasonController = TextEditingController(text: order.adjustmentNote);
    final quantityControllers = {
      for (final item in order.items)
        item.id: TextEditingController(text: item.quantity.round().toString()),
    };
    final newItemQuantities = <int, int>{};
    final newQuantityController = TextEditingController(text: '1');
    int? selectedVariantId = productOptions.isEmpty
        ? null
        : productOptions.first.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Điều chỉnh mặt hàng'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Đặt số lượng = 0 để xóa sản phẩm khỏi đơn.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  for (final item in order.items) ...[
                    Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: quantityControllers[item.id],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số lượng mới',
                        helperText: item.sku.isEmpty ? null : item.sku,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (productOptions.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Thêm sản phẩm mới vào đơn',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedVariantId,
                      isExpanded: true,
                      items: [
                        for (final option in productOptions.take(50))
                          DropdownMenuItem<int>(
                            value: option.id,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedVariantId = value),
                      decoration: const InputDecoration(labelText: 'Sản phẩm'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: selectedVariantId == null
                              ? null
                              : () {
                                  final qty =
                                      int.tryParse(
                                        newQuantityController.text.trim(),
                                      ) ??
                                      0;
                                  if (qty <= 0) return;
                                  setDialogState(() {
                                    newItemQuantities[selectedVariantId!] =
                                        (newItemQuantities[selectedVariantId!] ??
                                            0) +
                                        qty;
                                  });
                                },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm'),
                        ),
                      ],
                    ),
                    if (newItemQuantities.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final entry in newItemQuantities.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${productOptions.firstWhere((item) => item.id == entry.key).label}: +${entry.value}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Lý do thay đổi',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Gửi sale xác nhận'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      for (final controller in quantityControllers.values) {
        controller.dispose();
      }
      newQuantityController.dispose();
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    final quantities = {
      for (final entry in quantityControllers.entries)
        entry.key: int.tryParse(entry.value.text.trim()) ?? 0,
    };

    for (final controller in quantityControllers.values) {
      controller.dispose();
    }
    newQuantityController.dispose();
    reasonController.dispose();

    if (reason.isEmpty) {
      Get.snackbar('Thiếu lý do', 'Vui lòng nhập lý do thay đổi.');
      return;
    }

    await _perform(
      () => Get.find<RoleScreenService>().requestWarehouseAdjustment(
        orderId: order.id,
        reason: reason,
        itemQuantities: quantities,
        newItemQuantities: newItemQuantities,
      ),
      'Đã gửi yêu cầu điều chỉnh cho sale',
    );
  }
}

class WarehouseOrderData {
  const WarehouseOrderData({
    required this.id,
    required this.code,
    required this.sequence,
    required this.status,
    required this.statusLabel,
    required this.priorityState,
    required this.customerName,
    required this.address,
    required this.deliveryTime,
    required this.createdAt,
    required this.adjustmentStatus,
    required this.adjustmentNote,
    required this.adjustmentRejectedReason,
    required this.shippingFee,
    required this.foamBoxPrice,
    required this.chargeShippingFee,
    required this.chargeFoamBoxFee,
    required this.canStartPacking,
    required this.canCompletePacking,
    required this.canUndoStartPacking,
    required this.items,
  });

  final int id;
  final String code;
  final int sequence;
  final String status;
  final String statusLabel;
  final String priorityState;
  final String customerName;
  final String address;
  final String deliveryTime;
  final String createdAt;
  final String adjustmentStatus;
  final String adjustmentNote;
  final String adjustmentRejectedReason;
  final double? shippingFee;
  final double? foamBoxPrice;
  final bool chargeShippingFee;
  final bool chargeFoamBoxFee;
  final bool canStartPacking;
  final bool canCompletePacking;
  final bool canUndoStartPacking;
  final List<WarehouseOrderItemData> items;

  String get sequenceLabel => sequence > 0 ? '$sequence' : '—';

  factory WarehouseOrderData.fromItem(RoleListItemData item) {
    final raw = item.raw;
    final customer = raw['customer'] is Map ? raw['customer'] as Map : const {};
    final items = (raw['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(WarehouseOrderItemData.fromJson)
        .toList();

    return WarehouseOrderData(
      id: item.id,
      code: (raw['code'] ?? item.title).toString(),
      sequence: int.tryParse('${raw['daily_sequence'] ?? 0}') ?? 0,
      status: (raw['status'] ?? '').toString(),
      statusLabel: (raw['status_label'] ?? raw['status'] ?? '').toString(),
      priorityState: (raw['priority_state'] ?? 'unpacked').toString(),
      customerName: (customer['name'] ?? item.subtitle).toString(),
      address: (raw['shipping_address'] ?? customer['address'] ?? '')
          .toString(),
      deliveryTime: (raw['delivery_time'] ?? '').toString(),
      createdAt: (raw['created_at'] ?? '').toString(),
      adjustmentStatus: (raw['warehouse_adjustment_status'] ?? '').toString(),
      adjustmentNote: (raw['warehouse_adjustment_note'] ?? '').toString(),
      adjustmentRejectedReason:
          (raw['warehouse_adjustment_rejected_reason'] ?? '').toString(),
      shippingFee: raw['shipping_fee'] == null
          ? null
          : double.tryParse('${raw['shipping_fee']}'),
      foamBoxPrice: raw['foam_box_price'] == null
          ? null
          : double.tryParse('${raw['foam_box_price']}'),
      chargeShippingFee: raw['charge_shipping_fee'] != false,
      chargeFoamBoxFee: raw['charge_foam_box_fee'] == true,
      canStartPacking: raw['can_start_packing'] == true,
      canCompletePacking: raw['can_complete_packing'] == true,
      canUndoStartPacking: raw['can_undo_start_packing'] == true,
      items: items,
    );
  }
}

class WarehouseOrderItemData {
  const WarehouseOrderItemData({
    required this.id,
    required this.productName,
    required this.sku,
    required this.size,
    required this.quantity,
    required this.displayTotal,
    required this.weightLabel,
    required this.actualWeight,
    required this.isPricedByKg,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final String productName;
  final String sku;
  final String size;
  final double quantity;
  final String displayTotal;
  final String weightLabel;
  final double? actualWeight;
  final bool isPricedByKg;
  final double unitPrice;
  final double? lineTotal;

  factory WarehouseOrderItemData.fromJson(Map<String, dynamic> json) {
    return WarehouseOrderItemData(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      productName: (json['product_name'] ?? 'Sản phẩm').toString(),
      sku: (json['sku'] ?? '').toString(),
      size: (json['size'] ?? '').toString(),
      quantity: double.tryParse('${json['quantity'] ?? 0}') ?? 0,
      displayTotal: (json['display_total'] ?? '').toString(),
      weightLabel: (json['weight_label'] ?? '').toString(),
      actualWeight: json['actual_weight'] == null
          ? null
          : double.tryParse('${json['actual_weight']}'),
      isPricedByKg: json['is_priced_by_kg'] == true,
      unitPrice: double.tryParse('${json['unit_price'] ?? 0}') ?? 0,
      lineTotal: json['line_total'] == null
          ? null
          : double.tryParse('${json['line_total']}'),
    );
  }
}

Color _colorFromHex(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFF64748B);
}

IconData _changeIcon(String name) {
  return switch (name) {
    'edit' => Icons.edit_note_rounded,
    'chat' => Icons.chat_bubble_outline_rounded,
    'truck' => Icons.local_shipping_rounded,
    _ => Icons.notifications_active_outlined,
  };
}

Color _priorityColor(String state) {
  return switch (state) {
    'packing' => const Color(0xFFF59E0B),
    'packed' => const Color(0xFF16A34A),
    _ => const Color(0xFF64748B),
  };
}

String _compactNumber(num value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.001) return rounded.toInt().toString();
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

class _RoleDrawer extends StatelessWidget {
  const _RoleDrawer({
    required this.title,
    required this.menus,
    required this.selectedIndex,
    required this.onSelected,
    this.onSwitchWorkspace,
  });

  final String title;
  final List<MenuItemModel> menus;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onSwitchWorkspace;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 16, 12),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      if (onSwitchWorkspace != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: OutlinedButton.icon(
            onPressed: onSwitchWorkspace,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Chuyển vai trò'),
          ),
        ),
    ];

    String currentGroup = '';
    for (final menu in menus) {
      if (menu.group.isNotEmpty && menu.group != currentGroup) {
        currentGroup = menu.group;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 16, 6),
            child: Text(
              currentGroup,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }

      children.add(
        NavigationDrawerDestination(
          icon: Icon(_icon(menu.icon)),
          label: Text(menu.label),
        ),
      );
    }

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      children: children,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    final numeric = double.tryParse('$value');
    final text = numeric == null ? '$value' : Formatters.compactNumber(numeric);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.insights_rounded, color: Color(0xFF0D7A70)),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleListTile extends StatelessWidget {
  const _RoleListTile({
    required this.menu,
    required this.item,
    required this.onChanged,
  });

  final MenuItemModel menu;
  final RoleListItemData item;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => _showDetail(context),
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_rounded)),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            if (item.subtitle.isNotEmpty) item.subtitle,
            if (item.status.isNotEmpty) item.status,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: item.amount > 0
            ? Text(
                Formatters.money(item.amount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              )
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final actions = _actions(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
            if (actions.isNotEmpty) ...[const SizedBox(height: 16), ...actions],
            const SizedBox(height: 16),
            for (final entry in item.raw.entries)
              if (_displayValue(entry.value).isNotEmpty)
                _InfoLine(
                  label: entry.key.replaceAll('_', ' '),
                  value: _displayValue(entry.value),
                ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    if (menu.key == 'manage_assignments') {
      return _managerAssignmentActions(context);
    }
    if (menu.key == 'returns') {
      return _returnActions(context);
    }
    if (menu.key != 'orders') return const [];
    final status = item.status;
    final service = Get.find<RoleScreenService>();

    if (status == 'approved' || status == 'ready_to_pack') {
      return [
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await service.startPacking(item.id);
              await onChanged();
              Get.snackbar('Thành công', 'Đã bắt đầu đóng gói');
            } catch (error) {
              Get.snackbar('Lỗi', error.toString());
            }
          },
          icon: const Icon(Icons.play_circle_rounded),
          label: const Text('Bắt đầu đóng gói'),
        ),
      ];
    }

    if (status == 'packing') {
      return [
        if (item.raw['can_undo_start_packing'] == true)
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await service.undoStartPacking(item.id);
                await onChanged();
                Get.snackbar('Thành công', 'Đã Undo nhận đơn');
              } catch (error) {
                Get.snackbar('Lỗi', error.toString());
              }
            },
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Undo nhận đơn'),
          ),
        if (item.raw['can_undo_start_packing'] == true)
          const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await service.completePacking(item.id);
              await onChanged();
              Get.snackbar('Thành công', 'Đã hoàn tất đóng gói');
            } catch (error) {
              Get.snackbar('Lỗi', error.toString());
            }
          },
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Hoàn tất đóng gói'),
        ),
      ];
    }

    return const [];
  }

  List<Widget> _managerAssignmentActions(BuildContext context) {
    final shippers = (item.raw['available_shippers'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final assignedId = int.tryParse('${item.raw['shipper_id'] ?? ''}');

    return [
      if (assignedId != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Đang giao cho: ${item.raw['shipper_name'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      FilledButton.icon(
        onPressed: shippers.isEmpty
            ? null
            : () async {
                final selected = await showDialog<int>(
                  context: context,
                  builder: (dialogContext) => SimpleDialog(
                    title: const Text('Chọn shipper'),
                    children: [
                      for (final shipper in shippers)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(
                            dialogContext,
                            int.tryParse('${shipper['id']}'),
                          ),
                          child: Text((shipper['name'] ?? '').toString()),
                        ),
                    ],
                  ),
                );
                if (selected == null || !context.mounted) return;
                Navigator.of(context).pop();
                try {
                  await Get.find<RoleScreenService>().assignShipper(
                    orderId: item.id,
                    shipperId: selected,
                  );
                  await onChanged();
                  Get.snackbar('Thành công', 'Đã điều phối đơn hàng');
                } catch (error) {
                  Get.snackbar('Lỗi', error.toString());
                }
              },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(assignedId == null ? 'Gán shipper' : 'Chuyển shipper'),
      ),
      if (assignedId != null) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            try {
              await Get.find<RoleScreenService>().unassignShipper(item.id);
              await onChanged();
              Get.snackbar('Thành công', 'Đã gỡ điều phối đơn hàng');
            } catch (error) {
              Get.snackbar('Lỗi', error.toString());
            }
          },
          icon: const Icon(Icons.person_remove_rounded),
          label: const Text('Gỡ shipper'),
        ),
      ],
    ];
  }

  List<Widget> _returnActions(BuildContext context) {
    if (![
      'pending_warehouse',
      'requested',
      'ship_confirmed',
    ].contains(item.status)) {
      return const [];
    }

    return [
      FilledButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Nhận hàng trả'),
              content: const Text(
                'Xác nhận nhận hàng, cập nhật tồn kho và tạo phiếu nhập kho?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Xác nhận nhập kho'),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;
          Navigator.of(context).pop();
          try {
            await Get.find<RoleScreenService>().receiveReturn(item.id);
            await onChanged();
            Get.snackbar(
              'Thành công',
              'Đã nhận hàng trả và tạo phiếu nhập kho',
            );
          } catch (error) {
            Get.snackbar('Lỗi', error.toString());
          }
        },
        icon: const Icon(Icons.inventory_rounded),
        label: const Text('Nhận hàng trả và tạo phiếu nhập'),
      ),
    ];
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _displayValue(Object? value) {
  if (value == null) return '';
  if (value is num || value is bool || value is String) return value.toString();
  if (value is Map) {
    return (value['name'] ?? value['code'] ?? value['document_number'] ?? '')
        .toString();
  }
  if (value is List) return '${value.length} mục';
  return '';
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onRetry, child: const Text('Tải lại')),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showWorkspaceSwitcher(BuildContext context) async {
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

IconData _icon(String name) {
  return switch (name) {
    'account_balance' => Icons.account_balance_rounded,
    'add_box' => Icons.add_box_rounded,
    'assignment_return' => Icons.assignment_return_rounded,
    'assignment_returned' => Icons.assignment_returned_rounded,
    'approval' => Icons.approval_rounded,
    'check_circle' => Icons.check_circle_outline_rounded,
    'dashboard' => Icons.dashboard_rounded,
    'inventory' => Icons.inventory_rounded,
    'inventory_2' => Icons.inventory_2_rounded,
    'local_shipping' => Icons.local_shipping_rounded,
    'move_to_inbox' => Icons.move_to_inbox_rounded,
    'outbox' => Icons.outbox_rounded,
    'payments' => Icons.payments_rounded,
    'people' => Icons.people_alt_rounded,
    'money_off' => Icons.money_off_csred_rounded,
    'query_stats' => Icons.query_stats_rounded,
    'receipt_long' => Icons.receipt_long_rounded,
    'route' => Icons.route_rounded,
    'swap_horiz' => Icons.swap_horiz_rounded,
    'sync_alt' => Icons.sync_alt_rounded,
    _ => Icons.apps_rounded,
  };
}
