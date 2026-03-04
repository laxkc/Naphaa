import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/core/network/backend_gateway.dart';
import 'package:sme_digital/core/network/models/sync_models.dart';
import 'package:sme_digital/core/network/session_service.dart';
import 'package:sme_digital/core/network/sync_service.dart';
import 'package:sme_digital/core/storage/preferences.dart';
import 'package:sme_digital/core/storage/secure_storage.dart';

import '../helpers/test_db.dart';

class _FakePrefs extends AppPreferences {
  String? _lastSyncAt;
  String? _lastSyncCursor;
  String? _deviceId;

  @override
  Future<String?> getLastSyncAt() async => _lastSyncAt;

  @override
  Future<void> setLastSyncAt(String iso) async {
    _lastSyncAt = iso;
  }

  @override
  Future<String?> getLastSyncCursor() async => _lastSyncCursor;

  @override
  Future<void> setLastSyncCursor(String cursor) async {
    _lastSyncCursor = cursor;
  }

  @override
  Future<void> clearLastSyncCursor() async {
    _lastSyncCursor = null;
  }

  @override
  Future<String> getOrCreateDeviceId() async {
    _deviceId ??= 'test-device-1';
    return _deviceId!;
  }
}

class _FakeGateway extends BackendGateway {
  _FakeGateway() : super(Dio());

  final List<List<Map<String, dynamic>>> pushedBatches = [];
  final List<List<String>> pushAckBatches = [];
  final List<List<SyncPushFailure>> pushFailedBatches = [];
  final List<SyncPullResponseModel> pullResponses = [];
  final List<Map<String, dynamic>> pullCalls = [];
  Map<String, dynamic> customerMetricsResponse = const {'items': []};
  Map<String, dynamic> alertsResponse = const {'items': []};
  Map<String, dynamic> productMetricsResponse = const {'items': []};
  Map<String, dynamic> businessMetricsResponse = const {};

  @override
  Future<SyncPushResponseModel> pushSync(
    List<Map<String, dynamic>> events,
  ) async {
    pushedBatches.add(events);
    final acked =
        pushAckBatches.isNotEmpty
            ? pushAckBatches.removeAt(0)
            : events.map((e) => e['op_id'].toString()).toList();
    final failed =
        pushFailedBatches.isNotEmpty
            ? pushFailedBatches.removeAt(0)
            : const <SyncPushFailure>[];
    return SyncPushResponseModel(ackedOpIds: acked, failedEvents: failed);
  }

  @override
  Future<SyncPullResponseModel> pullSync({
    String? since,
    String? cursor,
    int? limit,
  }) async {
    pullCalls.add({'since': since, 'cursor': cursor, 'limit': limit});
    if (pullResponses.isNotEmpty) {
      return pullResponses.removeAt(0);
    }
    return SyncPullResponseModel(events: const [], nextCursor: cursor);
  }

  @override
  Future<Map<String, dynamic>> getCustomerMetrics({
    bool overdueOnly = false,
    bool highRiskOnly = false,
    int limit = 200,
  }) async {
    return customerMetricsResponse;
  }

  @override
  Future<Map<String, dynamic>> getAlerts({
    String status = 'open',
    int limit = 100,
  }) async {
    return alertsResponse;
  }

  @override
  Future<Map<String, dynamic>> getProductMetrics({
    bool deadStockOnly = false,
    int limit = 200,
    int windowDays = 30,
    int deadStockDays = 30,
  }) async {
    return productMetricsResponse;
  }

  @override
  Future<Map<String, dynamic>> getBusinessMetrics({
    String? fromDate,
    String? toDate,
  }) async {
    return businessMetricsResponse;
  }
}

class _FakeSessionService extends SessionService {
  _FakeSessionService()
    : super(
        BackendGateway(Dio()),
        SecureTokenStorage(const FlutterSecureStorage()),
        Dio(),
      );

  @override
  Future<void> ensureReady({required String localeCode}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ack reconciliation marks only acked outbox rows as synced', () async {
    final db = await createTestDb('sync_service_ack');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    final now = DateTime.now().toIso8601String();
    await sql.insert('sync_queue', {
      'op_id': 'op-a',
      'entity': 'expense',
      'entity_id': 'e1',
      'operation': 'UPSERT',
      'payload': jsonEncode({'id': 'e1', 'category': 'OTHER', 'amount': 10}),
      'created_at': now,
      'updated_at': now,
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
    });
    await sql.insert('sync_queue', {
      'op_id': 'op-b',
      'entity': 'expense',
      'entity_id': 'e2',
      'operation': 'UPSERT',
      'payload': jsonEncode({'id': 'e2', 'category': 'OTHER', 'amount': 20}),
      'created_at': now,
      'updated_at': now,
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
    });

    gateway.pushAckBatches.add(['op-a']);

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
      pushChunkSize: 100,
    );
    final result = await service.processPendingSyncDetailed(localeCode: 'en');
    expect(result.pendingAtStart, 2);
    expect(result.pushedEvents, 2);
    expect(result.ackedEvents, 1);
    expect(result.failedEvents, 1);

    final rows = await sql.query('sync_queue', orderBy: 'id ASC');
    expect(rows[0]['status'], 'synced');
    expect(rows[0]['synced'], 1);
    expect(rows[1]['status'], 'failed');
    expect(rows[1]['synced'], 0);
    expect((rows[1]['retry_count'] as num?)?.toInt(), 1);

