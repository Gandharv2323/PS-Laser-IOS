/// Date and time utility functions for PS LASER Manufacturing OS.
library;

import 'package:intl/intl.dart';

class PSDateUtils {
  PSDateUtils._();

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _shortDateFormat = DateFormat('d MMM');
  static final DateFormat _firestoreDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _dayNameFormat = DateFormat('EEEE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  // ── Formatting ──────────────────────────────────────────────────────────────

  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return _dateTimeFormat.format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '—';
    return _timeFormat.format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '—';
    return _shortDateFormat.format(date);
  }

  static String formatFirestore(DateTime date) => _firestoreDate.format(date);

  static String formatDayName(DateTime date) => _dayNameFormat.format(date);

  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  // ── Relative Time ────────────────────────────────────────────────────────────

  static String relativeTime(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  static String timeUntil(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    if (date.isBefore(now)) {
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m overdue';
      if (diff.inHours < 24) return '${diff.inHours}h overdue';
      return '${diff.inDays}d overdue';
    }
    final diff = date.difference(now);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m left';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    if (diff.inDays == 1) return 'Tomorrow';
    return '${diff.inDays}d left';
  }

  // ── Checks ───────────────────────────────────────────────────────────────────

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }

  static bool isUrgent(DateTime? dueDate, {int withinHours = 24}) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return true;
    return dueDate.difference(now).inHours <= withinHours;
  }

  // ── Working Hours ────────────────────────────────────────────────────────────

  /// Returns the start DateTime for the production floor on a given date.
  static DateTime workStart(DateTime date) =>
      DateTime(date.year, date.month, date.day, 9, 0);

  /// Returns the end DateTime for the production floor on a given date.
  static DateTime workEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, 19, 0);

  /// Total production minutes in a day.
  static int get totalWorkMinutes => (19 - 9) * 60;

  /// Returns a string like "Today" / "Tomorrow" / "3 May"
  static String smartDateLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    return formatShort(date);
  }
}
