import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/features/products/data/products_repository.dart';

import '../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'stock adjustment with DAMAGE reason writes LOSS movement type',
    () async {
      final db = await createTestDb('product_adjust_damage_loss_movement');
      await db.seedIfEmpty();
      final database = await db.database;
      final productId =
          (await database.query('products', limit: 1)).first['id'] as String;

      final repo = ProductsRepository(db);
      await repo.adjustStock(productId: productId, delta: -1, reason: 'DAMAGE');

      final movementRows = await database.query(
        'stock_movements',
        where: 'product_id = ? AND movement_type = ?',
        whereArgs: [productId, 'LOSS'],
        orderBy: 'created_at DESC, id DESC',
        limit: 1,
      );
      expect(movementRows, hasLength(1));
      expect(movementRows.first['movement_type'], 'LOSS');
      expect((movementRows.first['delta_qty'] as num).toDouble(), -1);

      await db.reset();
    },
  );

  test(
    'stock adjustment with RETURN reason writes RETURN movement type',
    () async {
      final db = await createTestDb('product_adjust_return_movement');
      await db.seedIfEmpty();
      final database = await db.database;
      final productId =
          (await database.query('products', limit: 1)).first['id'] as String;

      final repo = ProductsRepository(db);
      await repo.adjustStock(productId: productId, delta: 2, reason: 'RETURN');

      final movementRows = await database.query(
        'stock_movements',
        where: 'product_id = ? AND movement_type = ?',
        whereArgs: [productId, 'RETURN'],
        orderBy: 'created_at DESC, id DESC',
        limit: 1,
      );
      expect(movementRows, hasLength(1));
      expect(movementRows.first['movement_type'], 'RETURN');
      expect((movementRows.first['delta_qty'] as num).toDouble(), 2);

      await db.reset();
    },
  );

  test(
    'recentProducts prioritizes recently sold products over merely updated products',
    () async {
      final localDb = await createTestDb(
        'products_recent_ranks_by_recent_sales',
      );
      addTearDown(localDb.reset);
      final db = await localDb.database;
      final repo = ProductsRepository(localDb);

      await db.insert('products', {
        'id': 'p-old-sold',
        'name': 'Old Sold',
        'sell_price': 100.0,
        'cost_price': 50.0,
        'stock_qty': 5.0,
        'low_stock_threshold': 0.0,
        'unit': 'piece',
        'updated_at': '2026-03-04T10:00:00.000Z',
      });
      await db.insert('products', {
        'id': 'p-new-unsold',
        'name': 'New Unsold',
        'sell_price': 100.0,
        'cost_price': 50.0,
        'stock_qty': 5.0,
        'low_stock_threshold': 0.0,
        'unit': 'piece',
        'updated_at': '2026-03-04T12:00:00.000Z',
      });
      await db.insert('sales', {
        'id': 's-1',
        'sale_type': 'CASH',
        'payment_method': 'CASH',
        'customer_id': null,
        'total_amount': 100.0,
        'sale_date_ad': '2026-03-04',
        'status': 'completed',
        'created_at': '2026-03-04T11:30:00.000Z',
      });
      await db.insert('sale_items', {
        'id': 'si-1',
        'sale_id': 's-1',
        'product_id': 'p-old-sold',
        'qty': 1.0,
        'unit_price': 100.0,
        'line_total': 100.0,
      });

      final recent = await repo.recentProducts();
      expect(recent, isNotEmpty);
      expect(recent.first.id, 'p-old-sold');
    },
  );

  test('searchProducts ranks exact and prefix matches first', () async {
    final localDb = await createTestDb('products_search_ranking_priority');
    addTearDown(localDb.reset);
    final db = await localDb.database;
    final repo = ProductsRepository(localDb);

    await db.insert('products', {
      'id': 'p-exact',
      'name': 'Alp',
      'sell_price': 100.0,
      'cost_price': 50.0,
      'stock_qty': 3.0,
      'low_stock_threshold': 0.0,
      'unit': 'piece',
      'updated_at': '2026-03-04T10:00:00.000Z',
    });
    await db.insert('products', {
      'id': 'p-prefix',
      'name': 'Alpine',
      'sell_price': 100.0,
      'cost_price': 50.0,
      'stock_qty': 3.0,
      'low_stock_threshold': 0.0,
      'unit': 'piece',
      'updated_at': '2026-03-04T10:01:00.000Z',
    });
    await db.insert('products', {
      'id': 'p-contains',
      'name': 'Cool Alp Mix',
      'sell_price': 100.0,
      'cost_price': 50.0,
      'stock_qty': 3.0,
      'low_stock_threshold': 0.0,
      'unit': 'piece',
      'updated_at': '2026-03-04T10:02:00.000Z',
    });

    final result = await repo.searchProducts('alp');
    expect(result.length, greaterThanOrEqualTo(3));
    expect(result[0].id, 'p-exact');
    expect(result[1].id, 'p-prefix');
    expect(result[2].id, 'p-contains');
  });
}
