import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/features/sales/data/sales_repository.dart';
import 'package:sme_digital/features/sales/domain/sale_models.dart';

import '../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'active_store_id': 'test-store-id',
    });
  });

  test(
    'integration: void cash sale restores stock and zeroes sale amount',
    () async {
      final db = await createTestDb('integration_void_cash_sale');
      await db.seedIfEmpty();
      final database = await db.database;
      final product = (await database.query('products', limit: 1)).single;
      final productId = product['id'] as String;
      final beforeStock = (product['stock_qty'] as num).toDouble();

      final repo = SalesRepository(db);
      await repo.createSale(
        SaleInput(
          saleType: 'CASH',
          items: [SaleItemInput(productId: productId, qty: 2, unitPrice: 100)],
        ),
      );
      final sale = (await database.query('sales', limit: 1)).single;
      final saleId = sale['id'] as String;

      await repo.voidSale(saleId: saleId, reason: 'Wrong bill');

      final afterProduct = await database.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      expect((afterProduct.single['stock_qty'] as num).toDouble(), beforeStock);

      final afterSale = await database.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      expect(afterSale.single['status'], 'void');
      expect((afterSale.single['total_amount'] as num).toDouble(), 0.0);

      final queueRows = await database.query(
        'sync_queue',
        where: 'entity = ? AND entity_id = ?',
        whereArgs: ['sale_void', saleId],
      );
      expect(queueRows, isNotEmpty);

      await db.reset();
    },
  );

  test(
    'integration: partial return of credit sale balances stock and receivable',
    () async {
      final db = await createTestDb('integration_partial_return_credit_sale');
      await db.seedIfEmpty();
      final database = await db.database;
      final product = (await database.query('products', limit: 1)).single;
      final productId = product['id'] as String;
      final beforeStock = (product['stock_qty'] as num).toDouble();

      final customerId = 'integration-credit-customer';
      final now = DateTime.now().toIso8601String();
      await database.insert('customers', {
        'id': customerId,
        'name': 'Integration Credit Customer',
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
        reason: 'Customer returned one unit',
        itemQtyBySaleItemId: {saleItemId: 1.0},
      );

      final afterSale = await database.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      expect(afterSale.single['status'], 'partial');
      expect((afterSale.single['total_amount'] as num).toDouble(), 100.0);

      final afterCustomer = await database.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      expect((afterCustomer.single['balance'] as num).toDouble(), 100.0);

      final afterProduct = await database.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      expect(
        (afterProduct.single['stock_qty'] as num).toDouble(),
        beforeStock - 1.0,
      );

      final refunds = await database.query(
        'sale_refunds',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      expect(refunds, hasLength(1));
      final refundId = refunds.single['id'] as String;

      final queueRows = await database.query(
        'sync_queue',
        where: 'entity = ? AND entity_id = ?',
        whereArgs: ['sale_refund', refundId],
      );
      expect(queueRows, isNotEmpty);

      await db.reset();
    },
  );
}
