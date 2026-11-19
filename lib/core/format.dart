import 'package:intl/intl.dart';

/// Formatting helpers shared by every screen.
class Fmt {
  static String day(DateTime? d) => d == null ? '' : DateFormat('EEE, d MMM').format(d); // Sun, 18 Oct
  static String dayShort(DateTime? d) => d == null ? '' : DateFormat('EEE d MMM').format(d); // Fri 30 Oct
  static String date(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy').format(d); // 12 Mar 2026
  static String dateShort(DateTime? d) => d == null ? '' : DateFormat('d MMM').format(d); // 18 Oct
  static String monthYear(DateTime? d) => d == null ? '—' : DateFormat('MMM yyyy').format(d); // Feb 2027
  static String month(DateTime d) => DateFormat('MMM').format(d);
  static String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
  static String year(DateTime? d) => d == null ? '' : DateFormat('yyyy').format(d);
  static String time(DateTime? d) => d == null ? '' : DateFormat('h:mm a').format(d).toLowerCase(); // 6:40 pm
  static String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String relative(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return dateShort(d);
  }

  /// Indian currency short form: ₹1.20 Cr, ₹45.0 L, ₹85,000.
  static String budget(num? amount) {
    if (amount == null) return 'Hidden';
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)} L';
    if (amount == 0) return '—';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String pad2(int n) => n.toString().padLeft(2, '0');

  static String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

  static String statusLabel(String status) => switch (status) {
        'in_progress' => 'In progress',
        'on_hold' => 'On hold',
        'completed' => 'Completed',
        'new' => 'New',
        'done' => 'Done',
        _ => status,
      };

  static String requestType(String type) => switch (type) {
        'question' => 'Question',
        'change' => 'Change',
        'approval' => 'Approved',
        'call' => 'Call',
        _ => type,
      };
}
