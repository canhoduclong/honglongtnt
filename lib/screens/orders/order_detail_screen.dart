import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/order_controller.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _amountController = TextEditingController();
  final _picker = ImagePicker();
  final _qtyControllers = <int, TextEditingController>{};
  final _weightControllers = <int, TextEditingController>{};
  final _deliveryImages = <XFile>[];
  final _invoiceImages = <XFile>[];

  late final OrderModel order;
  late final OrderController controller;
  List<WarehouseOption> _warehouses = const [];
  int _step = 0;
  bool _returnMode = false;
  bool _submitting = false;
  int? _warehouseId;
  String? _returnReason;

  @override
  void initState() {
    super.initState();
    order = Get.arguments as OrderModel;
    controller = Get.find<OrderController>();
    for (final item in order.items) {
      _qtyControllers[item.id] = TextEditingController(
        text: item.quantity.round().toString(),
      );
      _weightControllers[item.id] = TextEditingController(
        text: _number(item.deliveryBaseWeight),
      );
    }
    controller.warehouses().then((items) {
      if (!mounted) return;
      setState(() {
        _warehouses = items;
        _warehouseId = items.isEmpty ? null : items.first.id;
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (final item in _qtyControllers.values) {
      item.dispose();
    }
    for (final item in _weightControllers.values) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text('Giao hàng ${order.code}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OrderHeader(order: order),
            const SizedBox(height: 14),
            if (_returnMode) _ReturnStepper(step: _step),
            if (_returnMode) const SizedBox(height: 14),
            if (_step == 0) _inspectionStep(),
            if (_step == 1) _reviewStep(),
            if (_step == 2) _completionStep(),
          ],
        ),
      ),
    );
  }

  Widget _inspectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Kiểm kê hàng hóa',
          subtitle: _returnMode
              ? 'Nhập số lượng và số kg thực tế khách đã nhận.'
              : 'Kiểm tra sản phẩm trước khi giao cho khách.',
          child: Column(
            children: [for (final item in order.items) _itemEditor(item)],
          ),
        ),
        if (_returnMode) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Thông tin hàng trả',
            subtitle: 'Kho tiếp nhận và lý do trả là bắt buộc.',
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _warehouseId,
                  decoration: const InputDecoration(labelText: 'Kho nhận trả'),
                  items: [
                    for (final warehouse in _warehouses)
                      DropdownMenuItem(
                        value: warehouse.id,
                        child: Text(warehouse.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _warehouseId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _returnReason,
                  decoration: const InputDecoration(
                    labelText: 'Lý do trả hàng',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'customer_refused',
                      child: Text('Khách từ chối nhận'),
                    ),
                    DropdownMenuItem(
                      value: 'overstock',
                      child: Text('Khách nhận dư / đặt nhầm'),
                    ),
                    DropdownMenuItem(
                      value: 'quality',
                      child: Text('Hàng không đủ chất lượng'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Lý do khác')),
                  ],
                  onChanged: (value) => setState(() => _returnReason = value),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            if (_returnMode)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _returnMode = false),
                  child: const Text('Quay lại'),
                ),
              )
            else
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _returnMode = true),
                  icon: const Icon(Icons.assignment_return_rounded),
                  label: const Text('Trả hàng'),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _continueFromInspection,
                child: Text(_returnMode ? 'Lưu và Tiếp tục' : 'Tiếp tục'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemEditor(OrderItemModel item) {
    final deliveredQty = _deliveredQty(item);
    final returnedQty = (item.quantity.round() - deliveredQty).clamp(
      0,
      item.quantity.round(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.displayName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            'Xuất: ${item.quantityLabel} | ${_number(item.deliveryBaseWeight)} kg',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyControllers[item.id],
                  enabled: _returnMode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'SL thực giao'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _weightControllers[item.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Kg thực giao'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (_returnMode && returnedQty > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Trả về: $returnedQty | ${_number(_returnedWeight(item))} kg',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const Divider(height: 22),
        ],
      ),
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Giao thành công',
          subtitle: 'Tổng tiền được tính lại theo lượng thực giao.',
          child: Column(
            children: [
              for (final item in order.items)
                _ReviewLine(
                  title: item.displayName,
                  detail:
                      'Giao ${_deliveredQty(item)} | ${_number(_deliveredWeight(item))} kg',
                  amount: item.price * _billingFactor(item),
                ),
              const Divider(),
              _MoneyRow(label: 'Tổng thực giao', amount: _adjustedTotal),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Hàng trả về',
          subtitle: _reasonLabel(_returnReason),
          child: Column(
            children: [
              for (final item in order.items)
                if (_returnedQty(item) > 0)
                  _ReviewLine(
                    title: item.displayName,
                    detail:
                        'Trả ${_returnedQty(item)} | ${_number(_returnedWeight(item))} kg',
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('Tiếp tục hoàn tất đơn'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _completionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Thanh toán / Hoàn tất',
          subtitle: 'Tổng cần thu: ${Formatters.money(_adjustedTotal)}',
          child: Column(
            children: [
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Số tiền thu (không bắt buộc)',
                  hintText: 'Để trống nếu khách công nợ / thanh toán sau',
                ),
              ),
              const SizedBox(height: 14),
              _ImagePickerField(
                label: 'Hình ảnh giao hàng *',
                count: _deliveryImages.length,
                onPick: () => _pickImages(_deliveryImages),
              ),
              const SizedBox(height: 10),
              _ImagePickerField(
                label: 'Hóa đơn giao hàng',
                count: _invoiceImages.length,
                onPick: () => _pickImages(_invoiceImages),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _step = _returnMode ? 1 : 0),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _submitting ? null : _complete,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_submitting ? 'Đang lưu...' : 'Hoàn thành'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _continueFromInspection() {
    for (final item in order.items) {
      final qty = _deliveredQty(item);
      final weight = _deliveredWeight(item);
      if (qty < 0 ||
          qty > item.quantity.round() ||
          weight < 0 ||
          weight > item.deliveryBaseWeight + .001) {
        Get.snackbar(
          'Dữ liệu chưa hợp lệ',
          'Kiểm tra số lượng và kg thực giao.',
        );
        return;
      }
    }
    if (_returnMode && (_warehouseId == null || _returnReason == null)) {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng chọn kho nhận và lý do trả hàng.',
      );
      return;
    }
    setState(() => _step = _returnMode ? 1 : 2);
  }

  Future<void> _pickImages(List<XFile> target) async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (!mounted || images.isEmpty) return;
    setState(() => target.addAll(images));
  }

  Future<void> _complete() async {
    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty ? null : double.tryParse(amountText);
    if (amountText.isNotEmpty && (amount == null || amount < 0)) {
      Get.snackbar('Số tiền chưa hợp lệ', 'Vui lòng nhập số tiền thu hợp lệ.');
      return;
    }
    if (_deliveryImages.isEmpty) {
      Get.snackbar(
        'Thiếu hình ảnh giao hàng',
        'Vui lòng chọn ít nhất một hình ảnh giao hàng.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành đơn hàng?'),
        content: const Text(
          'Dữ liệu giao thực tế, hàng trả và chứng từ sẽ được lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    final success = await controller.completeDelivery(
      order,
      collectedAmount: amount,
      hasPartialReturn: _returnMode,
      deliveredQuantities: {
        for (final item in order.items) item.id: _deliveredQty(item),
      },
      deliveredWeights: {
        for (final item in order.items) item.id: _deliveredWeight(item),
      },
      deliveryImagePaths: _deliveryImages.map((image) => image.path).toList(),
      invoiceImagePaths: _invoiceImages.map((image) => image.path).toList(),
      returnWarehouseId: _returnMode ? _warehouseId : null,
      returnReason: _returnMode ? _returnReason : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Get.back();
  }

  int _deliveredQty(OrderItemModel item) =>
      int.tryParse(_qtyControllers[item.id]?.text.trim() ?? '') ??
      item.quantity.round();
  int _returnedQty(OrderItemModel item) =>
      (item.quantity.round() - _deliveredQty(item)).clamp(
        0,
        item.quantity.round(),
      );
  double _deliveredWeight(OrderItemModel item) =>
      double.tryParse(_weightControllers[item.id]?.text.trim() ?? '') ??
      item.deliveryBaseWeight;
  double _returnedWeight(OrderItemModel item) =>
      (item.deliveryBaseWeight - _deliveredWeight(item)).clamp(
        0,
        double.infinity,
      );
  double _billingFactor(OrderItemModel item) =>
      item.pricedByKg ? _deliveredWeight(item) : _deliveredQty(item).toDouble();
  double get _adjustedTotal => order.items.fold(
    0,
    (total, item) => total + item.price * _billingFactor(item),
  );

  static String _number(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: order.code,
    subtitle: 'Thông tin đơn hàng và khách nhận',
    trailing: StatusBadge(status: order.status),
    child: Column(
      children: [
        _InfoRow(icon: Icons.person_rounded, value: order.customer.name),
        _InfoRow(icon: Icons.phone_rounded, value: order.customer.phone),
        _InfoRow(icon: Icons.place_rounded, value: order.customer.address),
        _InfoRow(
          icon: Icons.payments_rounded,
          value: Formatters.money(order.total),
        ),
      ],
    ),
  );
}

class _ReturnStepper extends StatelessWidget {
  const _ReturnStepper({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < 3; index++) ...[
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: index <= step
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFFE2E8F0),
                foregroundColor: index <= step ? Colors.white : Colors.black54,
                child: Text('${index + 1}'),
              ),
              const SizedBox(height: 4),
              Text(
                const ['Trả hàng', 'Xem lại', 'Thanh toán'][index],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          const Divider(height: 24),
          child,
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(child: Text(value.isEmpty ? '-' : value)),
      ],
    ),
  );
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.title, required this.detail, this.amount});
  final String title;
  final String detail;
  final double? amount;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(detail),
    trailing: amount == null ? null : Text(Formatters.money(amount)),
  );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      Text(
        Formatters.money(amount),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.label,
    required this.count,
    required this.onPick,
  });
  final String label;
  final int count;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPick,
    icon: const Icon(Icons.add_a_photo_rounded),
    label: Text('$label${count > 0 ? ' ($count ảnh)' : ''}'),
  );
}

String _reasonLabel(String? reason) => switch (reason) {
  'customer_refused' => 'Khách từ chối nhận',
  'overstock' => 'Khách nhận dư / đặt nhầm',
  'quality' => 'Hàng không đủ chất lượng',
  'other' => 'Lý do khác',
  _ => '-',
};
