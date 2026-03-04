import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/features/sales/data/sales_repository.dart';
import 'package:sme_digital/features/sales/domain/sale_models.dart';

import '../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    final stockMovements = await database.query(
      'stock_movements',
      where: 'product_id = ? AND movement_type = ?',
      whereArgs: [productId, 'SALE'],
    );

    expect(afterStock, beforeStock - 2);
    expect(sales.length, 1);
    expect(queue.length, 1);
    expect(stockMovements.length, 1);
    expect((stockMovements.first['delta_qty'] as num).toDouble(), -2);

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

  test('sale with empty items is rejected', () async {
    final db = await createTestDb('sale_empty_items_rejected');
    await db.seedIfEmpty();

    final repo = SalesRepository(db);
    await expectLater(
      repo.createSale(SaleInput(saleType: 'CASH', items: const [])),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('at least one item'),
        ),
      ),
    );

    await db.reset();
  });

  test('credit sale without customer is rejected', () async {
    final db = await createTestDb('credit_without_customer_rejected');
    await db.seedIfEmpty();

    final database = await db.database;
    final products = await database.query('products', limit: 1);
    final productId = products.first['id'] as String;

    final repo = SalesRepository(db);
    await expectLater(
      repo.createSale(
        SaleInput(
          saleType: 'CREDIT',
          items: [SaleItemInput(productId: productId, qty: 1, unitPrice: 100)],
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Customer is required for credit sale'),
        ),
      ),
    );

    await db.reset();
  });

  test('sale payment total mismatch is rejected', () async {
    final db = await createTestDb('sale_payment_mismatch_rejected');
    await db.seedIfEmpty();

    final database = await db.database;
    final products = await database.query('products', limit: 1);
    final productId = products.first['id'] as String;

    final repo = SalesRepository(db);
    await expectLater(
      repo.createSale(
        SaleInput(
          saleType: 'MIXED',
          items: [SaleItemInput(productId: productId, qty: 1, unitPrice: 200)],
          payments: [
            SalePaymentInput(method: PaymentMethod.cash, amount: 50),
            SalePaymentInput(method: PaymentMethod.qr, amount: 100),
          ],
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Payment total must equal sale total'),
        ),
      ),
    );

    await db.reset();
  });

  test('mixed payment sale is saved with split payment rows', () async {
    final db = await createTestDb('mixed_payment_sale_saved');
    await db.seedIfEmpty();

    final database = await db.database;
    final products = await database.query('products', limit: 1);
    final productId = products.first['id'] as String;

    final repo = SalesRepository(db);
    await repo.createSale(
      SaleInput(
        saleType: 'MIXED',
        paymentMethod: PaymentMethod.mixed,
        items: [SaleItemInput(productId: productId, qty: 1, unitPrice: 200)],
        payments: [
          SalePaymentInput(method: PaymentMethod.cash, amount: 120),
          SalePaymentInput(method: PaymentMethod.qr, amount: 80),
        ],
      ),
    );

    final sales = await database.query('sales');
    expect(sales, hasLength(1));
    expect(sales.first['sale_type'], 'MIXED');
    expect(sales.first['payment_method'], 'MIXED');

    final saleId = sales.first['id'] as String;
    final paymentRows = await database.query(
      'sale_payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    expect(paymentRows, hasLength(2));
    final methods = paymentRows.map((e) => e['method'] as String).toSet();
    expect(methods.contains('CASH'), isTrue);
    expect(methods.contains('QR'), isTrue);

    await db.reset();
  });

  test(
    'void sale restores stock and reverses customer credit balance',
    () async {
      final db = await createTestDb('void_sale_restores_state');
      await db.seedIfEmpty();
      final database = await db.database;
      final product = (await database.query('products', limit: 1)).first;
      final productId = product['id'] as String;
      final beforeStock = (product['stock_qty'] as num).toDouble();
      final customerId = 'void-customer';
      final now = DateTime.now().toIso8601String();
      await database.insert('customers', {
        'id': customerId,
        'name': 'Void Customer',
        'phone': null,
        'balance': 0.0,
        'updated_at': now,
      });

      final repo = SalesRepository(db);
      await repo.createSale(
        SaleInput(
          saleType: 'CREDIT',
          customerId: customerId,
          items: [SaleItemInput(productId: productId, qty: 2, unitPrice: 100)],
        ),
      );
      final sale = (await database.query('sales', limit: 1)).single;
      final saleId = sale['id'] as String;

      await repo.voidSale(saleId: saleId, reason: 'Entry mistake');

      final productAfter = await database.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      expect((productAfter.single['stock_qty'] as num).toDouble(), beforeStock);

      final saleAfter = await database.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      expect(saleAfter.single['status'], 'void');
      expect((saleAfter.single['total_amount'] as num).toDouble(), 0.0);

      final customerAfter = await database.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      expect((customerAfter.single['balance'] as num).toDouble(), 0.0);

      final movementRows = await database.query(
        'stock_movements',
        where: 'product_id = ? AND movement_type = ? AND reference_id = ?',
        whereArgs: [productId, 'VOID', saleId],
      );
      expect(movementRows, hasLength(1));
      expect((movementRows.single['delta_qty'] as num).toDouble(), 2.0);

      await db.reset();
    },
  );

  test(
    'partial refund updates sale totals, stock, and customer balance',
    () async {
      final db = await createTestDb('partial_refund_updates_state');
      await db.seedIfEmpty();
      final database = await db.database;
      final product = (await database.query('products', limit: 1)).first;
      final productId = product['id'] as String;
      final beforeStock = (product['stock_qty'] as num).toDouble();
      final customerId = 'refund-customer';
      final now = DateTime.now().toIso8601String();
      await database.insert('customers', {
        'id': customerId,
        'name': 'Refund Customer',
        'phone': null,
        'balance': 0.0,
        'updated_at': now,
      });

      final repo = SalesRepository(db);
      await repo.createSale(
        SaleInput(
          saleType: 'CREDIT',
          customerId: customerId,
          items: [SaleItemInput(productId: productId, qty: 2, unitPrice: 100)],
        ),
      );
      final sale = (await database.query('sales', limit: 1)).single;
      final saleId = sale['id'] as String;
      final saleItem =
          (await database.query(
            'sale_items',
            where: 'sale_id = ?',
            whereArgs: [saleId],
            limit: 1,
          )).single;
      final saleItemId = saleItem['id'] as String;

      await repo.refundSale(
        saleId: saleId,
        reason: 'Damaged pack returned',
        itemQtyBySaleItemId: {saleItemId: 1.0},
      );

      final saleAfter = await database.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      expect(saleAfter.single['status'], 'partial');
      expect((saleAfter.single['total_amount'] as num).toDouble(), 100.0);

      final productAfter = await database.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      expect(
        (productAfter.single['stock_qty'] as num).toDouble(),
        beforeStock - 1.0,
      );

      final customerAfter = await database.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      expect((customerAfter.single['balance'] as num).toDouble(), 100.0);

      final refunds = await database.query(
        'sale_refunds',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      expect(refunds, hasLength(1));
      expect((refunds.single['amount'] as num).toDouble(), 100.0);

      final refundId = refunds.single['id'] as String;
      final movementRows = await database.query(
        'stock_movements',
        where: 'product_id = ? AND movement_type = ? AND reference_id = ?',
        whereArgs: [productId, 'RETURN', refundId],
      );
      expect(movementRows, hasLength(1));
      expect((movementRows.single['delta_qty'] as num).toDouble(), 1.0);

      await db.reset();
    },
  );
}
