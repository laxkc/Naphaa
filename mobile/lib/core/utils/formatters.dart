import 'package:intl/intl.dart';

String formatCurrency(num value, String localeCode) {
  final locale = localeCode == 'ne' ? 'ne_NP' : 'en_US';
  final formatter = NumberFormat.currency(locale: locale, symbol: 'Rs ');
  return formatter.format(value);
}
