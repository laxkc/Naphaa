import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/core/providers/app_providers.dart';
import 'package:sme_digital/core/storage/local_db.dart';
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
    required this.onProcessDetailed,
  }) : super(queue);

  final Future<SyncRunResult> Function(String localeCode) onProcessDetailed;
  int calls = 0;

  @override
  Future<int> processPendingSync({String localeCode = 'ne'}) async {
    final result = await processPendingSyncDetailed(localeCode: localeCode);
    return result.pendingAtStart;
  }

  @override
  Future<SyncRunResult> processPendingSyncDetailed({
    String localeCode = 'ne',
  }) async {
    calls += 1;
    return onProcessDetailed(localeCode);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncCoordinatorController', () {
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
    });

    tearDown(() async {
      await connectivityController.close();
    });

    Future<ProviderContainer> _buildContainer({
      required LocalDatabase testDb,
      required Future<List<ConnectivityResult>> Function() checkConnectivity,
      required _FakeSyncManager fakeSyncManager,
      Duration debounce = const Duration(milliseconds: 20),
      Duration periodic = const Duration(seconds: 60),
      List extraOverrides = const [],
    }) async {
      final queue = SyncQueueService(testDb);
      // Seed one pending row so pending count queries have non-zero coverage.
      await queue.enqueue(entity: 'sale', operation: 'UPSERT', payload: {'id': 's1'});
      final container = ProviderContainer(
        overrides: [
          localDatabaseProvider.overrideWithValue(testDb),
          authControllerProvider.overrideWith(_TestAuthController.new),
          localeControllerProvider.overrideWith(_TestLocaleController.new),
          syncManagerProvider.overrideWithValue(fakeSyncManager),
          syncConnectivityCheckProvider.overrideWithValue(({
            Connectivity? connectivity,
          }) {
            return checkConnectivity();
          }),
          syncConnectivityChangesProvider.overrideWithValue(({
            Connectivity? connectivity,
          }) {
            return connectivityController.stream;
          }),
          syncCoordinatorDebounceDurationProvider.overrideWithValue(debounce),
          syncCoordinatorPeriodicDurationProvider.overrideWithValue(periodic),
          ...extraOverrides.cast<dynamic>(),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await testDb.reset();
      });
      return container;
    }

    test('reconnect triggers debounced sync once', () async {
      final db = await createTestDb('sync_coordinator_reconnect');
      final fake = _FakeSyncManager(
        queue: SyncQueueService(db),
        onProcessDetailed: (_) async => const SyncRunResult(pendingAtStart: 1, ackedEvents: 1),
      );
      final container = await _buildContainer(
        testDb: db,
        checkConnectivity: () async => [ConnectivityResult.none],
        fakeSyncManager: fake,
        debounce: const Duration(milliseconds: 10),
        periodic: const Duration(seconds: 60),
      );
      container.read(syncCoordinatorProvider);
      // Allow async startup to complete (initial connectivity + pending count refresh).
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (!container.read(syncCoordinatorProvider).online) {
          break;
        }
      }

      connectivityController.add([ConnectivityResult.wifi]);
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (fake.calls >= 1) {
          break;
        }
      }

      expect(fake.calls, 1);
      final state = container.read(syncCoordinatorProvider);
      expect(state.online, isTrue);
      expect(state.lastError, isNull);
    });

    test('periodic timer triggers sync when authenticated', () async {
      final db = await createTestDb('sync_coordinator_periodic');
      final fake = _FakeSyncManager(
        queue: SyncQueueService(db),
        onProcessDetailed: (_) async => const SyncRunResult(pendingAtStart: 1, ackedEvents: 1),
      );
      final container = await _buildContainer(
        testDb: db,
        checkConnectivity: () async => [ConnectivityResult.none],
        fakeSyncManager: fake,
        periodic: const Duration(milliseconds: 25),
      );
      container.read(syncCoordinatorProvider);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(fake.calls, greaterThanOrEqualTo(1));
    });

    test('in-flight lock prevents concurrent sync runs', () async {
      final db = await createTestDb('sync_coordinator_inflight');
      final blocker = Completer<void>();
      final fake = _FakeSyncManager(
        queue: SyncQueueService(db),
        onProcessDetailed: (_) async {
          await blocker.future;
          return const SyncRunResult(pendingAtStart: 1, ackedEvents: 1);
        },
      );
      final container = await _buildContainer(
        testDb: db,
        checkConnectivity: () async => [ConnectivityResult.none],
        fakeSyncManager: fake,
      );

      final notifier = container.read(syncCoordinatorProvider.notifier);
      final first = notifier.triggerNow();
      final second = notifier.triggerNow();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fake.calls, 1);

      blocker.complete();
      await Future.wait([first, second]);
      expect(container.read(syncCoordinatorProvider).syncing, isFalse);
    });

    test('failure sets backoff and skips immediate retry', () async {
      final db = await createTestDb('sync_coordinator_backoff');
      var shouldFail = true;
      final fake = _FakeSyncManager(
        queue: SyncQueueService(db),
        onProcessDetailed: (_) async {
          if (shouldFail) {
            throw Exception('sync failed');
          }
          return const SyncRunResult(pendingAtStart: 1, ackedEvents: 1);
        },
      );
      final container = await _buildContainer(
        testDb: db,
        checkConnectivity: () async => [ConnectivityResult.none],
        fakeSyncManager: fake,
      );

      final notifier = container.read(syncCoordinatorProvider.notifier);
      await notifier.triggerNow();
      final afterFailure = container.read(syncCoordinatorProvider);
      expect(fake.calls, 1);
      expect(afterFailure.lastError, contains('sync failed'));

      shouldFail = false;
      await notifier.triggerNow();
      expect(fake.calls, 1, reason: 'Immediate retry should be skipped by backoff');
    });

    test('successful sync invalidates common UI providers', () async {
      final db = await createTestDb('sync_coordinator_invalidate');
      final fake = _FakeSyncManager(
        queue: SyncQueueService(db),
        onProcessDetailed: (_) async => const SyncRunResult(pendingAtStart: 1, ackedEvents: 1),
      );
      final counts = <String, int>{};
      final container = await _buildContainer(
        testDb: db,
        checkConnectivity: () async => [ConnectivityResult.none],
        fakeSyncManager: fake,
        extraOverrides: [
          productsListProvider.overrideWith((ref) async {
            counts['products'] = (counts['products'] ?? 0) + 1;
            return [];
          }),
          customersListProvider.overrideWith((ref) async {
            counts['customers'] = (counts['customers'] ?? 0) + 1;
            return [];
          }),
          expensesListProvider.overrideWith((ref) async {
            counts['expenses'] = (counts['expenses'] ?? 0) + 1;
            return [];
          }),
          lowStockProductsProvider.overrideWith((ref) async {
            counts['lowStock'] = (counts['lowStock'] ?? 0) + 1;
            return [];
          }),
          dashboardSummaryProvider.overrideWith((ref) async {
            counts['dashboard'] = (counts['dashboard'] ?? 0) + 1;
            return DashboardSummary(
              todaySales: 0,
              todayExpenses: 0,
              creditOutstanding: 0,
            );
          }),
        ],
      );
      await container.read(productsListProvider.future);
      await container.read(customersListProvider.future);
      await container.read(expensesListProvider.future);
      await container.read(lowStockProductsProvider.future);
      await container.read(dashboardSummaryProvider.future);
      expect(counts.values.every((v) => v == 1), isTrue);

      await container.read(syncCoordinatorProvider.notifier).triggerNow();

      await container.read(productsListProvider.future);
      await container.read(customersListProvider.future);
      await container.read(expensesListProvider.future);
      await container.read(lowStockProductsProvider.future);
      await container.read(dashboardSummaryProvider.future);

      expect(counts['products'], greaterThanOrEqualTo(2));
      expect(counts['customers'], greaterThanOrEqualTo(2));
      expect(counts['expenses'], greaterThanOrEqualTo(2));
      expect(counts['lowStock'], greaterThanOrEqualTo(2));
      expect(counts['dashboard'], greaterThanOrEqualTo(2));
    });

    test('partial sync shows warning state instead of clean success', () async {
      final db = await createTestDb('sync_coordinator_partial_warning');
      final fake = _FakeSyncManager(
        queue: SyncQueueService(db),
        onProcessDetailed: (_) async => const SyncRunResult(
          pendingAtStart: 2,
          pushedEvents: 2,
          ackedEvents: 1,
          failedEvents: 1,
        ),
      );
      final container = await _buildContainer(
        testDb: db,
        checkConnectivity: () async => [ConnectivityResult.none],
        fakeSyncManager: fake,
      );

      await container.read(syncCoordinatorProvider.notifier).triggerNow();
      final state = container.read(syncCoordinatorProvider);
      expect(state.lastSuccessAt, isNotNull);
      expect(state.lastError, contains('failed item'));
    });
  });
}
