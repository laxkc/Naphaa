import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/features/customers/data/customers_repository.dart';
import 'package:sme_digital/features/expenses/data/expenses_repository.dart';
import 'package:sme_digital/features/products/data/products_repository.dart';
import 'package:sme_digital/features/reports/data/alerts_repository.dart';
import 'package:sme_digital/features/reports/data/metrics_repository.dart';
import 'package:sme_digital/features/sales/data/sales_repository.dart';
import 'package:sme_digital/features/sales/domain/sale_models.dart';

import '../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local write triggers recompute intelligence caches (IR3)', () async {
    final localDb = await createTestDb('local_intelligence_metrics_trigger');
    await localDb.seedIfEmpty();
    final db = await localDb.database;

    final alertsRepo = AlertsRepository(localDb);
    final metricsRepo = MetricsRepository(localDb, alertsRepo);
    final customersRepo = CustomersRepository(
      localDb,
      metricsRepository: metricsRepo,
    );
    final expensesRepo = ExpensesRepository(
      localDb,
      metricsRepository: metricsRepo,
    );
    final productsRepo = ProductsRepository(
      localDb,
      metricsRepository: metricsRepo,
    );
    final salesRepo = SalesRepository(localDb, metricsRepository: metricsRepo);

    final productRows = await db.query('products', limit: 1);
    final productId = productRows.first['id'] as String;

    final customerId = await customersRepo.addCustomer(
      name: 'Ram',
      phone: '9800000001',
    );
    await salesRepo.createSale(
      SaleInput(
        saleType: 'CREDIT',
        customerId: customerId,
        items: [SaleItemInput(productId: productId, qty: 1, unitPrice: 150)],
      ),
    );
    await expensesRepo.addExpense(
      category: 'TRANSPORT',
      amount: 40,
      note: 'Delivery',
    );
    await productsRepo.adjustStock(
      productId: productId,
      delta: 2,
      reason: 'COUNT',
    );

    final customerMetricsRows = await db.query('customer_metrics');
    expect(customerMetricsRows, isNotEmpty);
    final customerMetric = customerMetricsRows.firstWhere(
      (r) => r['customer_id'] == customerId,
      orElse: () => <String, Object?>{},
    );
    expect(customerMetric, isNotEmpty);
    expect((customerMetric['outstanding_amount'] as num?)?.toDouble(), 150);

    final productMetricsRows = await db.query('product_metrics');
    expect(productMetricsRows, isNotEmpty);
    final productMetric = productMetricsRows.firstWhere(
      (r) => r['product_id'] == productId,
      orElse: () => <String, Object?>{},
    );
    expect(productMetric, isNotEmpty);
    expect((productMetric['qty_sold_30d'] as num?)?.toDouble(), 1);

    final businessRows = await db.query(
      'business_metrics_cache',
      where: 'cache_key = ?',
      whereArgs: ['default'],
      limit: 1,
    );
    expect(businessRows, hasLength(1));
    final payload = Map<String, dynamic>.from(
      jsonDecode(businessRows.first['payload_json'] as String) as Map,
    );
    expect(payload['source'], 'local_cache');
    expect(payload['provisional'], true);
    expect(payload['sales_total'], isNotNull);
    expect(payload['expenses_total'], isNotNull);

    final alertsRows = await db.query('alerts');
    expect(alertsRows, isNotEmpty);

    await localDb.reset();
  });

  test(
    'product metrics net out refunded quantities from sales totals',
    () async {
      final localDb = await createTestDb('local_metrics_refund_netting');
      await localDb.seedIfEmpty();
      final db = await localDb.database;

      final alertsRepo = AlertsRepository(localDb);
      final metricsRepo = MetricsRepository(localDb, alertsRepo);
      final customersRepo = CustomersRepository(
        localDb,
        metricsRepository: metricsRepo,
      );
      final salesRepo = SalesRepository(
        localDb,
        metricsRepository: metricsRepo,
      );

      final productRows = await db.query('products', limit: 1);
      final productId = productRows.first['id'] as String;
      final customerId = await customersRepo.addCustomer(
        name: 'Sita',
        phone: '9800000002',
      );
      await salesRepo.createSale(
        SaleInput(
          saleType: 'CREDIT',
          customerId: customerId,
          items: [SaleItemInput(productId: productId, qty: 1, unitPrice: 200)],
        ),
      );
      final sale = (await db.query('sales', limit: 1)).single;
      final saleId = sale['id'] as String;
      final saleItem =
          (await db.query(
            'sale_items',
            where: 'sale_id = ?',
            whereArgs: [saleId],
            limit: 1,
          )).single;
      final saleItemId = saleItem['id'] as String;

      await salesRepo.refundSale(
        saleId: saleId,
        reason: 'Returned full qty',
        itemQtyBySaleItemId: {saleItemId: 1.0},
      );

      await metricsRepo.recomputeLocalCaches();

      final metricRows = await db.query(
        'product_metrics',
        where: 'product_id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      expect(metricRows, hasLength(1));
      final metric = metricRows.single;
      expect((metric['qty_sold_30d'] as num).toDouble(), 0.0);
      expect((metric['revenue_30d'] as num).toDouble(), 0.0);

      await localDb.reset();
    },
  );
}
