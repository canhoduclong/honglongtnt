class DashboardStats {
  const DashboardStats({
    required this.todayTotal,
    required this.available,
    required this.delivering,
    required this.deliveredToday,
    required this.returning,
  });

  final int todayTotal;
  final int available;
  final int delivering;
  final int deliveredToday;
  final int returning;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    int toInt(String key) => int.tryParse('${json[key] ?? 0}') ?? 0;

    return DashboardStats(
      todayTotal: toInt('today_total'),
      available: toInt('available'),
      delivering: toInt('delivering'),
      deliveredToday: toInt('delivered_today'),
      returning: toInt('returning'),
    );
  }

  static const empty = DashboardStats(
    todayTotal: 0,
    available: 0,
    delivering: 0,
    deliveredToday: 0,
    returning: 0,
  );
}
