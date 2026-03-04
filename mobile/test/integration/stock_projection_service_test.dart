import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/storage/stock_projection_service.dart';

import '../helpers/test_db.dart';

void main() {
  test(
    'reconcile backfills missing stock movements from historical rows',
    () async {
      final localDb = await createTestDb('stock_projection_backfill_missing');
      final db = await localDb.database;
      final now = DateTime.now().toIso8601String();

      await db.insert('products', {
        'id': 'p1',
        'name': 'Sugar',
        'sell_price': 100.0,
        'cost_price': 50.0,
        'stock_qty': 7.0,
        'low_stock_threshold': 2.0,
        'unit': 'piece',
        'category': null,
        'updated_at': now,
      });
      await db.insert('sales', {
        'id': 's1',
        'sale_type': 'CASH',
        'payment_method': 'CASH',
        'customer_id': null,
        'total_amount': 200.0,
        'sale_date_ad': '2026-03-04',
        'status': 'completed',
        'created_at': now,
      });
      await db.insert('sale_items', {
        'id': 'si1',
        'sale_id': 's1',
        'product_id': 'p1',
        'qty': 2.0,
        'unit_price': 100.0,
        'line_total': 200.0,
      });
      await db.insert('sale_refunds', {
        'id': 'r1',
        'sale_id': 's1',
        'amount': 100.0,
        'reason': 'return',
        'refund_date_ad': '2026-03-04',
        'created_at': now,
      });
      await db.insert('sale_refund_items', {
        'id': 'ri1',
        'refund_id': 'r1',
        'sale_id': 's1',
        'product_id': 'p1',
        'qty': 1.0,
        'unit_price': 100.0,
        'line_total': 100.0,
      });

      await db.transaction((txn) async {
        await StockProjectionService.reconcile(txn);
      });

      final movementRows = await db.query(
        'stock_movements',
        where: 'product_id = ?',
        whereArgs: ['p1'],
      );
      final movementTypes =
          movementRows.map((row) => row['movement_type'] as String).toSet();
      expect(movementRows.length, 3);
      expect(movementTypes.contains('OPENING'), isTrue);
      expect(movementTypes.contains('SALE'), isTrue);
      expect(movementTypes.contains('RETURN'), isTrue);

      final productRows = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['p1'],
      );
      expect((productRows.single['stock_qty'] as num).toDouble(), 7.0);

      await localDb.reset();
    },
  );

  test(
    'reconcile inserts opening baseline when movements exist without OPENING',
    () async {
      final localDb = await createTestDb('stock_projection_recompute_only');
      final db = await localDb.database;
      final now = DateTime.now().toIso8601String();

      await db.insert('products', {
        'id': 'p2',
        'name': 'Oil',
        'sell_price': 350.0,
        'cost_price': 200.0,
        'stock_qty': 999.0,
        'low_stock_threshold': 1.0,
        'unit': 'piece',
        'category': null,
        'updated_at': now,
      });
      await db.insert('stock_movements', {
        'id': 'm1',
        'product_id': 'p2',
        'movement_type': 'SALE',
        'delta_qty': -2.0,
        'reference_id': 'sale1',
        'created_at': now,
      });

      await db.transaction((txn) async {
        await StockProjectionService.reconcile(txn);
      });

      final productRows = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['p2'],
      );
      expect((productRows.single['stock_qty'] as num).toDouble(), 999.0);

      final movementRows = await db.query(
        'stock_movements',
        where: 'product_id = ?',
        whereArgs: ['p2'],
      );
      expect(movementRows.length, 2);
      expect(
        movementRows.where((row) => row['movement_type'] == 'OPENING').length,
        1,
      );
      final openingRow = movementRows.firstWhere(
        (row) => row['movement_type'] == 'OPENING',
      );
      expect((openingRow['delta_qty'] as num).toDouble(), 1001.0);

      await localDb.reset();
    },
  );

  test(
    'reconcile keeps cached stock equal to movement projection for all products',
    () async {
      final localDb = await createTestDb('stock_projection_consistency_all');
      final db = await localDb.database;
      final now = DateTime.now().toIso8601String();

      await db.insert('products', {
        'id': 'pa',
        'name': 'A',
        'sell_price': 10.0,
        'cost_price': 5.0,
        'stock_qty': 999.0,
        'low_stock_threshold': 0.0,
        'unit': 'piece',
        'category': null,
        'updated_at': now,
      });
      await db.insert('products', {
        'id': 'pb',
        'name': 'B',
        'sell_price': 20.0,
        'cost_price': 8.0,
        'stock_qty': 999.0,
        'low_stock_threshold': 0.0,
        'unit': 'piece',
        'category': null,
        'updated_at': now,
      });
      await db.insert('stock_movements', {
        'id': 'ma1',
        'product_id': 'pa',
        'movement_type': 'OPENING',
        'delta_qty': 10.0,
        'reference_id': 'seed',
        'created_at': now,
      });
      await db.insert('stock_movements', {
        'id': 'ma2',
        'product_id': 'pa',
        'movement_type': 'SALE',
        'delta_qty': -3.0,
        'reference_id': 's1',
        'created_at': now,
      });
      await db.insert('stock_movements', {
        'id': 'mb1',
        'product_id': 'pb',
        'movement_type': 'OPENING',
        'delta_qty': 7.0,
        'reference_id': 'seed',
        'created_at': now,
      });
      await db.insert('stock_movements', {
        'id': 'mb2',
        'product_id': 'pb',
        'movement_type': 'RETURN',
        'delta_qty': 2.0,
        'reference_id': 'r1',
        'created_at': now,
      });

      await db.transaction((txn) async {
        await StockProjectionService.reconcile(txn);
      });

      final mismatches = await db.rawQuery('''
        SELECT COUNT(*) AS total
        FROM products p
        WHERE ABS(
          COALESCE(p.stock_qty, 0) - COALESCE((
            SELECT SUM(sm.delta_qty) FROM stock_movements sm WHERE sm.product_id = p.id
          ), 0)
        ) > 0.0001
      ''');
      expect((mismatches.first['total'] as num).toInt(), 0);

      await localDb.reset();
    },
  );
}
