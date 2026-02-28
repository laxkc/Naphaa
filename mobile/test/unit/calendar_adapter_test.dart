import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/date/calendar_adapter.dart';

void main() {
  test('adToBsDate converts canonical AD date to BS', () {
    const adapter = CalendarAdapter(calendarMode: 'BS', localeCode: 'en');

    final bs = adapter.adToBsDate(DateTime(2019, 8, 3));

    expect(bs.year, 2076);
    expect(bs.month, 4);
    expect(bs.day, 18);
    expect(bs.isFallback, isFalse);
  });

  test('bsToAdDate round-trips known BS date to AD', () {
    const adapter = CalendarAdapter(calendarMode: 'BS', localeCode: 'en');

    final ad = adapter.bsToAdDate(year: 2076, month: 4, day: 18);

    expect(ad, isNotNull);
    expect(ad!.year, 2019);
    expect(ad.month, 8);
    expect(ad.day, 3);
  });

  test('formatBusinessDate renders BS year in BS mode', () {
    const adapter = CalendarAdapter(calendarMode: 'BS', localeCode: 'en');

    final formatted = adapter.formatBusinessDate(DateTime(2019, 8, 3));

    expect(formatted, '2076-04-18');
  });

  test('formatFiscalYearLabel uses BS year in BS mode', () {
    const adapter = CalendarAdapter(calendarMode: 'BS', localeCode: 'en');

    expect(adapter.formatFiscalYearLabel(DateTime(2019, 8, 3)), '2076');
  });
}
