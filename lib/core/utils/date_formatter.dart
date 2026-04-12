// lib/core/utils/date_formatter.dart
//
// Consistent date/time formatting used across the app.

class DateFormatter {
  DateFormatter._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g.  "15 Mar 2026"
  static String date(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  /// e.g.  "15 Mar · 09:30"
  static String dateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_months[dt.month - 1]} · $h:$m';
  }

  /// e.g.  "09:30"
  static String time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// e.g.  "2 days ago" / "just now"
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return date(dt);
  }
}
