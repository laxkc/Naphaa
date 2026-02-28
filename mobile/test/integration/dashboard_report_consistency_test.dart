import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/core/date/business_time.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/core/storage/local_db.dart';
import 'package:sme_digital/core/network/sync_service.dart';
import 'package:sme_digital/core/sync/sync_manager.dart';
import 'package:sme_digital/core/sync/sync_queue.dart';
import 'package:sme_digital/features/auth/domain/auth_state.dart';

import '../helpers/test_db.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => AuthState(authenticated: true);
}

class _TestLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('en');
}

class _FakeSyncManager extends SyncManager {
  _FakeSyncManager({
    required SyncQueueService queue,
    required this.onProcess,
  }) : super(queue);

  final Future<int> Function(String localeCode) onProcess;

  @override
  Future<int> processPendingSync({String localeCode = 'ne'}) {
    return onProcess(localeCode);
  }

  @override
  Future<SyncRunResult> processPendingSyncDetailed({
    String localeCode = 'ne',
  }) async {
    final count = await onProcess(localeCode);
    return SyncRunResult(
      pendingAtStart: count,
      pushedEvents: count,
      ackedEvents: count,
      failedEvents: 0,
      pulledEvents: 0,
      appliedEvents: 0,
    );
  }

  @override
  Future<SyncLastRunMeta> processPendingSyncWithMeta({
    String localeCode = 'ne',
  }) async {
    final result = await processPendingSyncDetailed(localeCode: localeCode);
    return SyncLastRunMeta(result: result, durationMs: 0);
  }
}

Future<void> _insertCustomer(
  LocalDatabase localDb, {
  required String id,
  required double balance,
}) async {
  final db = await localDb.database;
  final now = DateTime.now().toUtc().toIso8601String();
  await db.insert('customers', {
    'id': id,
    'name': 'Cust $id',
    'phone': null,
    'address': null,
    'notes': null,
    'balance': balance,
    'created_at': now,
    'is_deleted': 0,
    'updated_at': now,
  });
}

Future<void> _insertSale(
  LocalDatabase localDb, {
  required String id,
  required double amount,
  required String saleType,
  String? customerId,
  required DateTime createdAt,
  String? saleDateAd,
}) async {
  final db = await localDb.database;
  await db.insert('sales', {
    'id': id,
    'sale_type': saleType,
    'payment_method': saleType == 'CREDIT' ? 'CREDIT' : 'CASH',
    'customer_id': customerId,
    'total_amount': amount,
    'sale_date_ad':
        saleDateAd ??
        BusinessTime.businessDateAd(timestampUtc: createdAt.toUtc()),
    'created_at': createdAt.toUtc().toIso8601String(),
  });
}

Future<void> _insertExpense(
  LocalDatabase localDb, {
  required String id,
  required double amount,
  required DateTime createdAt,
  String? expenseDateAd,
}) async {
  final db = await localDb.database;
  await db.insert('expenses', {
    'id': id,
    'category': 'OTHER',
    'amount': amount,
    'note': 'Expense $id',
    'expense_date_ad':
        expenseDateAd ??
        BusinessTime.businessDateAd(timestampUtc: createdAt.toUtc()),
    'created_at': createdAt.toUtc().toIso8601String(),
  });
}

