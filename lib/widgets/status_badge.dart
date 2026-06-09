import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      'packed_waiting_pickup' => ('Chờ nhận', const Color(0xFF64748B)),
      'delivering' => ('Đang giao', const Color(0xFFF59E0B)),
      'delivered' => ('Đã giao', const Color(0xFF16A34A)),
      'returning' => ('Trả hàng', const Color(0xFFDC2626)),
      'returned_completed' => ('Đã trả', const Color(0xFFDC2626)),
      'completed' => ('Hoàn tất', const Color(0xFF16A34A)),
      _ => (status, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: data.$2.withValues(alpha: .26)),
      ),
      child: Text(
        data.$1,
        style: TextStyle(
          color: data.$2,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
