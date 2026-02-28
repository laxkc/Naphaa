import 'dart:convert';

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

  Future<double> todaySalesTotal() async {
    final db = await _db.database;
      final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) AS total FROM sales WHERE sale_date_ad = ?',
      [BusinessTime.businessDateAd(timezone: await _prefs.getBusinessTimezone())],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> todayExpenseTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE expense_date_ad = ?',
      [BusinessTime.businessDateAd(timezone: await _prefs.getBusinessTimezone())],
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
      createdAt: sale.createdAt,
      customerId: sale.customerId,
      customerName: sale.customerName,
      status: sale.status,
      items: items,
      payments: payments,
      note: sale.note,
    );
  }

  String _id() => newUuidV4();

  Future<void> _refreshLocalIntelligence() async {
    try {
      await _metricsRepository?.recomputeLocalCaches();
    } catch (_) {
      // Sales write path must not fail because analytics cache recompute failed.
    }
  }
}
