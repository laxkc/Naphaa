import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/features/sales/data/sales_repository.dart';
import 'package:sme_digital/features/sales/domain/sale_models.dart';

import '../helpers/test_db.dart';

void main() {
  test('cash sale deducts stock and queues sync event', () async {
    final db = await createTestDb('cash_sale');
    await db.seedIfEmpty();

    final database = await db.database;
    final products = await database.query('products', limit: 1);
    final productId = products.first['id'] as String;
    final beforeStock = (products.first['stock_qty'] as num).toDouble();

    final repo = SalesRepository(db);
    await repo.createSale(
      SaleInput(
        saleType: 'CASH',
        items: [SaleItemInput(productId: productId, qty: 2, unitPrice: 100)],
      ),
    );

    final productAfter = await database.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    final afterStock = (productAfter.first['stock_qty'] as num).toDouble();

    final sales = await database.query('sales');
    final queue = await database.query(
      'sync_queue',
      where: 'entity = ?',
      whereArgs: ['sale'],
    );

    expect(afterStock, beforeStock - 2);
    expect(sales.length, 1);
    expect(queue.length, 1);

    await db.reset();
  });

  test('credit sale updates customer balance', () async {
    final db = await createTestDb('credit_sale');
    await db.seedIfEmpty();

    final database = await db.database;
    final products = await database.query('products', limit: 1);
    final productId = products.first['id'] as String;

    final customerId = 'c1';
    final now = DateTime.now().toIso8601String();
    await database.insert('customers', {
      'id': customerId,
      'name': 'Ram',
      'phone': null,
      'balance': 0,
      'updated_at': now,
    });

    final repo = SalesRepository(db);
    await repo.createSale(
      SaleInput(
        saleType: 'CREDIT',
        customerId: customerId,
        items: [SaleItemInput(productId: productId, qty: 1, unitPrice: 150)],
      ),
    );

    final customers = await database.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    final balance = (customers.first['balance'] as num).toDouble();

    expect(balance, 150);

    await db.reset();
  });

  test('sale with insufficient stock throws error', () async {
    final db = await createTestDb('insufficient_stock');
    await db.seedIfEmpty();

    final database = await db.database;
    final products = await database.query('products', limit: 1);
    final productId = products.first['id'] as String;
    final stock = (products.first['stock_qty'] as num).toDouble();

    final repo = SalesRepository(db);

    await expectLater(
      repo.createSale(
        SaleInput(
          saleType: 'CASH',
          items: [
            SaleItemInput(productId: productId, qty: stock + 1, unitPrice: 100),
          ],
        ),
      ),
      throwsA(isA<StateError>()),
    );

    await db.reset();
  });
}