    await db.reset();
  });

  test(
    'outgoing sync payload timestamps are normalized to UTC Z strings',
    () async {
      final db = await createTestDb('sync_service_utc_normalize');
      final sql = await db.database;
      final prefs = _FakePrefs();
      final gateway = _FakeGateway();
      final session = _FakeSessionService();

      await sql.insert('sync_queue', {
        'op_id': 'op-z-1',
        'entity': 'expense',
        'entity_id': 'exp-z-1',
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': 'exp-z-1',
          'category': 'OTHER',
          'amount': 10,
          'created_at': '2026-02-27T12:00:00',
          'updated_at': '2026-02-27T12:00:00',
        }),
        'created_at': '2026-02-27T12:00:00',
        'updated_at': '2026-02-27T12:00:00',
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });

      final service = SyncService(
        db,
        gateway,
        prefs,
        session,
        connectivityCheck: () async => [ConnectivityResult.wifi],
        pushChunkSize: 100,
      );

      await service.processPendingSyncDetailed(localeCode: 'en');

      expect(gateway.pushedBatches, hasLength(1));
      final payload =
          gateway.pushedBatches.single.single['payload']
              as Map<String, dynamic>;
      expect(payload['created_at'], endsWith('Z'));
      expect(payload['updated_at'], endsWith('Z'));

      await db.reset();
    },
  );

  test('failed row is blocked after max retries', () async {
    final db = await createTestDb('sync_service_block_after_max_retries');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();
    final now = DateTime.now();

    await sql.insert('sync_queue', {
      'op_id': 'op-block-me',
      'entity': 'expense',
      'entity_id': 'e-block',
      'operation': 'UPSERT',
      'payload': jsonEncode({
        'id': 'e-block',
        'category': 'OTHER',
        'amount': 5,
      }),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'synced': 0,
      'status': 'failed',
      'retry_count': 4,
      'next_retry_at':
          now.subtract(const Duration(seconds: 1)).toIso8601String(),
    });

    gateway.pushAckBatches.add(const []);
    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
      pushChunkSize: 100,
    );
    final result = await service.processPendingSyncDetailed(localeCode: 'en');
    expect(result.pendingAtStart, 1);
    expect(result.failedEvents, 1);

    final row = (await sql.query('sync_queue')).single;
    expect(row['status'], 'blocked');
    expect((row['retry_count'] as num?)?.toInt(), 5);
    expect(row['next_retry_at'], isNull);
    expect(
      (row['last_error'] as String?) ?? '',
      contains('Max retries reached'),
    );

    await db.reset();
  });

  test('failed row with future retry_at is skipped until eligible', () async {
    final db = await createTestDb('sync_service_retry_window_gate');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();
    final now = DateTime.now().toUtc();

    await sql.insert('sync_queue', {
      'op_id': 'op-wait',
      'entity': 'expense',
      'entity_id': 'e-wait',
      'operation': 'UPSERT',
      'payload': jsonEncode({'id': 'e-wait', 'category': 'OTHER', 'amount': 5}),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'synced': 0,
      'status': 'failed',
      'retry_count': 1,
      'next_retry_at': now.add(const Duration(minutes: 5)).toIso8601String(),
    });

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
      pushChunkSize: 100,
    );
    final result = await service.processPendingSyncDetailed(localeCode: 'en');
    expect(result.pendingAtStart, 0);
    expect(result.pushedEvents, 0);
    expect(gateway.pushedBatches, isEmpty);

    final row = (await sql.query('sync_queue')).single;
    expect(row['status'], 'failed');
    expect((row['retry_count'] as num?)?.toInt(), 1);

    await db.reset();
  });

  test('customer balance reconcile uses void/refund/payment facts', () async {
    final db = await createTestDb('sync_service_reconcile_customer_balance');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();
    final now = DateTime.now().toUtc().toIso8601String();
    final todayAd = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    await sql.insert('customers', {
      'id': 'c-reconcile-1',
      'name': 'Reconcile Customer',
      'phone': null,
      'address': null,
      'notes': null,
      'balance': 999.0, // stale value, should be rebuilt from facts
      'created_at': now,
      'is_deleted': 0,
      'updated_at': now,
    });
    await sql.insert('sales', {
      'id': 'sale-active',
      'sale_type': 'CREDIT',
      'payment_method': 'CREDIT',
      'customer_id': 'c-reconcile-1',
      'total_amount': 200.0,
      'sale_date_ad': todayAd,
      'status': 'completed',
      'created_at': now,
    });
    await sql.insert('sale_payments', {
      'id': 'pay-active',
      'sale_id': 'sale-active',
      'method': 'CREDIT',
      'amount': 200.0,
      'created_at': now,
    });
    await sql.insert('sale_refunds', {
      'id': 'refund-active',
      'sale_id': 'sale-active',
      'amount': 100.0,
      'credit_refund_amount': 100.0,
      'reason': 'Returned items',
      'refund_date_ad': todayAd,
      'created_at': now,
    });
    await sql.insert('customer_payments', {
      'id': 'cust-pay-1',
      'customer_id': 'c-reconcile-1',
      'method': 'CASH',
      'amount': 50.0,
      'note': null,
      'payment_date_ad': todayAd,
      'created_at': now,
    });

    // A voided credit sale should not increase receivable.
    await sql.insert('sales', {
      'id': 'sale-void',
      'sale_type': 'CREDIT',
      'payment_method': 'CREDIT',
      'customer_id': 'c-reconcile-1',
      'total_amount': 0.0,
      'sale_date_ad': todayAd,
      'status': 'void',
      'created_at': now,
    });
    await sql.insert('sale_payments', {
      'id': 'pay-void',
      'sale_id': 'sale-void',
      'method': 'CREDIT',
      'amount': 70.0,
      'created_at': now,
    });

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSyncDetailed(localeCode: 'en');

    final customer =
        (await sql.query(
          'customers',
          where: 'id = ?',
          whereArgs: ['c-reconcile-1'],
          limit: 1,
        )).single;
    // expected = 200 credit - 100 credit refund - 50 customer payment = 50
    expect((customer['balance'] as num).toDouble(), 50.0);

    await db.reset();
  });

  test('deferred queue rows are normalized and processed as pending', () async {
    final db = await createTestDb('sync_service_process_deferred_rows');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();
    final now = DateTime.now().toUtc().toIso8601String();

    await sql.insert('sync_queue', {
      'op_id': 'op-deferred-1',
      'store_id': 'store-a',
      'entity': 'expense',
      'entity_id': 'exp-deferred-1',
      'operation': 'UPSERT',
      'payload': jsonEncode({
        'id': 'exp-deferred-1',
        'category': 'OTHER',
        'amount': 40.0,
      }),
      'created_at': now,
      'updated_at': now,
      'synced': 0,
      'status': 'deferred',
      'retry_count': 0,
    });
    await AppPreferences().setActiveStoreId('store-a');

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
      pushChunkSize: 100,
    );
    final result = await service.processPendingSyncDetailed(localeCode: 'en');

    expect(result.pendingAtStart, 1);
    expect(result.ackedEvents, 1);
    expect(gateway.pushedBatches, hasLength(1));
    expect(gateway.pushedBatches.single.single['op_id'], 'op-deferred-1');

    final row =
        (await sql.query(
          'sync_queue',
          where: 'op_id = ?',
          whereArgs: ['op-deferred-1'],
        )).single;
    expect(row['status'], 'synced');
    expect(row['synced'], 1);

    await db.reset();
  });

  test(
    'invalid outbound payload is blocked and moved to dead-letter',
    () async {
      final db = await createTestDb(
        'sync_service_dead_letter_outbound_invalid',
      );
      final sql = await db.database;
      final prefs = _FakePrefs();
      final gateway = _FakeGateway();
      final session = _FakeSessionService();
      final now = DateTime.now().toUtc().toIso8601String();

      await sql.insert('sync_queue', {
        'op_id': 'op-invalid-invoice',
        'store_id': 'store-a',
        'entity': 'invoice',
        'entity_id': 'inv-invalid',
        'operation': 'ISSUE',
        'payload': jsonEncode({
          // missing id/invoice_id and items
          'status': 'issued',
          'total': 100.0,
        }),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
      await AppPreferences().setActiveStoreId('store-a');

      final service = SyncService(
        db,
        gateway,
        prefs,
        session,
        connectivityCheck: () async => [ConnectivityResult.wifi],
      );
      final result = await service.processPendingSyncDetailed(localeCode: 'en');

      expect(result.pendingAtStart, 1);
      expect(result.failedEvents, 1);
      expect(gateway.pushedBatches, isEmpty);

      final row =
          (await sql.query(
            'sync_queue',
            where: 'op_id = ?',
            whereArgs: ['op-invalid-invoice'],
          )).single;
      expect(row['status'], 'blocked');
      expect(
        (row['last_error'] as String?) ?? '',
        contains('Invalid outbound invoice event'),
      );

      final deadLetters = await sql.query(
        'sync_dead_letters',
        where: 'op_id = ?',
        whereArgs: ['op-invalid-invoice'],
      );
      expect(deadLetters, hasLength(1));
      expect(deadLetters.single['direction'], 'push');
      expect(
        (deadLetters.single['reason'] as String?) ?? '',
        contains('Invalid outbound invoice event'),
      );

      await db.reset();
    },
  );

  test(
    'invalid inbound pull event is rejected with dead-letter diagnostics',
    () async {
      final db = await createTestDb('sync_service_dead_letter_inbound_invalid');
      final sql = await db.database;
      final prefs = _FakePrefs();
      final gateway = _FakeGateway();
      final session = _FakeSessionService();
      await AppPreferences().setActiveStoreId('store-a');

      gateway.pullResponses.add(
        SyncPullResponseModel(
          events: [
            SyncPullEventModel(
              id: 'evt-invalid-sale-1',
              entity: 'sale',
              operation: 'UPSERT',
              payload: const {
                'id': 'sale-invalid-1',
                'sale_type': 'CASH',
                'payment_method': 'CASH',
                'total_amount': 200.0,
                // missing items list => invalid
                'created_at': '2026-03-04T10:00:00Z',
              },
              createdAt: DateTime.parse('2026-03-04T10:00:00Z'),
            ),
          ],
          nextCursor: 'evt-invalid-sale-1',
        ),
      );

      final service = SyncService(
        db,
        gateway,
        prefs,
        session,
        connectivityCheck: () async => [ConnectivityResult.wifi],
      );
      final result = await service.processPendingSyncDetailed(localeCode: 'en');

      expect(result.pulledEvents, 1);
      expect(result.appliedEvents, 0);
      final sales = await sql.query(
        'sales',
        where: 'id = ?',
        whereArgs: ['sale-invalid-1'],
      );
      expect(sales, isEmpty);
      final deadLetters = await sql.query(
        'sync_dead_letters',
        where: 'event_id = ?',
        whereArgs: ['evt-invalid-sale-1'],
      );
      expect(deadLetters, hasLength(1));
      expect(deadLetters.single['direction'], 'pull');
      expect(
        (deadLetters.single['reason'] as String?) ?? '',
        contains('Invalid pull sale event'),
      );

      await db.reset();
    },
  );

  test(
    'account switch archives foreign store rows and pushes only active store',
    () async {
      final db = await createTestDb('sync_service_archive_foreign_store_rows');
      final sql = await db.database;
      final prefs = _FakePrefs();
      final gateway = _FakeGateway();
      final session = _FakeSessionService();
      final now = DateTime.now().toUtc().toIso8601String();

      await sql.insert('sync_queue', {
        'op_id': 'op-store-a',
        'store_id': 'store-a',
        'entity': 'expense',
        'entity_id': 'exp-store-a',
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': 'exp-store-a',
          'category': 'OTHER',
          'amount': 10.0,
        }),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
      await sql.insert('sync_queue', {
        'op_id': 'op-store-b',
        'store_id': 'store-b',
        'entity': 'expense',
        'entity_id': 'exp-store-b',
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': 'exp-store-b',
          'category': 'OTHER',
          'amount': 20.0,
        }),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
      await AppPreferences().setActiveStoreId('store-a');

      final service = SyncService(
        db,
        gateway,
        prefs,
        session,
        connectivityCheck: () async => [ConnectivityResult.wifi],
        pushChunkSize: 100,
      );
      await service.processPendingSyncDetailed(localeCode: 'en');

      expect(gateway.pushedBatches, hasLength(1));
      expect(gateway.pushedBatches.single, hasLength(1));
      expect(gateway.pushedBatches.single.single['op_id'], 'op-store-a');

      final rowA =
          (await sql.query(
            'sync_queue',
            where: 'op_id = ?',
            whereArgs: ['op-store-a'],
          )).single;
      final rowB =
          (await sql.query(
            'sync_queue',
            where: 'op_id = ?',
            whereArgs: ['op-store-b'],
          )).single;
      expect(rowA['status'], 'synced');
      expect(rowB['status'], 'archived');
      expect(
        (rowB['last_error'] as String?) ?? '',
        contains('different account/store'),
      );

      await db.reset();
    },
  );

  test('offline write syncs after reconnect with push then pull', () async {
    final db = await createTestDb('sync_service_offline_then_reconnect');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();
    final now = DateTime.now().toIso8601String();

    await sql.insert('sync_queue', {
      'op_id': 'op-offline-1',
      'entity': 'expense',
      'entity_id': 'exp-offline-1',
      'operation': 'UPSERT',
      'payload': jsonEncode({
        'id': 'exp-offline-1',
        'category': 'OTHER',
        'amount': 25.0,
      }),
      'created_at': now,
      'updated_at': now,
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
    });

    var online = false;
    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck:
          () async => [
            online ? ConnectivityResult.wifi : ConnectivityResult.none,
          ],
      pushChunkSize: 100,
    );

    final offlineRun = await service.processPendingSyncDetailed(
      localeCode: 'en',
    );
    expect(offlineRun.pendingAtStart, 0);
    expect(gateway.pushedBatches, isEmpty);

    gateway.pullResponses.add(
      SyncPullResponseModel(
        events: [
          SyncPullEventModel(
            id: 'evt-exp-2',
            entity: 'expense',
            operation: 'UPSERT',
            payload: const {
              'id': 'exp-pulled-2',
              'category': 'OTHER',
              'amount': 70.0,
              'note': 'from server',
              'created_at': '2026-02-27T10:00:00Z',
              'schema_version': 1,
            },
            createdAt: DateTime.parse('2026-02-27T10:00:00Z'),
          ),
        ],
        nextCursor: 'evt-exp-2',
      ),
    );

    online = true;
    final onlineRun = await service.processPendingSyncDetailed(
      localeCode: 'en',
    );
    expect(onlineRun.pendingAtStart, 1);
    expect(onlineRun.ackedEvents, 1);
    expect(onlineRun.pulledEvents, 1);

    final queueRows = await sql.query(
      'sync_queue',
      where: 'op_id = ?',
      whereArgs: ['op-offline-1'],
    );
    expect(queueRows.single['status'], 'synced');
    expect(queueRows.single['synced'], 1);

    final pulledRows = await sql.query(
      'expenses',
      where: 'id = ?',
      whereArgs: ['exp-pulled-2'],
    );
    expect(pulledRows, hasLength(1));
    expect(await prefs.getLastSyncCursor(), 'evt-exp-2');

    await db.reset();
  });

  test(
    'backend failed_events message is stored in outbox last_error',
    () async {
      final db = await createTestDb('sync_service_failed_event_reason');
      final sql = await db.database;
      final prefs = _FakePrefs();
      final gateway = _FakeGateway();
      final session = _FakeSessionService();
      final now = DateTime.now().toIso8601String();

      await sql.insert('sync_queue', {
        'op_id': 'op-fail-1',
        'entity': 'unknown_entity',
        'entity_id': 'x1',
        'operation': 'UPSERT',
        'payload': jsonEncode({'id': 'x1'}),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });

      gateway.pushAckBatches.add(const []);
      gateway.pushFailedBatches.add(const [
        SyncPushFailure(
          opId: 'op-fail-1',
          entity: 'unknown_entity',
          operation: 'UPSERT',
          code: 'UNSUPPORTED_ENTITY',
          message: 'Unsupported sync entity: unknown_entity',
        ),
      ]);

      final service = SyncService(
        db,
        gateway,
        prefs,
        session,
        connectivityCheck: () async => [ConnectivityResult.wifi],
        pushChunkSize: 100,
      );
      await service.processPendingSync(localeCode: 'en');

      final rows = await sql.query('sync_queue');
      expect(rows.single['status'], 'blocked');
      expect(rows.single['synced'], 0);
      expect(
        (rows.single['last_error'] as String?) ?? '',
        contains('Moved to dead-letter'),
      );
      final deadLetters = await sql.query(
        'sync_dead_letters',
        where: 'op_id = ?',
        whereArgs: ['op-fail-1'],
      );
      expect(deadLetters, hasLength(1));
      expect(deadLetters.single['direction'], 'push');

      await db.reset();
    },
  );

  test('pushes outbox in chunks of 100', () async {
    final db = await createTestDb('sync_service_chunk_push');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();
    final now = DateTime.now().toIso8601String();

    for (var i = 0; i < 205; i++) {
      await sql.insert('sync_queue', {
        'op_id': 'op-$i',
        'entity': 'expense',
        'entity_id': 'e-$i',
        'operation': 'UPSERT',
        'payload': jsonEncode({'id': 'e-$i', 'category': 'OTHER', 'amount': i}),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
    }

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
      pushChunkSize: 100,
    );
    await service.processPendingSync(localeCode: 'en');

    expect(gateway.pushedBatches.length, 3);
    expect(gateway.pushedBatches[0].length, 100);
    expect(gateway.pushedBatches[1].length, 100);
    expect(gateway.pushedBatches[2].length, 5);

    await db.reset();
  });

  test('pull applies delete event and persists next cursor', () async {
    final db = await createTestDb('sync_service_pull_delete');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    await sql.insert('products', {
      'id': 'p-del-1',
      'name': 'Test Product',
      'sell_price': 10.0,
      'cost_price': 0.0,
      'stock_qty': 5.0,
      'low_stock_threshold': 1.0,
      'unit': 'piece',
      'category': null,
      'updated_at': DateTime.now().toIso8601String(),
    });

    gateway.pullResponses.add(
      SyncPullResponseModel(
        events: [
          SyncPullEventModel(
            id: 'evt-1',
            entity: 'product',
            operation: 'DELETE',
            payload: const {'id': 'p-del-1', 'schema_version': 1},
            createdAt: DateTime.now(),
          ),
        ],
        nextCursor: 'evt-1',
      ),
    );

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    final rows = await sql.query(
      'products',
      where: 'id = ?',
      whereArgs: ['p-del-1'],
    );
    expect(rows, isEmpty);
    expect(await prefs.getLastSyncCursor(), 'evt-1');

    await db.reset();
  });

  test('pull applies product ADJUST_STOCK and writes movement row', () async {
    final db = await createTestDb('sync_service_pull_adjust_stock');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    await sql.insert('products', {
      'id': 'p-adjust-1',
      'name': 'Test Product',
      'sell_price': 10.0,
      'cost_price': 0.0,
      'stock_qty': 5.0,
      'low_stock_threshold': 1.0,
      'unit': 'piece',
      'category': null,
      'updated_at': DateTime.now().toIso8601String(),
    });

    gateway.pullResponses.add(
      SyncPullResponseModel(
        events: [
          SyncPullEventModel(
            id: 'evt-adjust-1',
            entity: 'product',
            operation: 'ADJUST_STOCK',
            payload: const {
              'id': 'p-adjust-1',
              'delta_qty': -2.0,
              'reason': 'damage',
              'updated_at': '2026-03-04T10:00:00Z',
              'schema_version': 1,
            },
            createdAt: DateTime.parse('2026-03-04T10:00:00Z'),
          ),
        ],
        nextCursor: 'evt-adjust-1',
      ),
    );

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    final productRows = await sql.query(
      'products',
      where: 'id = ?',
      whereArgs: ['p-adjust-1'],
    );
    expect(productRows, hasLength(1));
    expect((productRows.single['stock_qty'] as num).toDouble(), 3.0);

    final movementRows = await sql.query(
      'stock_movements',
      where: 'product_id = ? AND movement_type = ?',
      whereArgs: ['p-adjust-1', 'LOSS'],
    );
    expect(movementRows, hasLength(1));
    expect((movementRows.single['delta_qty'] as num).toDouble(), -2.0);
    expect(movementRows.single['reference_id'], 'damage');
    expect(await prefs.getLastSyncCursor(), 'evt-adjust-1');

    await db.reset();
  });

  test('pull applies invoice ISSUE and writes inventory movements', () async {
    final db = await createTestDb('sync_service_pull_invoice_issue');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    await sql.insert('products', {
      'id': 'p-invoice-1',
      'name': 'Invoice Product',
      'sell_price': 250.0,
      'cost_price': 120.0,
      'stock_qty': 10.0,
      'low_stock_threshold': 2.0,
      'unit': 'piece',
      'category': null,
      'updated_at': DateTime.now().toIso8601String(),
    });

    gateway.pullResponses.add(
      SyncPullResponseModel(
        events: [
          SyncPullEventModel(
            id: 'evt-invoice-issue-1',
            entity: 'invoice',
            operation: 'ISSUE',
            payload: const {
              'id': 'inv-1',
              'business_id': 'store-1',
              'invoice_number': 'INV-2026-00001',
              'status': 'issued',
              'issue_date': '2026-03-04T10:00:00Z',
              'issue_date_ad': '2026-03-04',
              'currency_code': 'NPR',
              'subtotal': 500.0,
              'discount_amount': 0.0,
              'tax_amount': 0.0,
              'total': 500.0,
              'paid_amount': 0.0,
              'balance_due': 500.0,
              'items': [
                {
                  'id': 'inv-item-1',
                  'product_id': 'p-invoice-1',
                  'product_name_snapshot': 'Invoice Product',
                  'quantity': 2.0,
                  'unit_price': 250.0,
                  'line_total': 500.0,
                },
              ],
              'updated_at': '2026-03-04T10:00:00Z',
              'created_at': '2026-03-04T10:00:00Z',
              'schema_version': 1,
            },
            createdAt: DateTime.parse('2026-03-04T10:00:00Z'),
          ),
        ],
        nextCursor: 'evt-invoice-issue-1',
      ),
    );

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    final invoiceRows = await sql.query(
      'invoices',
      where: 'id = ?',
      whereArgs: ['inv-1'],
    );
    expect(invoiceRows, hasLength(1));
    expect(invoiceRows.single['status'], 'issued');

    final invoiceItemRows = await sql.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: ['inv-1'],
    );
    expect(invoiceItemRows, hasLength(1));

    final productRows = await sql.query(
      'products',
      where: 'id = ?',
      whereArgs: ['p-invoice-1'],
    );
    expect((productRows.single['stock_qty'] as num).toDouble(), 8.0);

    final movementRows = await sql.query(
      'stock_movements',
      where: 'product_id = ? AND movement_type = ? AND reference_id = ?',
      whereArgs: ['p-invoice-1', 'INVOICE_ISSUE', 'inv-1'],
    );
    expect(movementRows, hasLength(1));
    expect((movementRows.single['delta_qty'] as num).toDouble(), -2.0);
    expect(await prefs.getLastSyncCursor(), 'evt-invoice-issue-1');

    await db.reset();
  });

  test('pull applies sale_refund and restocks inventory', () async {
    final db = await createTestDb('sync_service_pull_sale_refund');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    final nowIso = DateTime.now().toIso8601String();
    await sql.insert('products', {
      'id': 'p-refund-1',
      'name': 'Refund Product',
      'sell_price': 100.0,
      'cost_price': 50.0,
      'stock_qty': 5.0,
      'low_stock_threshold': 1.0,
      'unit': 'piece',
      'category': null,
      'updated_at': nowIso,
    });
    await sql.insert('sales', {
      'id': 'sale-ref-1',
      'sale_type': 'CASH',
      'payment_method': 'CASH',
      'customer_id': null,
      'total_amount': 300.0,
      'sale_date_ad': '2026-03-04',
      'status': 'completed',
      'created_at': nowIso,
    });
    await sql.insert('sale_items', {
      'id': 'sale-ref-1-item-1',
      'sale_id': 'sale-ref-1',
      'product_id': 'p-refund-1',
      'qty': 3.0,
      'unit_price': 100.0,
      'line_total': 300.0,
    });

    gateway.pullResponses.add(
      SyncPullResponseModel(
        events: [
          SyncPullEventModel(
            id: 'evt-refund-1',
            entity: 'sale_refund',
            operation: 'UPSERT',
            payload: const {
              'id': 'refund-1',
              'sale_id': 'sale-ref-1',
              'amount': 100.0,
              'reason': 'Damaged pack return',
              'refund_date_ad': '2026-03-04',
              'created_at': '2026-03-04T12:00:00Z',
              'items': [
                {
                  'id': 'refund-1-item-1',
                  'product_id': 'p-refund-1',
                  'qty': 1.0,
                  'unit_price': 100.0,
                  'line_total': 100.0,
                },
              ],
              'schema_version': 1,
            },
            createdAt: DateTime.parse('2026-03-04T12:00:00Z'),
          ),
        ],
        nextCursor: 'evt-refund-1',
      ),
    );

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    final refunds = await sql.query(
      'sale_refunds',
      where: 'id = ?',
      whereArgs: ['refund-1'],
    );
    expect(refunds, hasLength(1));
    final refundItems = await sql.query(
      'sale_refund_items',
      where: 'refund_id = ?',
      whereArgs: ['refund-1'],
    );
    expect(refundItems, hasLength(1));

    final productRows = await sql.query(
      'products',
      where: 'id = ?',
      whereArgs: ['p-refund-1'],
    );
    expect((productRows.single['stock_qty'] as num).toDouble(), 6.0);

    final movementRows = await sql.query(
      'stock_movements',
      where: 'product_id = ? AND movement_type = ? AND reference_id = ?',
      whereArgs: ['p-refund-1', 'RETURN', 'refund-1'],
    );
    expect(movementRows, hasLength(1));
    expect((movementRows.single['delta_qty'] as num).toDouble(), 1.0);

    final saleRows = await sql.query(
      'sales',
      where: 'id = ?',
      whereArgs: ['sale-ref-1'],
    );
    expect(saleRows.single['status'], 'partial');
    expect((saleRows.single['total_amount'] as num).toDouble(), 200.0);
    expect(await prefs.getLastSyncCursor(), 'evt-refund-1');

    await db.reset();
  });

  test('pull applies stock_loss and records LOSS movement type', () async {
    final db = await createTestDb('sync_service_pull_stock_loss');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    await sql.insert('products', {
      'id': 'p-loss-1',
      'name': 'Loss Product',
      'sell_price': 100.0,
      'cost_price': 50.0,
      'stock_qty': 7.0,
      'low_stock_threshold': 1.0,
      'unit': 'piece',
      'category': null,
      'updated_at': DateTime.now().toIso8601String(),
    });

    gateway.pullResponses.add(
      SyncPullResponseModel(
        events: [
          SyncPullEventModel(
            id: 'evt-loss-1',
            entity: 'stock_loss',
            operation: 'UPSERT',
            payload: const {
              'id': 'loss-1',
              'product_id': 'p-loss-1',
              'qty': 2.0,
              'reason': 'Expired',
              'created_at': '2026-03-04T13:00:00Z',
              'schema_version': 1,
            },
            createdAt: DateTime.parse('2026-03-04T13:00:00Z'),
          ),
        ],
        nextCursor: 'evt-loss-1',
      ),
    );

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    final productRows = await sql.query(
      'products',
      where: 'id = ?',
      whereArgs: ['p-loss-1'],
    );
    expect((productRows.single['stock_qty'] as num).toDouble(), 5.0);

    final movementRows = await sql.query(
      'stock_movements',
      where: 'product_id = ? AND movement_type = ? AND reference_id = ?',
      whereArgs: ['p-loss-1', 'LOSS', 'loss-1'],
    );
    expect(movementRows, hasLength(1));
    expect((movementRows.single['delta_qty'] as num).toDouble(), -2.0);
    expect(await prefs.getLastSyncCursor(), 'evt-loss-1');

    await db.reset();
  });

  test(
    'pull drops invalid sale payload and applies valid sale payload',
    () async {
      final db = await createTestDb('sync_service_sale_payload_validation');
      final prefs = _FakePrefs();
      final gateway = _FakeGateway();
      final session = _FakeSessionService();
      final sql = await db.database;
      await sql.insert('products', {
        'id': 'p1',
        'name': 'Seed Product',
        'sell_price': 100.0,
        'cost_price': 40.0,
        'stock_qty': 5.0,
        'low_stock_threshold': 1.0,
        'unit': 'piece',
        'category': null,
        'updated_at': DateTime.now().toIso8601String(),
      });

      gateway.pullResponses.add(
        SyncPullResponseModel(
          events: [
            SyncPullEventModel(
              id: 'evt-sale-invalid',
              entity: 'sale',
              operation: 'UPSERT',
              payload: const {
                'id': 'sale-invalid',
                'sale_type': 'CASH',
                'payment_method': 'CASH',
                'total_amount': 100,
                'items': [],
                'created_at': '2026-03-04T10:00:00Z',
                'schema_version': 1,
              },
              createdAt: DateTime.parse('2026-03-04T10:00:00Z'),
            ),
            SyncPullEventModel(
              id: 'evt-sale-valid',
              entity: 'sale',
              operation: 'UPSERT',
              payload: const {
                'id': 'sale-valid',
                'sale_type': 'CASH',
                'payment_method': 'CASH',
                'total_amount': 200,
                'sale_date_ad': '2026-03-04',
                'status': 'completed',
                'items': [
                  {'product_id': 'p1', 'qty': 2, 'unit_price': 100},
                ],
                'created_at': '2026-03-04T10:05:00Z',
                'schema_version': 1,
              },
              createdAt: DateTime.parse('2026-03-04T10:05:00Z'),
            ),
          ],
          nextCursor: 'evt-sale-valid',
        ),
      );

      final service = SyncService(
        db,
        gateway,
        prefs,
        session,
        connectivityCheck: () async => [ConnectivityResult.wifi],
      );
      await service.processPendingSync(localeCode: 'en');

      final invalidRows = await sql.query(
        'sales',
        where: 'id = ?',
        whereArgs: ['sale-invalid'],
      );
      final validRows = await sql.query(
        'sales',
        where: 'id = ?',
        whereArgs: ['sale-valid'],
      );
      expect(invalidRows, isEmpty);
      expect(validRows, hasLength(1));
      expect(validRows.single['status'], 'completed');

      final validItems = await sql.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: ['sale-valid'],
      );
      expect(validItems, hasLength(1));
      final productRows = await sql.query(
        'products',
        where: 'id = ?',
        whereArgs: ['p1'],
      );
      expect((productRows.single['stock_qty'] as num).toDouble(), 3.0);
      final movementRows = await sql.query(
        'stock_movements',
        where: 'product_id = ? AND movement_type = ?',
        whereArgs: ['p1', 'SALE'],
      );
      expect(movementRows, hasLength(1));
      expect((movementRows.single['delta_qty'] as num).toDouble(), -2.0);

      await db.reset();
    },
  );

  test('pull paginates with cursor when page size exceeded', () async {
    final db = await createTestDb('sync_service_pull_pagination');
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    final firstPageEvents = List.generate(
      200,
      (i) => {
        'id': 'evt-$i',
        'entity': 'expense',
        'operation': 'UPSERT',
        'payload': {
          'id': 'exp-$i',
          'category': 'OTHER',
          'amount': i,
          'schema_version': 1,
        },
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    final secondPageEvents = [
      {
        'id': 'evt-200',
        'entity': 'expense',
        'operation': 'UPSERT',
        'payload': {
          'id': 'exp-200',
          'category': 'OTHER',
          'amount': 200,
          'schema_version': 1,
        },
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
    gateway.pullResponses
      ..add(
        SyncPullResponseModel.fromJson({
          'events': firstPageEvents,
          'next_cursor': 'evt-199',
        }),
      )
      ..add(
        SyncPullResponseModel.fromJson({
          'events': secondPageEvents,
          'next_cursor': 'evt-200',
        }),
      );

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
      pullChunkSize: 200,
    );
    await service.processPendingSync(localeCode: 'en');

    expect(gateway.pullCalls.length, 2);
    expect(gateway.pullCalls[0]['cursor'], isNull);
    expect(gateway.pullCalls[0]['limit'], 200);
    expect(gateway.pullCalls[1]['cursor'], 'evt-199');
    expect(await prefs.getLastSyncCursor(), 'evt-200');

    final sql = await db.database;
    final count =
        (await sql.rawQuery(
              'SELECT COUNT(*) AS total FROM expenses',
            )).first['total']
            as num;
    expect(count.toInt(), 201);

    await db.reset();
  });

  test('uses legacy lastSyncAt fallback when no cursor exists', () async {
    final db = await createTestDb('sync_service_legacy_since');
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    // Ensure "hasLocalBusinessData" is true so SyncService considers since fallback.
    final sql = await db.database;
    await sql.insert('expenses', {
      'id': 'exp-local-1',
      'category': 'OTHER',
      'amount': 10.0,
      'expense_date_ad': '2026-02-27',
      'note': 'local',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await prefs.setLastSyncAt('2026-02-23T00:00:00.000Z');
    gateway.pullResponses.add(
      const SyncPullResponseModel(events: [], nextCursor: null),
    );

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    expect(gateway.pullCalls, isNotEmpty);
    expect(gateway.pullCalls.first['cursor'], isNull);
    expect(gateway.pullCalls.first['since'], '2026-02-23T00:00:00.000Z');

    await db.reset();
  });

  test('successful sync overwrites local intelligence caches', () async {
    final db = await createTestDb('sync_service_intelligence_cache');
    final sql = await db.database;
    final prefs = _FakePrefs();
    final gateway = _FakeGateway();
    final session = _FakeSessionService();

    // Seed old cache rows to verify replace/overwrite behavior.
    await sql.insert('customer_metrics', {
      'customer_id': 'old-c1',
      'outstanding_amount': 1.0,
      'oldest_due_days': 1,
      'avg_days_to_pay': 1.0,
      'on_time_rate': 1.0,
      'payment_frequency_30d': 1.0,
      'risk_score': 1,
      'risk_level': 'green',
      'explanation_json': null,
      'version': 1,
      'computed_at': DateTime.now().toIso8601String(),
    });
    await sql.insert('alerts', {
      'id': 'old-alert',
      'type': 'credit_overdue',
      'entity_type': 'customer',
      'entity_id': 'old-c1',
      'severity': 'warn',
      'title': 'Old',
      'body': 'Old',
      'action_type': null,
      'action_payload_json': null,
      'created_at': DateTime.now().toIso8601String(),
      'resolved_at': null,
    });
    await sql.insert('product_metrics', {
      'product_id': 'old-p1',
      'product_name': 'Old Product',
      'stock_qty': 1.0,
      'cost_price': 1.0,
      'qty_sold_7d': 0.0,
      'qty_sold_30d': 0.0,
      'revenue_30d': 0.0,
      'profit_30d': 0.0,
      'last_sale_at': null,
      'dead_stock': 1,
      'dead_stock_value': 1.0,
      'computed_at': DateTime.now().toIso8601String(),
    });
    await sql.insert('business_metrics_cache', {
      'cache_key': 'default',
      'from_date': null,
      'to_date': null,
      'payload_json': '{"sales_total":1}',
      'computed_at': DateTime.now().toIso8601String(),
    });

    gateway.customerMetricsResponse = {
      'items': [
        {
          'customer_id': 'c1',
          'outstanding_amount': 500,
          'oldest_due_days': 22,
          'avg_days_to_pay': 14,
          'on_time_rate': 0.3,
          'payment_frequency_30d': 2,
          'risk_score': 74,
          'risk_level': 'red',
          'factors': {
            'oldest_due_factor': 0.5,
            'avg_days_to_pay_factor': 0.3,
            'late_behavior_factor': 0.7,
            'outstanding_spike_factor': 0.4,
          },
        },
      ],
    };
    gateway.alertsResponse = {
      'items': [
        {
          'id': 'a1',
          'type': 'credit_overdue',
          'entity_type': 'customer',
          'entity_id': 'c1',
          'severity': 'critical',
          'title': 'Credit overdue',
          'body': 'Customer owes NPR 500',
          'action_type': 'open_customer',
          'action_payload': {'customer_id': 'c1'},
          'created_at': '2026-02-24T12:00:00Z',
        },
      ],
    };
    gateway.productMetricsResponse = {
      'items': [
        {
          'product_id': 'p1',
          'product_name': 'WaiWai',
          'stock_qty': 2,
          'cost_price': 12,
          'qty_sold_7d': 18,
          'qty_sold_30d': 42,
          'revenue_30d': 840,
          'profit_30d': 210,
          'last_sale_at': '2026-02-24T11:00:00Z',
          'dead_stock': false,
          'dead_stock_value': 0,
          'computed_at': '2026-02-24T12:00:00Z',
        },
      ],
    };
    gateway.businessMetricsResponse = {
      'sales_total': 1200,
      'expenses_total': 450,
      'profit_est': 750,
      'profit_margin': 62.5,
      'outstanding_total': 800,
      'overdue_total': 500,
      'cash_risk_level': 'high',
      'low_stock_count': 1,
      'dead_stock_count': 0,
      'high_risk_customers': 1,
      'open_alerts_count': 1,
      'computed_at': '2026-02-24T12:00:00Z',
      'reasons': ['Overdue credit NPR 500.00'],
    };

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    final metricRows = await sql.query('customer_metrics');
    expect(metricRows, hasLength(1));
    expect(metricRows.single['customer_id'], 'c1');
    expect(metricRows.single['risk_level'], 'red');
    expect(metricRows.single['risk_score'], 74);

    final alertRows = await sql.query('alerts');
    expect(alertRows, hasLength(1));
    expect(alertRows.single['id'], 'a1');
    expect(alertRows.single['severity'], 'critical');
    expect(alertRows.single['action_type'], 'open_customer');

    final productRows = await sql.query('product_metrics');
    expect(productRows, hasLength(1));
    expect(productRows.single['product_id'], 'p1');
    expect(productRows.single['product_name'], 'WaiWai');
    expect((productRows.single['qty_sold_7d'] as num).toDouble(), 18);

    final businessRows = await sql.query(
      'business_metrics_cache',
      where: 'cache_key = ?',
      whereArgs: ['default'],
    );
    expect(businessRows, hasLength(1));
    final cachedPayload = Map<String, dynamic>.from(
      jsonDecode(businessRows.single['payload_json'] as String) as Map,
    );
    expect(cachedPayload['cash_risk_level'], 'high');
    expect(cachedPayload['sales_total'], 1200);

    await db.reset();
  });
}
