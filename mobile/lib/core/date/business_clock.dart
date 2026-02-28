import 'business_time.dart';

class BusinessDateRange {
  const BusinessDateRange({
    required this.fromDate,
    required this.toDate,
  });

  final DateTime fromDate;
  final DateTime toDate;
}

class BusinessClock {
  const BusinessClock({
    required this.timezone,
  });

  final String timezone;

  factory BusinessClock.fallback() =>
      const BusinessClock(timezone: BusinessTime.defaultBusinessTimezone);

  DateTime nowUtc() => BusinessTime.nowUtc();

  DateTime currentBusinessDate() {
    final ad = BusinessTime.businessDateAd(timezone: timezone);
    return BusinessTime.parseAdDate(ad) ?? DateTime.utc(1970, 1, 1);
  }

  DateTime startOfDayAd([DateTime? date]) {
    final value = date ?? currentBusinessDate();
    return DateTime(value.year, value.month, value.day);
  }

  DateTime endOfDayAd([DateTime? date]) {
    return startOfDayAd(date).add(const Duration(days: 1));
  }

  BusinessDateRange todayRange() {
    final today = startOfDayAd();
    return BusinessDateRange(
      fromDate: today,
      toDate: endOfDayAd(today),
    );
  }

  BusinessDateRange currentWeekRange() {
    final today = startOfDayAd();
    final start = today.subtract(Duration(days: today.weekday - 1));
    return BusinessDateRange(
      fromDate: start,
      toDate: endOfDayAd(today),
    );
  }

  BusinessDateRange currentMonthRange() {
    final today = startOfDayAd();
    return BusinessDateRange(
      fromDate: DateTime(today.year, today.month, 1),
      toDate: endOfDayAd(today),
    );
  }
}
