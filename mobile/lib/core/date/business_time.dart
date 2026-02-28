class BusinessTime {
  static const String defaultBusinessTimezone = 'Asia/Kathmandu';
  static const String defaultCalendarMode = 'BS';

  static DateTime nowUtc() => DateTime.now().toUtc();

  static String nowUtcIso() => nowUtc().toIso8601String();

  static String normalizeUtcIso(
    Object? raw, {
    DateTime? fallback,
  }) {
    final parsed = raw == null ? null : DateTime.tryParse(raw.toString());
    return (parsed ?? fallback ?? nowUtc()).toUtc().toIso8601String();
  }

  static String businessDateAd({
    DateTime? timestampUtc,
    String timezone = defaultBusinessTimezone,
  }) {
    final businessLocal = _toBusinessLocal(
      (timestampUtc ?? nowUtc()).toUtc(),
      timezone,
    );
    return formatDateOnly(businessLocal);
  }

  static String formatDateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? parseAdDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  static DateTime _toBusinessLocal(DateTime utc, String timezone) {
    switch (timezone.trim()) {
      case 'UTC':
        return utc;
      case defaultBusinessTimezone:
      default:
        return utc.add(const Duration(hours: 5, minutes: 45));
    }
  }
}
