import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sme_digital/core/date/calendar_adapter.dart';
import 'package:sme_digital/core/storage/local_db.dart';
import 'package:sme_digital/features/billing/data/invoice_numbering_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('generates sequential invoice numbers per business/year', () async {
    const dbName = 'test_invoice_numbering_seq.db';
    final path = join(await getDatabasesPath(), dbName);
    await deleteDatabase(path);

    final localDb = LocalDatabase(dbName: dbName);
    final db = await localDb.database;
    final service = InvoiceNumberingService(localDb);
    final issueDate = DateTime(2026, 2, 25);

    final n1 = await service.nextInvoiceNumber(
      businessId: 'b1',
      prefix: 'INV',
      issueDateAd: issueDate,
      fiscalCalendar: 'AD',
    );
    await db.insert('invoices', {
      'id': 'i1',
      'business_id': 'b1',
      'invoice_number': n1,
      'status': 'issued',
      'issue_date': issueDate.toIso8601String(),
      'currency_code': 'NPR',
      'fiscal_calendar_snapshot': 'AD',
      'language_snapshot': 'en',
      'vat_enabled_snapshot': 0,
      'vat_rate_snapshot': 13.0,
      'tax_mode_snapshot': 'exclusive',
      'subtotal': 100.0,
      'discount_amount': 0.0,
      'tax_amount': 0.0,
      'total': 100.0,
      'paid_amount': 100.0,
      'balance_due': 0.0,
      'pdf_status': 'none',
      'created_at': issueDate.toIso8601String(),
      'updated_at': issueDate.toIso8601String(),
    });

    final n2 = await service.nextInvoiceNumber(
      businessId: 'b1',
      prefix: 'INV',
      issueDateAd: issueDate,
      fiscalCalendar: 'AD',
    );

    expect(n1, 'INV-2026-00001');
    expect(n2, 'INV-2026-00002');

    await db.close();
    await deleteDatabase(path);
  });

  test('separates sequence by business and year', () async {
    const dbName = 'test_invoice_numbering_scope.db';
    final path = join(await getDatabasesPath(), dbName);
    await deleteDatabase(path);

    final localDb = LocalDatabase(dbName: dbName);
    final service = InvoiceNumberingService(localDb);

    final b1y2026 = await service.nextInvoiceNumber(
      businessId: 'b1',
      prefix: 'KTM',
      issueDateAd: DateTime(2026, 1, 1),
      fiscalCalendar: 'AD',
    );
    final b2y2026 = await service.nextInvoiceNumber(
      businessId: 'b2',
      prefix: 'INV',
      issueDateAd: DateTime(2026, 1, 1),
      fiscalCalendar: 'AD',
    );
    final b1y2027 = await service.nextInvoiceNumber(
      businessId: 'b1',
      prefix: 'KTM',
      issueDateAd: DateTime(2027, 1, 1),
      fiscalCalendar: 'AD',
    );

    expect(b1y2026, 'KTM-2026-00001');
    expect(b2y2026, 'INV-2026-00001');
    expect(b1y2027, 'KTM-2027-00001');

    final db = await localDb.database;
    final seqRows = await db.query('invoice_sequence', orderBy: 'business_id, year_key');
    expect(seqRows.length, 3);

    await db.close();
    await deleteDatabase(path);
  });

  test('skips existing invoice number collisions and advances sequence', () async {
    const dbName = 'test_invoice_numbering_collision.db';
    final path = join(await getDatabasesPath(), dbName);
    await deleteDatabase(path);

    final localDb = LocalDatabase(dbName: dbName);
    final db = await localDb.database;
    final service = InvoiceNumberingService(localDb);
    final issueDate = DateTime(2026, 2, 25);

    await db.insert('invoice_sequence', {
      'business_id': 'b1',
      'year_key': '2026',
      'last_seq': 1,
    });
    await db.insert('invoices', {
      'id': 'i-existing',
      'business_id': 'b1',
      'invoice_number': 'INV-2026-00002',
      'status': 'issued',
      'issue_date': issueDate.toIso8601String(),
      'currency_code': 'NPR',
      'fiscal_calendar_snapshot': 'AD',
      'language_snapshot': 'en',
      'vat_enabled_snapshot': 0,
      'vat_rate_snapshot': 13.0,
      'tax_mode_snapshot': 'exclusive',
      'subtotal': 100.0,
      'discount_amount': 0.0,
      'tax_amount': 0.0,
      'total': 100.0,
      'paid_amount': 100.0,
      'balance_due': 0.0,
      'pdf_status': 'none',
      'created_at': issueDate.toIso8601String(),
      'updated_at': issueDate.toIso8601String(),
    });

    final next = await service.nextInvoiceNumber(
      businessId: 'b1',
      prefix: 'INV',
      issueDateAd: issueDate,
      fiscalCalendar: 'AD',
    );

    expect(next, 'INV-2026-00003');

    final row = await db.query(
      'invoice_sequence',
      where: 'business_id = ? AND year_key = ?',
      whereArgs: ['b1', '2026'],
      limit: 1,
    );
    expect((row.first['last_seq'] as num).toInt(), 3);

    await db.close();
    await deleteDatabase(path);
  });

  test('uses real BS year key when fiscal calendar is BS', () async {
    const dbName = 'test_invoice_numbering_bs_year.db';
    final path = join(await getDatabasesPath(), dbName);
    await deleteDatabase(path);

    final localDb = LocalDatabase(dbName: dbName);
    final service = InvoiceNumberingService(
      localDb,
      adapter: const CalendarAdapter(calendarMode: 'BS', localeCode: 'en'),
    );

    final number = await service.nextInvoiceNumber(
      businessId: 'b-bs',
      prefix: 'INV',
      issueDateAd: DateTime(2019, 8, 3),
      fiscalCalendar: 'BS',
    );

    expect(number, 'INV-2076-00001');

    final db = await localDb.database;
    final seqRows = await db.query(
      'invoice_sequence',
      where: 'business_id = ?',
      whereArgs: ['b-bs'],
      limit: 1,
    );
    expect(seqRows.single['year_key'], '2076');

    await db.close();
    await deleteDatabase(path);
  });
}
