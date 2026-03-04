import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/date/business_time.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/utils/uuid_id.dart';
import '../domain/billing_calculator.dart';
import '../domain/invoice_models.dart';
import 'invoice_numbering_service.dart';

class BillingRepository {
  BillingRepository(
    this._db, {
    AppPreferences? preferences,
    InvoiceNumberingService? numberingService,
    Future<Map<String, dynamic>> Function()? billingSettingsLoader,
  }) : _prefs = preferences ?? AppPreferences(),
       _numbering = numberingService ?? InvoiceNumberingService(_db),
       _billingSettingsLoader = billingSettingsLoader;

  final LocalDatabase _db;
  final AppPreferences _prefs;
  final InvoiceNumberingService _numbering;
  final Future<Map<String, dynamic>> Function()? _billingSettingsLoader;

  Future<String> saveDraft(InvoiceDraftInput input) async {
    if (input.items.isEmpty)
      throw StateError('Invoice must have at least one item');

    final db = await _db.database;
    final invoiceId = newUuidV4();
    final now = BusinessTime.nowUtc();
    final nowIso = now.toIso8601String();
    final dueDateAd =
        input.dueDateAd == null
            ? null
            : BusinessTime.formatDateOnly(input.dueDateAd!);
    final settings = await _loadBillingSettings();
    final totals = _calculateTotals(
      input.items,
      input.invoiceDiscountAmount,
      settings,
    );

    await db.transaction((txn) async {
      await txn.insert('invoices', {
        'id': invoiceId,
        'business_id': input.businessId,
        'customer_id': input.customerId,
        'status': invoiceStatusToDb(InvoiceStatus.draft),
        'issue_date': null,
        'due_date':
            dueDateAd == null
                ? null
                : BusinessTime.parseAdDate(
                  dueDateAd,
                )?.toUtc().toIso8601String(),
        'issue_date_ad': null,
        'due_date_ad': dueDateAd,
        'currency_code': settings['currency_code'],
        'fiscal_calendar_snapshot': settings['fiscal_calendar'],
        'language_snapshot': settings['language'],
        'vat_enabled_snapshot': (settings['vat_enabled'] as bool) ? 1 : 0,
        'vat_rate_snapshot': (settings['vat_rate'] as num).toDouble(),
        'tax_mode_snapshot': settings['tax_mode'],
        'subtotal': totals.subtotal,
        'discount_amount': totals.discountAmount,
        'tax_amount': totals.taxAmount,
        'total': totals.total,
        'paid_amount': 0.0,
        'balance_due': totals.total,
        'payment_method_summary': null,
        'notes': input.notes,
        'terms_snapshot': settings['invoice_terms_default'],
        'footer_snapshot': settings['invoice_footer_default'],
        'business_name_snapshot': settings['business_name'],
        'business_address_snapshot': settings['business_address'],
        'business_phone_snapshot': settings['business_phone'],
        'business_email_snapshot': settings['business_email'],
        'business_pan_vat_snapshot': settings['pan_vat_number'],
        'invoice_prefix_snapshot': settings['invoice_prefix'],
        'pdf_status': 'none',
        'created_at': nowIso,
        'updated_at': nowIso,
      });

      for (var i = 0; i < input.items.length; i++) {
        final item = input.items[i];
        final line = totals.lines[i];
        await txn.insert('invoice_items', {
          'id': newUuidV4(),
          'invoice_id': invoiceId,
          'product_id': item.productId,
          'product_name_snapshot': item.productNameSnapshot,
          'unit_snapshot': item.unitSnapshot,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': line.discountAllocated,
          'tax_rate_snapshot':
              (settings['vat_enabled'] as bool)
                  ? (settings['vat_rate'] as num).toDouble()
                  : 0.0,
          'line_subtotal': line.lineSubtotal,
          'line_tax': line.lineTax,
          'line_total': line.lineTotal,
        });
      }
    });

    return invoiceId;
  }

