import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String symbol = '\$'}) {
    final f = NumberFormat('#,##0.00');
    return '$symbol${f.format(amount)}';
  }

  static String compactCurrency(double amount, {String symbol = '\$'}) {
    if (amount >= 1000000) return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    return currency(amount, symbol: symbol);
  }

  static String date(DateTime dt) => DateFormat('MMM d, yyyy').format(dt);
  static String dateShort(DateTime dt) => DateFormat('MMM d').format(dt);
  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);
  static String dayMonth(DateTime dt) => DateFormat('d MMM').format(dt);
  static String weekdayShort(DateTime dt) => DateFormat('EEE').format(dt);
  static String monthYear(DateTime dt) => DateFormat('MMMM yyyy').format(dt);

  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  static String percentage(double value) => '${value.toStringAsFixed(0)}%';

  static String waterAmount(int ml) {
    if (ml >= 1000) return '${(ml / 1000).toStringAsFixed(1)}L';
    return '${ml}ml';
  }

  static String sleepDuration(double hours) {
    final h = hours.truncate();
    final m = ((hours - h) * 60).round();
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  static String relativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return date(dt);
  }
}
