import 'package:sqflite/sqflite.dart';

import '../date/business_time.dart';
import '../utils/uuid_id.dart';

class StockProjectionService {
  const StockProjectionService._();

  static Future<void> reconcile(DatabaseExecutor txn) async {
    await _backfillMissingMovements(txn);
    await _recomputeCachedStock(txn);
  }

  static Future<void> _backfillMissingMovements(DatabaseExecutor txn) async {
    final products = await txn.query('products', columns: ['id', 'stock_qty']);
    for (final product in products) {
      final productId = product['id']?.toString();
      if (productId == null || productId.isEmpty) continue;

      final stats =
          (await txn.rawQuery(
            '''
        SELECT
          COUNT(*) AS total_count,
          SUM(CASE WHEN movement_type = 'OPENING' THEN 1 ELSE 0 END) AS opening_count,
          COALESCE(SUM(delta_qty), 0) AS delta_sum
        FROM stock_movements
        WHERE product_id = ?
        ''',
            [productId],
          )).first;
      final movementCount = (stats['total_count'] as num?)?.toInt() ?? 0;
      final openingCount = (stats['opening_count'] as num?)?.toInt() ?? 0;
      final existingDeltaSum = _toDouble(stats['delta_sum']);
      final currentStock = _toDouble(product['stock_qty']);
      final nowIso = BusinessTime.nowUtcIso();

      if (movementCount > 0) {
        if (openingCount == 0) {
          // Preserve current stock while enabling projection recompute:
          // opening + existing_deltas = current_stock.
          final openingQty = currentStock - existingDeltaSum;
          await txn.insert('stock_movements', {
            'id': newUuidV4(),
            'product_id': productId,
            'movement_type': 'OPENING',
            'delta_qty': openingQty,
            'reference_id': 'backfill_opening_baseline',
            'created_at': nowIso,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        continue;
      }

      final soldQty = _sumQty(
        await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(si.qty), 0) AS total
          FROM sale_items si
          JOIN sales s ON s.id = si.sale_id
          WHERE si.product_id = ?
            AND COALESCE(s.status, 'completed') != 'void'
          ''',
          [productId],
        ),
      );
      final invoiceIssuedQty = _sumQty(
        await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(ii.quantity), 0) AS total
          FROM invoice_items ii
          JOIN invoices i ON i.id = ii.invoice_id
          WHERE ii.product_id = ?
            AND COALESCE(i.status, 'draft') IN ('issued', 'paid', 'overdue')
          ''',
          [productId],
        ),
      );
      final refundQty = _sumQty(
        await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(qty), 0) AS total
          FROM sale_refund_items
          WHERE product_id = ?
          ''',
          [productId],
        ),
      );

      // Reconstruct a baseline opening quantity so that:
      // opening - sold - invoiceIssued + refunded ~= currentStock.
      var openingQty = currentStock + soldQty + invoiceIssuedQty - refundQty;
      if (openingQty < 0) openingQty = 0;
      await txn.insert('stock_movements', {
        'id': newUuidV4(),
        'product_id': productId,
        'movement_type': 'OPENING',
        'delta_qty': openingQty,
        'reference_id': 'backfill_opening',
        'created_at': nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      if (soldQty > 0) {
        await txn.insert('stock_movements', {
          'id': newUuidV4(),
          'product_id': productId,
          'movement_type': 'SALE',
          'delta_qty': -soldQty,
          'reference_id': 'backfill_sales',
          'created_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      if (invoiceIssuedQty > 0) {
        await txn.insert('stock_movements', {
          'id': newUuidV4(),
          'product_id': productId,
          'movement_type': 'INVOICE_ISSUE',
          'delta_qty': -invoiceIssuedQty,
          'reference_id': 'backfill_invoices',
          'created_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      if (refundQty > 0) {
        await txn.insert('stock_movements', {
          'id': newUuidV4(),
          'product_id': productId,
          'movement_type': 'RETURN',
          'delta_qty': refundQty,
          'reference_id': 'backfill_refunds',
          'created_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  static Future<void> _recomputeCachedStock(DatabaseExecutor txn) async {
    await txn.rawUpdate(
      '''
      UPDATE products
      SET stock_qty = COALESCE((
            SELECT SUM(sm.delta_qty)
            FROM stock_movements sm
            WHERE sm.product_id = products.id
          ), 0),
          updated_at = ?
    ''',
      [BusinessTime.nowUtcIso()],
    );
  }

  static double _sumQty(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return 0;
    return _toDouble(rows.first['total']);
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
