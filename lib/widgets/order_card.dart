import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_model.dart';
import '../routes/app_routes.dart';
import '../utils/formatters.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.trailing,
    this.priorityNumber,
  });

  final OrderModel order;
  final Widget? trailing;
  final int? priorityNumber;

  Color get _statusColor {
    if (order.isReadyToShip) return const Color(0xFF64748B);
    if (order.isDelivering) return const Color(0xFFF59E0B);
    if (order.isDelivered || order.status == 'completed') {
      return const Color(0xFF16A34A);
    }
    if (order.isReturning || order.status == 'returned_completed') {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF64748B);
  }

  int get _priority => priorityNumber ?? order.dailySequence ?? order.id;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriorityCircle(number: _priority, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customer.name.isEmpty
                              ? 'Khách hàng chưa cập nhật'
                              : order.customer.name,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              if (order.deliveryTime?.isNotEmpty == true) ...[
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 19, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'Giao trước ${order.deliveryTime}',
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customer.phone.isEmpty ? '-' : order.customer.phone,
                    ),
                  ),
                  _ContactButton(
                    icon: Icons.call_rounded,
                    label: 'Gọi',
                    onPressed: order.customer.phone.isEmpty
                        ? null
                        : () => _openPhone(order.customer.phone),
                  ),
                  const SizedBox(width: 6),
                  _ContactButton(
                    icon: Icons.chat_rounded,
                    label: 'Zalo',
                    onPressed: order.customer.phone.isEmpty
                        ? null
                        : () => _openZalo(order.customer.phone),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customer.address.isEmpty
                          ? 'Chưa có địa chỉ'
                          : order.customer.address,
                    ),
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...order.items
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.shopping_bag_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                [
                                  item.displayName.isEmpty
                                      ? 'Sản phẩm'
                                      : item.displayName,
                                  if (item.size.isNotEmpty) 'Size ${item.size}',
                                  'SL ${item.quantityLabel}',
                                ].join(' | '),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              if (order.hasCustomerFeedback) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tình trạng khách hàng: ${order.customerFeedbackLabel ?? 'Cần lưu ý'}',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if ((order.customerFeedbackNote ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          order.customerFeedbackNote!,
                          style: const TextStyle(color: Color(0xFF78350F)),
                        ),
                      ],
                      if ((order.customerFeedbackSaleReview ?? '')
                          .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Sale: ${order.customerFeedbackSaleReview!}',
                          style: const TextStyle(
                            color: Color(0xFF78350F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (order.customerFeedbackImages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: order.customerFeedbackImages.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                order.customerFeedbackImages[index],
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (order.deliverySchedule != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lộ trình ${order.deliverySchedule!.code}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Formatters.money(order.total),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static Future<void> _openPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: _cleanPhone(phone));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> _openZalo(String phone) async {
    final cleanPhone = _cleanPhone(phone).replaceFirst(RegExp(r'^\+?84'), '0');
    final uri = Uri.parse('https://zalo.me/$cleanPhone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PriorityCircle extends StatelessWidget {
  const _PriorityCircle({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: color == const Color(0xFFF59E0B) ? Colors.black : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