ProviderContainer _baseContainer(LocalDatabase localDb) {
  return ProviderContainer(
    overrides: [
      localDatabaseProvider.overrideWithValue(localDb),
      authControllerProvider.overrideWith(_TestAuthController.new),
      localeControllerProvider.overrideWith(_TestLocaleController.new),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard and report consistency', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('dashboard summary uses local-first today totals and credit', () async {
      final localDb = await createTestDb('dashboard_summary_local_first');
      addTearDown(localDb.reset);
      final now = DateTime.now();
      final todayAd = BusinessTime.businessDateAd(timestampUtc: now.toUtc());
      final yesterdayAd = BusinessTime.formatDateOnly(
        BusinessTime.parseAdDate(todayAd)!.subtract(const Duration(days: 1)),
      );

      await _insertCustomer(localDb, id: 'c1', balance: 75);
      await _insertSale(
        localDb,
        id: 's-today',
        amount: 120,
        saleType: 'CASH',
        createdAt: now.subtract(const Duration(hours: 1)),
        saleDateAd: todayAd,
      );
      await _insertSale(
        localDb,
        id: 's-old',
        amount: 999,
        saleType: 'CASH',
        createdAt: now.subtract(const Duration(days: 1)),
        saleDateAd: yesterdayAd,
      );
      await _insertExpense(
        localDb,
        id: 'e-today',
        amount: 20,
        createdAt: now.subtract(const Duration(minutes: 30)),
        expenseDateAd: todayAd,
      );
      await _insertExpense(
        localDb,
        id: 'e-old',
        amount: 777,
        createdAt: now.subtract(const Duration(days: 1)),
        expenseDateAd: yesterdayAd,
      );

      final container = _baseContainer(localDb);
      addTearDown(container.dispose);

      final summary = await container.read(dashboardSummaryProvider.future);
      expect(summary.todaySales, 120);
      expect(summary.todayExpenses, 20);
      expect(summary.creditOutstanding, 75);
      expect(summary.estimatedProfit, 100);
    });

    test('sales report provider filters by date range from local DB', () async {
      final localDb = await createTestDb('sales_report_period_filter');
      addTearDown(localDb.reset);
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final yesterdayLate = dayStart.subtract(const Duration(minutes: 1));
      final todayAd = BusinessTime.formatDateOnly(dayStart);
      final yesterdayAd = BusinessTime.formatDateOnly(
        dayStart.subtract(const Duration(days: 1)),
      );

      await _insertSale(
        localDb,
        id: 'r1',
        amount: 100,
        saleType: 'CASH',
        createdAt: dayStart.add(const Duration(hours: 1)),
        saleDateAd: todayAd,
      );
      await _insertSale(
        localDb,
        id: 'r2',
        amount: 50,
        saleType: 'CREDIT',
        createdAt: dayStart.add(const Duration(hours: 2)),
        saleDateAd: todayAd,
      );
      await _insertSale(
        localDb,
        id: 'r3',
        amount: 999,
        saleType: 'CASH',
        createdAt: yesterdayLate,
        saleDateAd: yesterdayAd,
      );

      final container = _baseContainer(localDb);
      addTearDown(container.dispose);

      final params = ReportParams(
        fromDate: dayStart,
        toDate: dayStart.add(const Duration(days: 1)).subtract(
          const Duration(milliseconds: 1),
        ),
      );
      final report = await container.read(salesReportProvider(params).future);
      expect(report['total_revenue'], 150.0);
      expect(report['total_transactions'], 2);
      expect(report['cash_total'], 100.0);
      expect(report['credit_total'], 50.0);
    });

    test('sales and profit-style expense filters handle synced timezone timestamps', () async {
      final localDb = await createTestDb('report_synced_tz_filters');
      addTearDown(localDb.reset);
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final inRangeLocal = dayStart.add(const Duration(hours: 2, minutes: 15));
      final outOfRangeLocal = dayStart.subtract(const Duration(minutes: 5));
      final inRangeAd = BusinessTime.formatDateOnly(dayStart);
      final outOfRangeAd = BusinessTime.formatDateOnly(
        dayStart.subtract(const Duration(days: 1)),
      );

      await _insertSale(
        localDb,
        id: 'tz-sale-in',
        amount: 80,
        saleType: 'CASH',
        createdAt: inRangeLocal.toUtc(),
        saleDateAd: inRangeAd,
      );
      await _insertSale(
        localDb,
        id: 'tz-sale-out',
        amount: 999,
        saleType: 'CASH',
        createdAt: outOfRangeLocal.toUtc(),
        saleDateAd: outOfRangeAd,
      );
      await _insertExpense(
        localDb,
        id: 'tz-exp-in',
        amount: 15,
        createdAt: inRangeLocal.toUtc(),
        expenseDateAd: inRangeAd,
      );
      await _insertExpense(
        localDb,
        id: 'tz-exp-out',
        amount: 777,
        createdAt: outOfRangeLocal.toUtc(),
        expenseDateAd: outOfRangeAd,
      );

      final container = _baseContainer(localDb);
      addTearDown(container.dispose);

      final params = ReportParams(
        fromDate: dayStart,
        toDate: dayEnd,
      );
      final salesReport = await container.read(salesReportProvider(params).future);
      expect(salesReport['total_revenue'], 80.0);
      expect(salesReport['total_transactions'], 1);

      final expenses = await container.read(expensesListProvider.future);
      final filteredExpenseTotal = expenses
          .where((e) {
            final expenseDateAd =
                e.expenseDateAd ??
                BusinessTime.formatDateOnly(e.createdAt.toUtc());
            return expenseDateAd.compareTo(
                      BusinessTime.formatDateOnly(params.fromDate),
                    ) >=
                    0 &&
                expenseDateAd.compareTo(
                      BusinessTime.formatDateOnly(
                        params.toDate.subtract(const Duration(milliseconds: 1)),
                      ),
                    ) <=
                    0;
          })
          .fold<double>(0, (sum, e) => sum + e.amount);
      expect(filteredExpenseTotal, 15.0);
    });

    test('expense business-date filtering stays stable even when timestamps drift', () async {
      final localDb = await createTestDb('expense_business_date_filtering');
      addTearDown(localDb.reset);
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      await _insertExpense(
        localDb,
        id: 'e-business-in',
        amount: 33,
        createdAt: dayStart.subtract(const Duration(days: 2)),
        expenseDateAd: BusinessTime.formatDateOnly(dayStart),
      );
      await _insertExpense(
        localDb,
        id: 'e-business-out',
        amount: 77,
        createdAt: dayStart.add(const Duration(hours: 2)),
        expenseDateAd: BusinessTime.formatDateOnly(
          dayStart.subtract(const Duration(days: 3)),
        ),
      );

      final expenses = await _baseContainer(localDb).read(expensesListProvider.future);
      final filteredExpenseTotal = expenses
          .where((e) {
            final expenseDateAd =
                e.expenseDateAd ??
                BusinessTime.formatDateOnly(e.createdAt.toUtc());
            return expenseDateAd.compareTo(BusinessTime.formatDateOnly(dayStart)) >= 0 &&
                expenseDateAd.compareTo(
                      BusinessTime.formatDateOnly(
                        dayEnd.subtract(const Duration(milliseconds: 1)),
                      ),
                    ) <=
                    0;
          })
          .fold<double>(0, (sum, e) => sum + e.amount);
      expect(filteredExpenseTotal, 33.0);
    });

    test('sync-triggered invalidation refreshes dashboard and report values', () async {
      final localDb = await createTestDb('dashboard_summary_sync_refresh');
      addTearDown(localDb.reset);
      final connectivityChanges = StreamController<List<ConnectivityResult>>.broadcast();
      addTearDown(connectivityChanges.close);

      final db = await localDb.database;
      await db.insert('sync_queue', {
        'entity': 'sale',
        'entity_id': 'queued-1',
        'operation': 'UPSERT',
        'payload': '{}',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });

      final fakeSyncManager = _FakeSyncManager(
        queue: SyncQueueService(localDb),
        onProcess: (_) async {
          final now = DateTime.now();
          final todayAd = BusinessTime.businessDateAd(timestampUtc: now.toUtc());
          await _insertCustomer(localDb, id: 'c-sync', balance: 40);
          await _insertSale(
            localDb,
            id: 's-sync',
            amount: 200,
            saleType: 'CREDIT',
            customerId: 'c-sync',
            createdAt: now,
            saleDateAd: todayAd,
          );
          await _insertExpense(
            localDb,
            id: 'e-sync',
            amount: 25,
            createdAt: now,
            expenseDateAd: todayAd,
          );
          await db.update(
            'sync_queue',
            {'synced': 1, 'status': 'synced'},
            where: 'entity_id = ?',
            whereArgs: ['queued-1'],
          );
          return 1;
        },
      );

      final container = ProviderContainer(
        overrides: [
          localDatabaseProvider.overrideWithValue(localDb),
          authControllerProvider.overrideWith(_TestAuthController.new),
          localeControllerProvider.overrideWith(_TestLocaleController.new),
          syncManagerProvider.overrideWithValue(fakeSyncManager),
          syncConnectivityCheckProvider.overrideWithValue(({
            Connectivity? connectivity,
          }) async => [ConnectivityResult.none]),
          syncConnectivityChangesProvider.overrideWithValue(({
            Connectivity? connectivity,
          }) => connectivityChanges.stream),
          syncCoordinatorPeriodicDurationProvider.overrideWithValue(
            const Duration(seconds: 60),
          ),
          syncCoordinatorDebounceDurationProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
        ],
      );
      addTearDown(container.dispose);

      final before = await container.read(dashboardSummaryProvider.future);
      expect(before.todaySales, 0);
      expect(before.todayExpenses, 0);
      expect(before.creditOutstanding, 0);
      final now = DateTime.now();
      final reportDay =
          BusinessTime.parseAdDate(
            BusinessTime.businessDateAd(timestampUtc: now.toUtc()),
          )!;
      final reportParams = ReportParams(
        fromDate: reportDay,
        toDate: reportDay.add(const Duration(days: 1)).subtract(
          const Duration(milliseconds: 1),
        ),
      );
      final beforeReport = await container.read(salesReportProvider(reportParams).future);
      expect(beforeReport['total_revenue'], 0.0);
      expect(beforeReport['total_transactions'], 0);

      await container.read(syncCoordinatorProvider.notifier).triggerNow();

      final after = await container.read(dashboardSummaryProvider.future);
      expect(after.todaySales, 200);
      expect(after.todayExpenses, 25);
      expect(after.creditOutstanding, 40);
      final afterReport = await container.read(salesReportProvider(reportParams).future);
      expect(afterReport['total_revenue'], 200.0);
      expect(afterReport['total_transactions'], 1);
    });
  });
}