  Future<void> issueInvoice({
    required String invoiceId,
    String? paymentMethodSummary,
  }) async {
    final db = await _db.database;
    final now = BusinessTime.nowUtc();
    final nowIso = now.toIso8601String();
    final timezone = await _prefs.getBusinessTimezone();
    final issueDateAd = BusinessTime.businessDateAd(
      timestampUtc: now,
      timezone: timezone,
    );
    final issueBusinessDate =
        BusinessTime.parseAdDate(issueDateAd) ??
        DateTime(now.year, now.month, now.day);

    await db.transaction((txn) async {
      final invoice = await _getInvoiceRow(txn, invoiceId);
      final status = invoiceStatusFromDb(
        (invoice['status'] ?? 'draft').toString(),
      );
      if (status != InvoiceStatus.draft) {
        throw StateError('Only draft invoices can be issued');
      }

      final items = await txn.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      if (items.isEmpty)
        throw StateError('Invoice must have at least one item');

      // Validate and deduct stock atomically inside the transaction.
      for (final item in items) {
        final productId = item['product_id']?.toString();
        if (productId == null || productId.isEmpty) continue;
        final productRows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (productRows.isEmpty) {
          throw StateError('Product not found for invoice item');
        }
        final product = productRows.first;
        final currentQty = (product['stock_qty'] as num?)?.toDouble() ?? 0;
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
        if (qty <= 0)
          throw StateError('Invoice item quantity must be greater than zero');
        if (currentQty < qty) {
          throw StateError(
            'Insufficient stock for ${(product['name'] ?? 'product').toString()}',
          );
        }
      }

      for (final item in items) {
        final productId = item['product_id']?.toString();
        if (productId == null || productId.isEmpty) continue;
        final productRows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        final product = productRows.first;
        final currentQty = (product['stock_qty'] as num?)?.toDouble() ?? 0;
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
        final nextQty = currentQty - qty;
        await txn.update(
          'products',
          {'stock_qty': nextQty, 'updated_at': nowIso},
          where: 'id = ?',
          whereArgs: [productId],
        );
        await txn.insert('stock_movements', {
          'id': newUuidV4(),
          'product_id': productId,
          'movement_type': 'INVOICE_ISSUE',
          'delta_qty': -qty,
          'reference_id': invoiceId,
          'created_at': nowIso,
        });
      }

      final businessId = invoice['business_id']?.toString() ?? '';
      if (businessId.isEmpty)
        throw StateError('Invoice is missing business_id');
      final prefix = invoice['invoice_prefix_snapshot']?.toString() ?? 'INV';
      final fiscalCalendar =
          invoice['fiscal_calendar_snapshot']?.toString() ?? 'AD';
      final invoiceNumber = await _numbering.reserveNextInvoiceNumber(
        txn,
        businessId: businessId,
        prefix: prefix,
        issueDateAd: issueBusinessDate,
        fiscalCalendar: fiscalCalendar,
      );

      final total = (invoice['total'] as num?)?.toDouble() ?? 0;
      final paidAmount = (invoice['paid_amount'] as num?)?.toDouble() ?? 0;
      final balanceDue = _r2(total - paidAmount);
      final nextStatus =
          balanceDue <= 0 ? InvoiceStatus.paid : InvoiceStatus.issued;

      await txn.update(
        'invoices',
        {
          'invoice_number': invoiceNumber,
          'status': invoiceStatusToDb(nextStatus),
          'issue_date': nowIso,
          'issue_date_ad': issueDateAd,
          'payment_method_summary':
              paymentMethodSummary ?? invoice['payment_method_summary'],
          'balance_due': balanceDue,
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      final issuedInvoice = await _getInvoiceRow(txn, invoiceId);
      final issuedItems = await txn.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
        orderBy: 'rowid ASC',
      );
      await _enqueueDeferredSyncEvent(
        txn,
        storeId: businessId,
        entity: 'invoice',
        entityId: invoiceId,
        operation: 'ISSUE',
        payload: {
          'schema_version': 1,
          'event_type': 'invoice_issue',
          'invoice_id': invoiceId,
          'invoice_number': invoiceNumber,
          'business_id': businessId,
          'customer_id': issuedInvoice['customer_id'],
          'status': issuedInvoice['status'],
          'issue_date': issuedInvoice['issue_date'],
          'issue_date_ad': issuedInvoice['issue_date_ad'],
          'due_date': issuedInvoice['due_date'],
          'due_date_ad': issuedInvoice['due_date_ad'],
          'currency_code': issuedInvoice['currency_code'],
          'fiscal_calendar_snapshot': issuedInvoice['fiscal_calendar_snapshot'],
          'language_snapshot': issuedInvoice['language_snapshot'],
          'subtotal': (issuedInvoice['subtotal'] as num?)?.toDouble() ?? 0.0,
          'discount_amount':
              (issuedInvoice['discount_amount'] as num?)?.toDouble() ?? 0.0,
          'tax_amount':
              (issuedInvoice['tax_amount'] as num?)?.toDouble() ?? 0.0,
          'total': (issuedInvoice['total'] as num?)?.toDouble() ?? 0.0,
          'paid_amount':
              (issuedInvoice['paid_amount'] as num?)?.toDouble() ?? 0.0,
          'balance_due':
              (issuedInvoice['balance_due'] as num?)?.toDouble() ?? 0.0,
          'payment_method_summary': issuedInvoice['payment_method_summary'],
          'items': [
            for (final row in issuedItems)
              {
                'id': row['id'],
                'product_id': row['product_id'],
                'product_name_snapshot': row['product_name_snapshot'],
                'unit_snapshot': row['unit_snapshot'],
                'quantity': (row['quantity'] as num?)?.toDouble() ?? 0.0,
                'unit_price': (row['unit_price'] as num?)?.toDouble() ?? 0.0,
                'discount': (row['discount'] as num?)?.toDouble() ?? 0.0,
                'tax_rate_snapshot':
                    (row['tax_rate_snapshot'] as num?)?.toDouble() ?? 0.0,
                'line_subtotal':
                    (row['line_subtotal'] as num?)?.toDouble() ?? 0.0,
                'line_tax': (row['line_tax'] as num?)?.toDouble() ?? 0.0,
                'line_total': (row['line_total'] as num?)?.toDouble() ?? 0.0,
              },
          ],
          'updated_at': issuedInvoice['updated_at'],
        },
        nowIso: nowIso,
      );
    });
  }

  Future<void> recordPayment({
    required String invoiceId,
    required InvoicePaymentInput input,
  }) async {
    if (input.amount <= 0)
      throw StateError('Payment amount must be greater than zero');
    final db = await _db.database;
    final paidAtDt = (input.paidAt ?? BusinessTime.nowUtc()).toUtc();
    final paidAt = paidAtDt.toIso8601String();

    await db.transaction((txn) async {
      final invoice = await _getInvoiceRow(txn, invoiceId);
      final status = invoiceStatusFromDb(
        (invoice['status'] ?? 'draft').toString(),
      );
      if (status == InvoiceStatus.cancelled) {
        throw StateError('Cancelled invoice cannot receive payment');
      }
      final total = (invoice['total'] as num?)?.toDouble() ?? 0;
      final paidAmount = (invoice['paid_amount'] as num?)?.toDouble() ?? 0;
      final nextPaid = _r2(paidAmount + input.amount);
      if (nextPaid - total > 0.0001) {
        throw StateError('Payment cannot exceed invoice total');
      }
      final balanceDue = _r2(total - nextPaid);
      final nextStatus =
          balanceDue <= 0 ? InvoiceStatus.paid : InvoiceStatus.issued;

      final paymentId = newUuidV4();
      await txn.insert('invoice_payments', {
        'id': paymentId,
        'invoice_id': invoiceId,
        'amount': _r2(input.amount),
        'method': input.method.toUpperCase(),
        'paid_at': paidAt,
        'note': input.note,
      });
      final updatedAt = BusinessTime.nowUtcIso();
      await txn.update(
        'invoices',
        {
          'paid_amount': nextPaid,
          'balance_due': balanceDue,
          'status': invoiceStatusToDb(nextStatus),
          'updated_at': updatedAt,
          'payment_method_summary': _mergePaymentMethodSummary(
            invoice['payment_method_summary']?.toString(),
            input.method,
          ),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      await _enqueueDeferredSyncEvent(
        txn,
        storeId: (invoice['business_id']?.toString() ?? '').trim(),
        entity: 'invoice_payment',
        entityId: paymentId,
        operation: 'UPSERT',
        payload: {
          'schema_version': 1,
          'event_type': 'invoice_payment',
          'id': paymentId,
          'invoice_id': invoiceId,
          'business_id': invoice['business_id'],
          'amount': _r2(input.amount),
          'method': input.method.toUpperCase(),
          'paid_at': paidAt,
          'note': input.note,
          'invoice_status': invoiceStatusToDb(nextStatus),
          'invoice_paid_amount': nextPaid,
          'invoice_balance_due': balanceDue,
          'updated_at': updatedAt,
        },
        nowIso: updatedAt,
      );
    });
  }

  Future<int> markOverdueInvoices({DateTime? now}) async {
    final db = await _db.database;
    final timezone = await _prefs.getBusinessTimezone();
    final currentAd = BusinessTime.businessDateAd(
      timestampUtc: (now ?? BusinessTime.nowUtc()).toUtc(),
      timezone: timezone,
    );
    final rows = await db.query(
      'invoices',
      columns: ['id', 'status', 'due_date_ad', 'balance_due'],
      where:
          "status IN ('issued', 'overdue') AND due_date_ad IS NOT NULL AND trim(due_date_ad) != ''",
    );
    var updated = 0;
    for (final row in rows) {
      final dueRaw = row['due_date_ad']?.toString();
      if (dueRaw == null || dueRaw.isEmpty) continue;
      final balance = (row['balance_due'] as num?)?.toDouble() ?? 0;
      if (balance <= 0) continue;
      if (dueRaw.compareTo(currentAd) < 0) {
        await db.update(
          'invoices',
          {
            'status': invoiceStatusToDb(InvoiceStatus.overdue),
            'updated_at': BusinessTime.nowUtcIso(),
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        updated += 1;
      }
    }
    return updated;
  }

  Future<void> deleteDraftInvoice(String invoiceId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final invoice = await _getInvoiceRow(txn, invoiceId);
      final status = invoiceStatusFromDb(
        (invoice['status'] ?? 'draft').toString(),
      );
      if (status != InvoiceStatus.draft) {
        throw StateError('Only draft invoices can be deleted');
      }
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      await txn.delete(
        'invoice_payments',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      await txn.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  Future<InvoiceRecord?> getInvoiceById(String invoiceId) async {
    final db = await _db.database;
    final rows = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return InvoiceRecord.fromMap(rows.first);
  }

  Future<List<InvoiceRecord>> listInvoices({
    String? businessId,
    InvoiceStatus? status,
  }) async {
    final db = await _db.database;
    final clauses = <String>[];
    final args = <Object?>[];
    if (businessId != null && businessId.isNotEmpty) {
      clauses.add('business_id = ?');
      args.add(businessId);
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(invoiceStatusToDb(status));
    }
    final rows = await db.query(
      'invoices',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: clauses.isEmpty ? null : args,
      orderBy:
          'COALESCE(issue_date_ad, substr(created_at, 1, 10)) DESC, created_at DESC',
    );
    return rows.map(InvoiceRecord.fromMap).toList();
  }

  Future<List<InvoiceItemRecord>> getInvoiceItems(String invoiceId) async {
    final db = await _db.database;
    final rows = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'rowid ASC',
    );
    return rows.map(InvoiceItemRecord.fromMap).toList();
  }

  Future<List<InvoicePaymentRecord>> getInvoicePayments(
    String invoiceId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'invoice_payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'paid_at DESC',
    );
    return rows.map(InvoicePaymentRecord.fromMap).toList();
  }

  Future<void> updateInvoicePdfArtifact({
    required String invoiceId,
    String? pdfPath,
    required String pdfStatus,
  }) async {
    final db = await _db.database;
    await db.update(
      'invoices',
      {
        'pdf_path': pdfPath,
        'pdf_status': pdfStatus,
        'updated_at': BusinessTime.nowUtcIso(),
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<void> _enqueueDeferredSyncEvent(
    DatabaseExecutor txn, {
    required String storeId,
    required String entity,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required String nowIso,
  }) async {
    if (storeId.isEmpty) return;
    await txn.insert('sync_queue', {
      'op_id': newUuidV4(),
      'store_id': storeId,
      'entity': entity,
      'entity_id': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': nowIso,
      'updated_at': nowIso,
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
      'last_error': null,
    });
  }

  BillingTotalsResult _calculateTotals(
    List<InvoiceDraftLineInput> items,
    double invoiceDiscountAmount,
    Map<String, dynamic> settings,
  ) {
    final taxMode =
        (settings['tax_mode']?.toString().toLowerCase() == 'inclusive')
            ? BillingTaxMode.inclusive
            : BillingTaxMode.exclusive;
    return BillingCalculator.calculate(
      lines: items.map((e) => e.toBillingLine()).toList(),
      vatEnabled: (settings['vat_enabled'] as bool?) ?? false,
      vatRatePercent: (settings['vat_rate'] as num?)?.toDouble() ?? 13.0,
      taxMode: taxMode,
      invoiceDiscountAmount: invoiceDiscountAmount,
    );
  }

  Future<Map<String, dynamic>> _loadBillingSettings() async {
    if (_billingSettingsLoader != null) return _billingSettingsLoader.call();
    return _prefs.getBillingSettings();
  }

  Future<Map<String, dynamic>> _getInvoiceRow(
    DatabaseExecutor txn,
    String invoiceId,
  ) async {
    final rows = await txn.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Invoice not found');
    return rows.first;
  }

  String _mergePaymentMethodSummary(String? existing, String incoming) {
    final next = incoming.trim().toUpperCase();
    if (next.isEmpty) return existing ?? '';
    final current = (existing ?? '').trim().toUpperCase();
    if (current.isEmpty) return next;
    if (current == next) return current;
    if (current == 'MIXED') return current;
    return 'MIXED';
  }

  double _r2(double v) => (v * 100).roundToDouble() / 100;
}
