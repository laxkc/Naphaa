import 'package:sqflite/sqflite.dart';

import '../../../core/date/calendar_adapter.dart';
import '../../../core/storage/local_db.dart';

class InvoiceNumberingService {
  InvoiceNumberingService(this._db, {CalendarAdapter? adapter})
    : _adapter =
          adapter ??
          const CalendarAdapter(calendarMode: 'AD', localeCode: 'en');

  final LocalDatabase _db;
  final CalendarAdapter _adapter;

  Future<String> nextInvoiceNumber({
    required String businessId,
    required String prefix,
    required DateTime issueDateAd,
    required String fiscalCalendar,
  }) async {
    final db = await _db.database;
    return db.transaction((txn) {
      return reserveNextInvoiceNumber(
        txn,
        businessId: businessId,
        prefix: prefix,
        issueDateAd: issueDateAd,
        fiscalCalendar: fiscalCalendar,
      );
    });
  }

  Future<String> reserveNextInvoiceNumber(
    DatabaseExecutor txn, {
    required String businessId,
    required String prefix,
    required DateTime issueDateAd,
    required String fiscalCalendar,
  }) async {
    final safePrefix = _sanitizePrefix(prefix);
    final yearKey = _yearKey(
      issueDateAd: issueDateAd,
      fiscalCalendar: fiscalCalendar,
    );

    final row = await txn.query(
      'invoice_sequence',
      where: 'business_id = ? AND year_key = ?',
      whereArgs: [businessId, yearKey],
      limit: 1,
    );
    var nextSeq = row.isEmpty ? 1 : ((row.first['last_seq'] as num?)?.toInt() ?? 0) + 1;

    while (true) {
      final candidate = _formatInvoiceNumber(
        prefix: safePrefix,
        yearKey: yearKey,
        sequence: nextSeq,
      );
      final exists =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              '''
              SELECT 1
              FROM invoices
              WHERE business_id = ? AND invoice_number = ?
              LIMIT 1
              ''',
              [businessId, candidate],
            ),
          ) ==
          1;

      if (!exists) {
        if (row.isEmpty) {
          await txn.insert('invoice_sequence', {
            'business_id': businessId,
            'year_key': yearKey,
            'last_seq': nextSeq,
          });
        } else {
          await txn.update(
            'invoice_sequence',
            {'last_seq': nextSeq},
            where: 'business_id = ? AND year_key = ?',
            whereArgs: [businessId, yearKey],
          );
        }
        return candidate;
      }

      nextSeq += 1;
    }
  }

  String _yearKey({
    required DateTime issueDateAd,
    required String fiscalCalendar,
  }) {
    final normalized = fiscalCalendar.trim().toUpperCase();
    final adapter =
        normalized == 'BS'
            ? CalendarAdapter(
              calendarMode: 'BS',
              localeCode: _adapter.localeCode,
            )
            : CalendarAdapter(
              calendarMode: 'AD',
              localeCode: _adapter.localeCode,
            );
    return adapter.invoiceYearKey(issueDateAd);
  }

  String _sanitizePrefix(String prefix) {
    final p = prefix.trim().toUpperCase();
    return p.isEmpty ? 'INV' : p.replaceAll(RegExp(r'[^A-Z0-9_-]'), '');
  }

  String _formatInvoiceNumber({
    required String prefix,
    required String yearKey,
    required int sequence,
  }) {
    final seq = sequence.toString().padLeft(5, '0');
    return '$prefix-$yearKey-$seq';
  }
}
