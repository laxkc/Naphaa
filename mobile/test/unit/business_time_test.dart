import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/date/business_clock.dart';
import 'package:sme_digital/core/date/business_time.dart';

void main() {
  test('businessDateAd uses Asia/Kathmandu business day by default', () {
    final timestamp = DateTime.parse('2026-02-27T18:30:00Z');

    final ad = BusinessTime.businessDateAd(timestampUtc: timestamp);

    expect(ad, '2026-02-28');
  });

  test('businessDateAd stays on same day for UTC business timezone', () {
    final timestamp = DateTime.parse('2026-02-27T18:30:00Z');

    final ad = BusinessTime.businessDateAd(
      timestampUtc: timestamp,
      timezone: 'UTC',
    );

    expect(ad, '2026-02-27');
  });

  test('normalizeUtcIso converts offset timestamps into canonical UTC', () {
    final normalized = BusinessTime.normalizeUtcIso(
      '2026-02-27T18:00:00+05:45',
    );

    expect(normalized, '2026-02-27T12:15:00.000Z');
  });

  test('BusinessClock day ranges are end-exclusive', () {
    const clock = BusinessClock(timezone: 'Asia/Kathmandu');
    final day = DateTime.utc(2026, 2, 27);

    final start = clock.startOfDayAd(day);
    final end = clock.endOfDayAd(day);

    expect(start, DateTime(2026, 2, 27));
    expect(end, DateTime(2026, 2, 28));
    expect(end.difference(start), const Duration(days: 1));
  });

  test('BusinessClock currentWeekRange starts on Monday', () {
    const clock = BusinessClock(timezone: 'UTC');
    final reference = DateTime.utc(2026, 2, 27); // Friday

    final start = clock.startOfDayAd(
      reference.subtract(Duration(days: reference.weekday - 1)),
    );

    expect(start.weekday, DateTime.monday);
  });
}
