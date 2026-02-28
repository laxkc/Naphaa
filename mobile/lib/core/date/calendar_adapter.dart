import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

class CalendarDateParts {
  const CalendarDateParts({
    required this.year,
    required this.month,
    required this.day,
    required this.isFallback,
  });

  final int year;
  final int month;
  final int day;
  final bool isFallback;
}

class CalendarAdapter {
  const CalendarAdapter({
    required this.calendarMode,
    required this.localeCode,
  });

  final String calendarMode;
  final String localeCode;

  bool get isBsMode => calendarMode.trim().toUpperCase() == 'BS';
  bool get supportsBsConversion => true;

  Language get _language =>
      localeCode.trim().toLowerCase() == 'ne'
          ? Language.nepali
          : Language.english;

  DateTime _normalizeAdBusinessDate(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day, 12);

  bool _sameAdDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  DateTime? bsToAdDate({
    required int year,
    required int month,
    required int day,
  }) {
    try {
      return NepaliDateTime(year, month, day).toDateTime();
    } catch (_) {
      return null;
    }
  }

  CalendarDateParts adToBsDate(DateTime adDate) {
    final targetAdDate = DateTime(adDate.year, adDate.month, adDate.day);
    final approximate = _normalizeAdBusinessDate(adDate).toNepaliDateTime();
    NepaliDateTime resolved = approximate;
    var matched = false;

    for (var offset = -2; offset <= 2; offset++) {
      final candidate = approximate.add(Duration(days: offset));
      if (_sameAdDate(candidate.toDateTime(), targetAdDate)) {
        resolved = candidate;
        matched = true;
        break;
      }
    }

    return CalendarDateParts(
      year: resolved.year,
      month: resolved.month,
      day: resolved.day,
      isFallback: !matched,
    );
  }

  String formatBusinessDate(
    DateTime? adDate, {
    bool includeTime = false,
  }) {
    if (adDate == null) return '-';
    if (isBsMode) {
      final parts = adToBsDate(adDate);
      final localTime = adDate.toLocal();
      final bs = NepaliDateTime(
        parts.year,
        parts.month,
        parts.day,
        includeTime ? localTime.hour : 0,
        includeTime ? localTime.minute : 0,
      );
      final pattern = includeTime ? 'yyyy-MM-dd HH:mm' : 'yyyy-MM-dd';
      return NepaliDateFormat(pattern, _language).format(bs);
    }
    final locale = localeCode == 'ne' ? 'ne_NP' : 'en_US';
    final normalized = adDate.toLocal();
    final formatter =
        includeTime
            ? DateFormat('yyyy-MM-dd HH:mm', locale)
            : DateFormat('yyyy-MM-dd', locale);
    return formatter.format(normalized);
  }

  String formatFiscalYearLabel(DateTime adDate) {
    if (isBsMode) {
      return adToBsDate(adDate).year.toString();
    }
    return adDate.year.toString();
  }

  String invoiceYearKey(DateTime issueDate) => formatFiscalYearLabel(issueDate);
}
