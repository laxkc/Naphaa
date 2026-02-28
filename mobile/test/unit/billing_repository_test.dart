import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/features/billing/data/billing_repository.dart';
import 'package:sme_digital/features/billing/domain/invoice_models.dart';

import '../helpers/test_db.dart';

Map<String, dynamic> _billingSettings({
  bool vatEnabled = true,
  double vatRate = 13.0,
  String taxMode = 'exclusive',
}) => {
  'language': 'en',
  'currency_code': 'NPR',
  'fiscal_calendar': 'AD',
  'vat_enabled': vatEnabled,
  'vat_rate': vatRate,
  'tax_mode': taxMode,
  'invoice_prefix': 'INV',
  'invoice_terms_default': 'Thank you',
  'invoice_footer_default': 'Visit again',
  'business_name': 'Demo Store',
  'business_address': 'Kathmandu',
  'business_phone': '9800000999',
  'business_email': 'demo@example.com',
  'pan_vat_number': '123456789',
  'logo_path': null,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveDraft stores invoice and line snapshots', () async {
    final db = await createTestDb('billing_draft');
    final repo = BillingRepository(
      db,
      billingSettingsLoader: () async => _billingSettings(vatEnabled: false),
    );

    final invoiceId = await repo.saveDraft(
      const InvoiceDraftInput(
        businessId: 'b1',
        customerId: 'c1',
        invoiceDiscountAmount: 10,
        dueDateAd: null,
        items: [
          InvoiceDraftLineInput(
            productId: 'p1',
            productNameSnapshot: 'Sugar 1kg',
            unitSnapshot: 'kg',
            quantity: 2,
            unitPrice: 90,
          ),
        ],
      ),
    );

    final database = await db.database;
    final invoices = await database.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    final items = await database.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);

    expect(invoices.length, 1);
    expect(invoices.first['status'], 'draft');
    expect(invoices.first['invoice_number'], isNull);
    expect(invoices.first['due_date_ad'], isNull);
    expect((invoices.first['total'] as num).toDouble(), 170); // 180 - 10, no VAT
    expect(items.length, 1);
    expect(items.first['product_name_snapshot'], 'Sugar 1kg');

    await db.reset();
  });

  test('issueInvoice generates invoice number and deducts stock', () async {
    final db = await createTestDb('billing_issue');
    await db.seedIfEmpty();
    final database = await db.database;
    final product = (await database.query('products', limit: 1)).first;
    final productId = product['id'] as String;
    final beforeStock = (product['stock_qty'] as num).toDouble();

    final repo = BillingRepository(
      db,
      billingSettingsLoader: () async => _billingSettings(vatEnabled: false),
    );
    final invoiceId = await repo.saveDraft(
      InvoiceDraftInput(
        businessId: 'b1',
        items: [
          InvoiceDraftLineInput(
            productId: productId,
            productNameSnapshot: product['name'] as String,
            unitSnapshot: 'piece',
            quantity: 2,
            unitPrice: 100,
          ),
        ],
      ),
    );

    await repo.issueInvoice(invoiceId: invoiceId, paymentMethodSummary: 'CASH');
    final invoice = await repo.getInvoiceById(invoiceId);
    final productAfter = (await database.query('products', where: 'id = ?', whereArgs: [productId])).first;
    final stockMoves = await database.query('stock_movements', where: 'reference_id = ?', whereArgs: [invoiceId]);

    expect(invoice, isNotNull);
    expect(invoice!.status, InvoiceStatus.issued);
    expect(invoice.invoiceNumber, 'INV-2026-00001');
    expect(invoice.issueDateAd, isNotNull);
    expect((productAfter['stock_qty'] as num).toDouble(), beforeStock - 2);
    expect(stockMoves.length, 1);
    final outbox = await database.query(
      'sync_queue',
      where: 'entity = ? AND entity_id = ?',
      whereArgs: ['invoice', invoiceId],
    );
    expect(outbox.length, 1);
    expect(outbox.first['operation'], 'ISSUE');
    expect(outbox.first['status'], 'deferred');
    final payload = jsonDecode(outbox.first['payload'] as String) as Map<String, dynamic>;
    expect(payload['event_type'], 'invoice_issue');
    expect(payload['invoice_number'], 'INV-2026-00001');

    await db.reset();
  });

  test('issueInvoice rejects draft with no items', () async {
    final db = await createTestDb('billing_issue_no_items');
    final database = await db.database;
    final nowIso = DateTime.now().toIso8601String();
    await database.insert('invoices', {
      'id': 'inv1',
      'business_id': 'b1',
      'status': 'draft',
      'currency_code': 'NPR',
      'fiscal_calendar_snapshot': 'AD',
      'language_snapshot': 'en',
      'vat_enabled_snapshot': 0,
      'vat_rate_snapshot': 13.0,
      'tax_mode_snapshot': 'exclusive',
      'subtotal': 0.0,
      'discount_amount': 0.0,
      'tax_amount': 0.0,
      'total': 0.0,
      'paid_amount': 0.0,
      'balance_due': 0.0,
      'pdf_status': 'none',
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    final repo = BillingRepository(db);
    await expectLater(
      repo.issueInvoice(invoiceId: 'inv1'),
      throwsA(isA<StateError>()),
    );
    await db.reset();
  });

  test('recordPayment updates paid status and rejects overpayment', () async {
    final db = await createTestDb('billing_payment');
    final repo = BillingRepository(
      db,
      billingSettingsLoader: () async => _billingSettings(vatEnabled: false),
    );

    final invoiceId = await repo.saveDraft(
      const InvoiceDraftInput(
        businessId: 'b1',
        items: [
          InvoiceDraftLineInput(
            productId: null,
            productNameSnapshot: 'Manual Service',
            unitSnapshot: 'pcs',
            quantity: 1,
            unitPrice: 500,
          ),
        ],
      ),
    );
    await repo.issueInvoice(invoiceId: invoiceId);

    await repo.recordPayment(
      invoiceId: invoiceId,
      input: const InvoicePaymentInput(amount: 200, method: 'cash'),
    );
    var invoice = await repo.getInvoiceById(invoiceId);
    expect(invoice!.status, InvoiceStatus.issued);
    expect(invoice.paidAmount, 200);
    expect(invoice.balanceDue, 300);
    final outboxAfterFirst = await (await db.database).query(
      'sync_queue',
      where: 'entity = ? AND operation = ?',
      whereArgs: ['invoice_payment', 'UPSERT'],
    );
    expect(outboxAfterFirst, isNotEmpty);
    expect(outboxAfterFirst.first['status'], 'deferred');
    final p1 = jsonDecode(outboxAfterFirst.first['payload'] as String) as Map<String, dynamic>;
    expect(p1['event_type'], 'invoice_payment');
    expect((p1['amount'] as num).toDouble(), 200);

    await repo.recordPayment(
      invoiceId: invoiceId,
      input: const InvoicePaymentInput(amount: 300, method: 'bank'),
    );
    invoice = await repo.getInvoiceById(invoiceId);
    expect(invoice!.status, InvoiceStatus.paid);
    expect(invoice.paidAmount, 500);
    expect(invoice.balanceDue, 0);

    await expectLater(
      repo.recordPayment(
        invoiceId: invoiceId,
        input: const InvoicePaymentInput(amount: 1, method: 'cash'),
      ),
      throwsA(isA<StateError>()),
    );

    await db.reset();
  });

  test('markOverdueInvoices changes issued invoices past due date', () async {
    final db = await createTestDb('billing_overdue');
    final database = await db.database;
    final now = DateTime.now();
    final oldDue = now.subtract(const Duration(days: 2)).toIso8601String();
    final nowIso = now.toIso8601String();
    await database.insert('invoices', {
      'id': 'inv-overdue',
      'business_id': 'b1',
      'invoice_number': 'INV-2026-00010',
      'status': 'issued',
      'issue_date': now.subtract(const Duration(days: 5)).toIso8601String(),
      'issue_date_ad': DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 5)).toIso8601String().substring(0, 10),
      'due_date': oldDue,
      'due_date_ad':
          now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
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
      'paid_amount': 0.0,
      'balance_due': 100.0,
      'pdf_status': 'none',
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    final repo = BillingRepository(db);
    final changed = await repo.markOverdueInvoices(now: now);
    final invoice = await repo.getInvoiceById('inv-overdue');

    expect(changed, 1);
    expect(invoice!.status, InvoiceStatus.overdue);

    await db.reset();
  });

  test('saveDraft stores due_date_ad when selected', () async {
    final db = await createTestDb('billing_due_date_ad');
    final repo = BillingRepository(
      db,
      billingSettingsLoader: () async => _billingSettings(vatEnabled: false),
    );
    final dueDate = DateTime(2026, 3, 15);

    final invoiceId = await repo.saveDraft(
      InvoiceDraftInput(
        businessId: 'b1',
        dueDateAd: dueDate,
        items: const [
          InvoiceDraftLineInput(
            productId: null,
            productNameSnapshot: 'Service',
            unitSnapshot: 'pcs',
            quantity: 1,
            unitPrice: 100,
          ),
        ],
      ),
    );

    final invoice = await repo.getInvoiceById(invoiceId);
    expect(invoice, isNotNull);
    expect(invoice!.dueDateAd, isNotNull);
    expect(invoice.dueDateAd!.year, 2026);
    expect(invoice.dueDateAd!.month, 3);
    expect(invoice.dueDateAd!.day, 15);

    await db.reset();
  });

  test('deleteDraftInvoice blocks issued invoice deletion', () async {
    final db = await createTestDb('billing_delete_rule');
    final repo = BillingRepository(
      db,
      billingSettingsLoader: () async => _billingSettings(vatEnabled: false),
    );
    final invoiceId = await repo.saveDraft(
      const InvoiceDraftInput(
        businessId: 'b1',
        items: [
          InvoiceDraftLineInput(
            productId: null,
            productNameSnapshot: 'Service',
            quantity: 1,
            unitPrice: 100,
          ),
        ],
      ),
    );
    await repo.issueInvoice(invoiceId: invoiceId);

    await expectLater(
      repo.deleteDraftInvoice(invoiceId),
      throwsA(isA<StateError>()),
    );

    await db.reset();
  });
}
