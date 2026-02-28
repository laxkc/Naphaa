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

  test('outgoing sync payload timestamps are normalized to UTC Z strings', () async {
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
    final payload = gateway.pushedBatches.single.single['payload'] as Map<String, dynamic>;
    expect(payload['created_at'], endsWith('Z'));
    expect(payload['updated_at'], endsWith('Z'));

    await db.reset();
  });

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
      expect(rows.single['status'], 'failed');
      expect(rows.single['synced'], 0);
      expect(
        rows.single['last_error'],
        'Sync failed on server. We will retry automatically.',
      );

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
