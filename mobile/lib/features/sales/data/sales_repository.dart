import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/storage/local_db.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/date/business_time.dart';
import '../../../core/utils/uuid_id.dart';
import '../../products/domain/product.dart';
import '../../reports/data/metrics_repository.dart';
import '../domain/sale.dart';
import '../domain/sale_models.dart';

class SalesRepository {
  SalesRepository(
    this._db, {
    AppPreferences? preferences,
    MetricsRepository? metricsRepository,
  }) : _prefs = preferences ?? AppPreferences(),
       _metricsRepository = metricsRepository;

  final LocalDatabase _db;
  final AppPreferences _prefs;
  final MetricsRepository? _metricsRepository;

  Future<void> createSale(SaleInput input) async {
    _validateSaleInput(input);
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();

    await db.transaction((txn) async {
      final productRows = await txn.query('products');
      final products = {
        for (final row in productRows)
          row['id'] as String: Product.fromMap(row),
      };

      for (final item in input.items) {
        final product = products[item.productId];
        if (product == null) {
          throw StateError('Product missing');
        }
        if (product.stockQty < item.qty) {
          throw StateError('Insufficient stock for ${product.name}');
        }
      }

      final saleId = _id();
      final now = BusinessTime.nowUtcIso();
      final timezone = await _prefs.getBusinessTimezone();
      final saleDateAd = BusinessTime.businessDateAd(timezone: timezone);
      await txn.insert('sales', {
        'id': saleId,
        'sale_type': input.saleType,
        'payment_method': paymentMethodToApi(
          input.paymentMethod ?? PaymentMethod.cash,
        ),
        'customer_id': input.customerId,
        'total_amount': input.totalAmount,
        'sale_date_ad': saleDateAd,
        'status': 'completed',
        'created_at': now,
      });

      for (final item in input.items) {
        final product = products[item.productId]!;
        final nextQty = product.stockQty - item.qty;

        await txn.update(
          'products',
          {'stock_qty': nextQty, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        await txn.insert('stock_movements', {
          'id': _id(),
          'product_id': item.productId,
          'movement_type': 'SALE',
          'delta_qty': -item.qty,
          'reference_id': saleId,
          'created_at': now,
        });

        await txn.insert('sale_items', {
          'id': _id(),
          'sale_id': saleId,
          'product_id': item.productId,
          'qty': item.qty,
          'unit_price': item.unitPrice,
          'line_total': item.lineTotal,
        });
      }

      if (input.payments.isEmpty) {
        await txn.insert('sale_payments', {
          'id': _id(),
          'sale_id': saleId,
          'method': paymentMethodToApi(
            input.paymentMethod ??
                (input.saleType == 'CREDIT'
                    ? PaymentMethod.credit
                    : PaymentMethod.cash),
          ),
          'amount': input.totalAmount,
          'created_at': now,
        });
      } else {
        for (final payment in input.payments) {
          await txn.insert('sale_payments', {
            'id': _id(),
            'sale_id': saleId,
            'method': paymentMethodToApi(payment.method),
            'amount': payment.amount,
            'created_at': now,
          });
        }
      }

      if (input.creditAmount > 0 && input.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [input.creditAmount, now, input.customerId],
        );
      }

      await txn.insert('sync_queue', {
        'op_id': _id(),
        'store_id': activeStoreId,
        'entity': 'sale',
        'entity_id': saleId,
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': saleId,
          'sale_type': input.saleType,
          'payment_method': paymentMethodToApi(
            input.paymentMethod ?? PaymentMethod.cash,
          ),
          'customer_id': input.customerId,
          'total_amount': input.totalAmount,
          'sale_date_ad': saleDateAd,
          'status': 'completed',
          'created_at': now,
          'items': [
            for (final item in input.items)
              {
                'product_id': item.productId,
                'qty': item.qty,
                'unit_price': item.unitPrice,
              },
          ],
          if (input.payments.isNotEmpty)
            'payments': [
              for (final payment in input.payments)
                {
                  'method': paymentMethodToApi(payment.method),
                  'amount': payment.amount,
                },
            ],
        }),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
    });
    await _refreshLocalIntelligence();
  }

  Future<void> voidSale({
    required String saleId,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw StateError('Reason is required');
    }
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    await db.transaction((txn) async {
      final saleRows = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      if (saleRows.isEmpty) throw StateError('Sale not found');
      final sale = saleRows.first;
      final status = (sale['status']?.toString() ?? 'completed').toLowerCase();
      if (status == 'void') {
        throw StateError('Sale is already voided');
      }
      if (status == 'refunded' || status == 'partial') {
        throw StateError('Refunded sale cannot be voided');
      }

      final items = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      if (items.isEmpty) throw StateError('Sale has no items');
      final now = BusinessTime.nowUtcIso();
      for (final raw in items) {
        final productId = raw['product_id']?.toString();
        final qty = (raw['qty'] as num?)?.toDouble() ?? 0;
        if (productId == null || productId.isEmpty || qty <= 0) continue;
        await txn.rawUpdate(
          '''
          UPDATE products
          SET stock_qty = COALESCE(stock_qty, 0) + ?,
              updated_at = ?
          WHERE id = ?
          ''',
          [qty, now, productId],
        );
        await txn.insert('stock_movements', {
          'id': _id(),
          'product_id': productId,
          'movement_type': 'VOID',
          'delta_qty': qty,
          'reference_id': saleId,
          'created_at': now,
        });
      }

      final customerId = sale['customer_id']?.toString();
      final creditAmount = await _creditPaymentTotal(txn, saleId);
      if (customerId != null && customerId.isNotEmpty && creditAmount > 0) {
        await txn.rawUpdate(
          '''
          UPDATE customers
          SET balance = MAX(COALESCE(balance, 0) - ?, 0),
              updated_at = ?
          WHERE id = ?
          ''',
          [creditAmount, now, customerId],
        );
      }

      await txn.update(
        'sales',
        {'status': 'void', 'total_amount': 0.0},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      await _enqueueDeferredSync(
        txn,
        storeId: activeStoreId,
        entity: 'sale_void',
        entityId: saleId,
        operation: 'UPSERT',
        payload: {
          'schema_version': 1,
          'id': _id(),
          'sale_id': saleId,
          'reason': cleanReason,
          'created_at': now,
          'credit_reversal_amount': creditAmount,
        },
        now: now,
      );
    });
    await _refreshLocalIntelligence();
  }

  Future<void> refundSale({
    required String saleId,
    required String reason,
    Map<String, double>? itemQtyBySaleItemId,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw StateError('Reason is required');
    }
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    await db.transaction((txn) async {
      final saleRows = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      if (saleRows.isEmpty) throw StateError('Sale not found');
      final sale = saleRows.first;
      final saleStatus =
          (sale['status']?.toString() ?? 'completed').toLowerCase();
      if (saleStatus == 'void') {
        throw StateError('Voided sale cannot be refunded');
      }
      final previousTotal = (sale['total_amount'] as num?)?.toDouble() ?? 0;
      if (previousTotal <= 0) {
        throw StateError('Sale has no refundable amount');
      }

      final items = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      if (items.isEmpty) throw StateError('Sale has no items');

      final soldByProduct = <String, double>{};
      for (final raw in items) {
        final productId = raw['product_id']?.toString();
        if (productId == null || productId.isEmpty) continue;
        soldByProduct[productId] =
            (soldByProduct[productId] ?? 0) +
            ((raw['qty'] as num?)?.toDouble() ?? 0);
      }
      final refundedRows = await txn.rawQuery(
        '''
        SELECT product_id, COALESCE(SUM(qty), 0) AS total
        FROM sale_refund_items
        WHERE sale_id = ?
        GROUP BY product_id
        ''',
        [saleId],
      );
      final refundedByProduct = <String, double>{
        for (final row in refundedRows)
          (row['product_id']?.toString() ?? ''):
              (row['total'] as num).toDouble(),
      };
      final remainingByProduct = <String, double>{
        for (final entry in soldByProduct.entries)
          entry.key: entry.value - (refundedByProduct[entry.key] ?? 0),
      };

      final selected = <Map<String, dynamic>>[];
      for (final raw in items) {
        final itemId = raw['id']?.toString();
        final productId = raw['product_id']?.toString();
        final soldQty = (raw['qty'] as num?)?.toDouble() ?? 0;
        final unitPrice = (raw['unit_price'] as num?)?.toDouble() ?? 0;
        if (itemId == null ||
            itemId.isEmpty ||
            productId == null ||
            productId.isEmpty ||
            soldQty <= 0) {
          continue;
        }
        final requestedQty =
            itemQtyBySaleItemId == null
                ? soldQty
                : (itemQtyBySaleItemId[itemId] ?? 0);
        if (requestedQty <= 0) continue;
        final remainingQty = remainingByProduct[productId] ?? 0;
        if (requestedQty - remainingQty > 0.0001) {
          throw StateError('Refund quantity exceeds refundable quantity');
        }
        remainingByProduct[productId] = remainingQty - requestedQty;
        selected.add({
          'sale_item_id': itemId,
          'product_id': productId,
          'qty': requestedQty,
          'unit_price': unitPrice,
          'line_total': requestedQty * unitPrice,
        });
      }
      if (selected.isEmpty) {
        throw StateError('No refundable items selected');
      }

      final now = BusinessTime.nowUtcIso();
      final timezone = await _prefs.getBusinessTimezone();
      final refundDateAd = BusinessTime.businessDateAd(timezone: timezone);
      final refundId = _id();
      final refundTotal = selected.fold<double>(
        0,
        (sum, row) => sum + ((row['line_total'] as num?)?.toDouble() ?? 0),
      );
      await txn.insert('sale_refunds', {
        'id': refundId,
        'sale_id': saleId,
        'amount': refundTotal,
        'credit_refund_amount': 0.0,
        'reason': cleanReason,
        'refund_date_ad': refundDateAd,
        'created_at': now,
      });

      for (final row in selected) {
        final productId = row['product_id'] as String;
        final qty = (row['qty'] as num).toDouble();
        final unitPrice = (row['unit_price'] as num).toDouble();
        final lineTotal = (row['line_total'] as num).toDouble();
        await txn.insert('sale_refund_items', {
          'id': _id(),
          'refund_id': refundId,
          'sale_id': saleId,
          'product_id': productId,
          'qty': qty,
          'unit_price': unitPrice,
          'line_total': lineTotal,
        });
        await txn.rawUpdate(
          '''
          UPDATE products
          SET stock_qty = COALESCE(stock_qty, 0) + ?,
              updated_at = ?
          WHERE id = ?
          ''',
          [qty, now, productId],
        );
        await txn.insert('stock_movements', {
          'id': _id(),
          'product_id': productId,
          'movement_type': 'RETURN',
          'delta_qty': qty,
          'reference_id': refundId,
          'created_at': now,
        });
      }

      final soldQtyAllRaw = await txn.rawQuery(
        'SELECT COALESCE(SUM(qty), 0) AS total FROM sale_items WHERE sale_id = ?',
        [saleId],
      );
      final refundedQtyAllRaw = await txn.rawQuery(
        'SELECT COALESCE(SUM(qty), 0) AS total FROM sale_refund_items WHERE sale_id = ?',
        [saleId],
      );
      final soldQtyAll =
          (soldQtyAllRaw.first['total'] as num?)?.toDouble() ?? 0;
      final refundedQtyAll =
          (refundedQtyAllRaw.first['total'] as num?)?.toDouble() ?? 0;
      final nextStatus =
          refundedQtyAll >= (soldQtyAll - 0.0001) ? 'refunded' : 'partial';
      final nextTotal = (previousTotal - refundTotal).clamp(
        0.0,
        double.infinity,
      );
      await txn.update(
        'sales',
        {'status': nextStatus, 'total_amount': nextTotal},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      final customerId = sale['customer_id']?.toString();
      final creditTotal = await _creditPaymentTotal(txn, saleId);
      var creditRefundAmount = 0.0;
      if (customerId != null &&
          customerId.isNotEmpty &&
          creditTotal > 0 &&
          previousTotal > 0) {
        creditRefundAmount = refundTotal * (creditTotal / previousTotal);
        final customerRows = await txn.query(
          'customers',
          columns: ['balance'],
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );
        if (customerRows.isNotEmpty) {
          final currentBalance =
              (customerRows.first['balance'] as num?)?.toDouble() ?? 0;
          if (creditRefundAmount > currentBalance) {
            creditRefundAmount = currentBalance;
          }
        }
        if (creditRefundAmount > 0) {
          await txn.rawUpdate(
            '''
            UPDATE customers
            SET balance = MAX(COALESCE(balance, 0) - ?, 0),
                updated_at = ?
            WHERE id = ?
            ''',
            [creditRefundAmount, now, customerId],
          );
        }
      }
      await txn.update(
        'sale_refunds',
        {'credit_refund_amount': creditRefundAmount},
        where: 'id = ?',
        whereArgs: [refundId],
      );

      await _enqueueDeferredSync(
        txn,
        storeId: activeStoreId,
        entity: 'sale_refund',
        entityId: refundId,
        operation: 'UPSERT',
        payload: {
          'schema_version': 1,
          'id': refundId,
          'refund_id': refundId,
          'sale_id': saleId,
          'amount': refundTotal,
          'reason': cleanReason,
          'refund_date_ad': refundDateAd,
          'credit_refund_amount': creditRefundAmount,
          'created_at': now,
          'items': selected,
        },
        now: now,
      );
    });
    await _refreshLocalIntelligence();
  }

  Future<double> todaySalesTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM sales
      WHERE sale_date_ad = ?
        AND COALESCE(status, 'completed') != 'void'
      ''',
      [
        BusinessTime.businessDateAd(
          timezone: await _prefs.getBusinessTimezone(),
        ),
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> todayExpenseTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE expense_date_ad = ?',
      [
        BusinessTime.businessDateAd(
          timezone: await _prefs.getBusinessTimezone(),
        ),
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> creditOutstanding() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(balance), 0) AS total FROM customers',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Sale>> listSales({
    DateTime? fromDate,
    DateTime? toDate,
    String? customerId,
  }) async {
    final db = await _db.database;
    String where = '1=1';
    final args = <dynamic>[];
    if (customerId != null) {
      where += ' AND s.customer_id = ?';
      args.add(customerId);
    }
    if (fromDate != null) {
      where += ' AND s.sale_date_ad >= ?';
      args.add(BusinessTime.formatDateOnly(fromDate));
    }
    if (toDate != null) {
      where += ' AND s.sale_date_ad <= ?';
      args.add(
        BusinessTime.formatDateOnly(
          toDate.subtract(const Duration(milliseconds: 1)),
        ),
      );
    }
    final rows = await db.rawQuery('''
      SELECT s.*, c.name as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE $where
      ORDER BY s.sale_date_ad DESC, s.created_at DESC
    ''', args);
    return rows.map((r) => Sale.fromMap(r)).toList();
  }

  Future<Sale?> getSaleById(String id) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT s.*, c.name as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
    ''',
      [id],
    );
    if (rows.isEmpty) return null;
    final sale = Sale.fromMap(rows.first);

    final itemRows = await db.rawQuery(
      '''
      SELECT si.*, p.name as product_name
      FROM sale_items si
      LEFT JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
    ''',
      [id],
    );
    final items = itemRows.map((r) => SaleItem.fromMap(r)).toList();

    final paymentRows = await db.rawQuery(
      'SELECT * FROM sale_payments WHERE sale_id = ?',
      [id],
    );
    final payments = paymentRows.map((r) => SalePayment.fromMap(r)).toList();

    return Sale(
      id: sale.id,
      totalAmount: sale.totalAmount,
      saleType: sale.saleType,
      paymentMethod: sale.paymentMethod,
      createdAt: sale.createdAt,
      saleDateAd: sale.saleDateAd,
      customerId: sale.customerId,
      customerName: sale.customerName,
      status: sale.status,
      items: items,
      payments: payments,
      note: sale.note,
    );
  }

  String _id() => newUuidV4();

  void _validateSaleInput(SaleInput input) {
    final saleType = input.saleType.trim().toUpperCase();
    if (saleType != 'CASH' && saleType != 'CREDIT' && saleType != 'MIXED') {
      throw StateError('Invalid sale type');
    }
    if (input.items.isEmpty) {
      throw StateError('Sale must contain at least one item');
    }
    if (saleType == 'CREDIT' &&
        (input.customerId == null || input.customerId!.trim().isEmpty)) {
      throw StateError('Customer is required for credit sale');
    }

    for (final item in input.items) {
      if (item.productId.trim().isEmpty) {
        throw StateError('Sale item product is required');
      }
      if (item.qty <= 0) {
        throw StateError('Sale item quantity must be greater than zero');
      }
      if (item.unitPrice < 0) {
        throw StateError('Sale item price cannot be negative');
      }
    }

    if (input.payments.isNotEmpty) {
      var paidTotal = 0.0;
      for (final payment in input.payments) {
        if (payment.amount <= 0) {
          throw StateError('Payment amount must be greater than zero');
        }
        paidTotal += payment.amount;
      }
      if ((paidTotal - input.totalAmount).abs() > 0.01) {
        throw StateError('Payment total must equal sale total');
      }
    }
  }

  Future<void> _refreshLocalIntelligence() async {
    try {
      await _metricsRepository?.recomputeLocalCaches();
    } catch (_) {
      // Sales write path must not fail because analytics cache recompute failed.
    }
  }

  Future<double> _creditPaymentTotal(
    DatabaseExecutor txn,
    String saleId,
  ) async {
    final rows = await txn.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM sale_payments
      WHERE sale_id = ?
        AND UPPER(COALESCE(method, '')) = 'CREDIT'
      ''',
      [saleId],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _enqueueDeferredSync(
    DatabaseExecutor txn, {
    required String? storeId,
    required String entity,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required String now,
  }) async {
    final cleanStoreId = (storeId ?? '').trim();
    if (cleanStoreId.isEmpty) return;
    await txn.insert('sync_queue', {
      'op_id': _id(),
      'store_id': cleanStoreId,
      'entity': entity,
      'entity_id': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': now,
      'updated_at': now,
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
      'last_error': null,
    });
  }
}
