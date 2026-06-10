import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../utils/formatters.dart';

class AppNotificationCard extends StatelessWidget {
  const AppNotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final AppNotificationItem item;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: item.isUnread ? const Color(0xFFEFF6FF) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(item.priority), color: _color(item.priority)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    for (final line in item.detailLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          line,
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.createdAt.isNotEmpty)
                          Formatters.dateTime(item.createdAt),
                        item.isUnread ? 'Chưa đọc' : 'Đã đọc',
                      ].join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isUnread)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Icon(Icons.circle, size: 10, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _icon(String priority) {
  return switch (priority) {
    'urgent' => Icons.priority_high_rounded,
    'warning' => Icons.warning_amber_rounded,
    _ => Icons.info_outline_rounded,
  };
}

Color _color(String priority) {
  return switch (priority) {
    'urgent' => const Color(0xFFDC2626),
    'warning' => const Color(0xFFF59E0B),
    _ => const Color(0xFF2563EB),
  };
}
