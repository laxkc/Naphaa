import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/core/storage/local_db.dart';
import 'package:sme_digital/core/sync/sync_manager.dart';
import 'package:sme_digital/core/sync/sync_queue.dart';
import 'package:sme_digital/features/auth/domain/auth_state.dart';
import 'package:sme_digital/features/sales/domain/sale_models.dart';

import '../helpers/test_db.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => AuthState(authenticated: true);
}

class _TestLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

class _ThrowingSyncManager extends SyncManager {
  _ThrowingSyncManager(LocalDatabase db) : super(SyncQueueService(db));

  @override
  Future<int> processPendingSync({String localeCode = 'ne'}) async {
    throw StateError('sync unavailable');
  }
}

Future<void> _insertProduct(
  LocalDatabase localDb, {
  required String id,
  required double stockQty,
  double sellPrice = 100,
}) async {
  final db = await localDb.database;
  await db.insert('products', {
    'id': id,
    'name': 'Product $id',
    'sell_price': sellPrice,
    'cost_price': 50.0,
    'stock_qty': stockQty,
    'low_stock_threshold': 0.0,
    'unit': 'piece',
    'category': null,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  });
}

ProviderContainer _container(
  LocalDatabase localDb, {
  SyncManager? syncManager,
}) {
  return ProviderContainer(
    overrides: [
      localDatabaseProvider.overrideWithValue(localDb),
      authControllerProvider.overrideWith(_TestAuthController.new),
      localeControllerProvider.overrideWith(_TestLocaleController.new),
      if (syncManager != null)
        syncManagerProvider.overrideWithValue(syncManager),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'sale save stays successful when sync fails and shows retry notice',
    () async {
      final localDb = await createTestDb('sales_checkout_feedback_sync_retry');
      addTearDown(localDb.reset);
      await _insertProduct(localDb, id: 'p1', stockQty: 10);

      final container = _container(
        localDb,
        syncManager: _ThrowingSyncManager(localDb),
      );
      addTearDown(container.dispose);
      final controller = container.read(salesControllerProvider.notifier);

      await controller.search('');
      controller.increment('p1');
      final ok = await controller.saveCashSale();

      expect(ok, isTrue);
      final state = container.read(salesControllerProvider);
      expect(state.selected, isEmpty);
      expect(state.message, contains('Cash sale saved successfully.'));
      expect(state.message, contains('Sync failed. Will retry automatically.'));

      final db = await localDb.database;
      final salesRows = await db.query('sales');
      expect(salesRows.length, 1);
      final diagnosticRows = await db.query(
        'checkout_diagnostics',
        orderBy: 'id DESC',
        limit: 1,
      );
      expect(diagnosticRows, hasLength(1));
      expect((diagnosticRows.single['success'] as num).toInt(), 1);
      expect((diagnosticRows.single['sync_retry_notice'] as num).toInt(), 1);
      expect(diagnosticRows.single['flow'], 'quick_cash');
    },
  );

  test('insufficient stock returns actionable save failure message', () async {
    final localDb = await createTestDb('sales_checkout_feedback_stock_error');
    addTearDown(localDb.reset);
    await _insertProduct(localDb, id: 'p1', stockQty: 1);

    final container = _container(localDb);
    addTearDown(container.dispose);
    final controller = container.read(salesControllerProvider.notifier);

    await controller.search('');
    controller.increment('p1');
    controller.increment('p1');
    final ok = await controller.saveCashSale();

    expect(ok, isFalse);
    final state = container.read(salesControllerProvider);
    expect(state.message, 'Sale could not be saved: insufficient stock.');
    final db = await localDb.database;
    final diagnosticRows = await db.query(
      'checkout_diagnostics',
      orderBy: 'id DESC',
      limit: 1,
    );
    expect(diagnosticRows, hasLength(1));
    expect((diagnosticRows.single['success'] as num).toInt(), 0);
    expect(diagnosticRows.single['error_code'], 'insufficient_stock');
  });

  test(
    'quick cash path writes single CASH payment and quick_cash diagnostic',
    () async {
      final localDb = await createTestDb('sales_quick_cash_reliable_flow');
      addTearDown(localDb.reset);
      await _insertProduct(localDb, id: 'p1', stockQty: 10, sellPrice: 120);

      final container = _container(localDb);
      addTearDown(container.dispose);
      final controller = container.read(salesControllerProvider.notifier);

      await controller.search('');
      controller.increment('p1');
      final ok = await controller.saveCashSale();

      expect(ok, isTrue);
      final db = await localDb.database;
      final paymentRows = await db.query('sale_payments');
      expect(paymentRows, hasLength(1));
      expect(paymentRows.single['method'], 'CASH');
      expect((paymentRows.single['amount'] as num).toDouble(), 120);

      final diagnosticRows = await db.query(
        'checkout_diagnostics',
        orderBy: 'id DESC',
        limit: 1,
      );
      expect(diagnosticRows, hasLength(1));
      expect(diagnosticRows.single['flow'], 'quick_cash');
      expect((diagnosticRows.single['success'] as num).toInt(), 1);
      expect(
        (diagnosticRows.single['duration_ms'] as num).toInt(),
        greaterThanOrEqualTo(0),
      );
    },
  );

  test('benchmark captures top 3 checkout flows in diagnostics', () async {
    final localDb = await createTestDb('sales_checkout_top3_flow_benchmark');
    addTearDown(localDb.reset);
    await _insertProduct(localDb, id: 'p1', stockQty: 30, sellPrice: 100);

    final container = _container(localDb);
    addTearDown(container.dispose);
    final controller = container.read(salesControllerProvider.notifier);

    // quick_cash
    await controller.search('');
    controller.increment('p1');
    expect(await controller.saveCashSale(), isTrue);

    // quick_credit
    controller.increment('p1');
    expect(
      await controller.saveCreditSaleWithCustomer(
        customerName: 'Rohan',
        phone: '9800000123',
      ),
      isTrue,
    );

    // advanced_mixed
    controller.increment('p1');
    expect(
      await controller.saveSaleWithPayments(
        payments: [
          SalePaymentInput(method: PaymentMethod.cash, amount: 50),
          SalePaymentInput(method: PaymentMethod.credit, amount: 50),
        ],
        customerName: 'Sita',
      ),
      isTrue,
    );

    final db = await localDb.database;
    final flowRows = await db.rawQuery('''
      SELECT flow, COUNT(*) AS cnt, AVG(duration_ms) AS avg_ms
      FROM checkout_diagnostics
      WHERE success = 1
      GROUP BY flow
    ''');
    final flowMap = {for (final row in flowRows) row['flow'] as String: row};

    expect(flowMap.containsKey('quick_cash'), isTrue);
    expect(flowMap.containsKey('quick_credit'), isTrue);
    expect(flowMap.containsKey('advanced_mixed'), isTrue);
    expect(
      (flowMap['quick_cash']!['avg_ms'] as num).toDouble(),
      greaterThanOrEqualTo(0),
    );
    expect(
      (flowMap['quick_credit']!['avg_ms'] as num).toDouble(),
      greaterThanOrEqualTo(0),
    );
    expect(
      (flowMap['advanced_mixed']!['avg_ms'] as num).toDouble(),
      greaterThanOrEqualTo(0),
    );
  });
}
