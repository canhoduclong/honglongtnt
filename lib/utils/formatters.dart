import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String money(num? value) => _money.format(value ?? 0);

  static String compactNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat.compact(locale: 'vi_VN').format(value);
  }

  static String dateTime(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }
}
