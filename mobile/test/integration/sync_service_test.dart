import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/network/backend_gateway.dart';
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
  final List<Map<String, dynamic>> pullResponses = [];
  final List<Map<String, dynamic>> pullCalls = [];

  @override
  Future<SyncPushResult> pushSync(List<Map<String, dynamic>> events) async {
    pushedBatches.add(events);
    final acked =
        pushAckBatches.isNotEmpty
            ? pushAckBatches.removeAt(0)
            : events.map((e) => e['op_id'].toString()).toList();
    final failed =
        pushFailedBatches.isNotEmpty ? pushFailedBatches.removeAt(0) : const <SyncPushFailure>[];
    return SyncPushResult(ackedOpIds: acked, failedEvents: failed);
  }

  @override
  Future<Map<String, dynamic>> pullSync({String? since, String? cursor, int? limit}) async {
    pullCalls.add({'since': since, 'cursor': cursor, 'limit': limit});
    if (pullResponses.isNotEmpty) {
      return pullResponses.removeAt(0);
    }
    return {'events': <Map<String, dynamic>>[], 'next_cursor': cursor};
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

  test('backend failed_events message is stored in outbox last_error', () async {
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
    );
    await service.processPendingSync(localeCode: 'en');

    final rows = await sql.query('sync_queue');
    expect(rows.single['status'], 'failed');
    expect(rows.single['synced'], 0);
    expect(rows.single['last_error'], contains('UNSUPPORTED_ENTITY'));

    await db.reset();
  });

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

    gateway.pullResponses.add({
      'events': [
        {
          'id': 'evt-1',
          'entity': 'product',
          'operation': 'DELETE',
          'payload': {'id': 'p-del-1', 'schema_version': 1},
          'created_at': DateTime.now().toIso8601String(),
        },
      ],
      'next_cursor': 'evt-1',
    });

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    final rows = await sql.query('products', where: 'id = ?', whereArgs: ['p-del-1']);
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
      ..add({'events': firstPageEvents, 'next_cursor': 'evt-199'})
      ..add({'events': secondPageEvents, 'next_cursor': 'evt-200'});

    final service = SyncService(
      db,
      gateway,
      prefs,
      session,
      connectivityCheck: () async => [ConnectivityResult.wifi],
    );
    await service.processPendingSync(localeCode: 'en');

    expect(gateway.pullCalls.length, 2);
    expect(gateway.pullCalls[0]['cursor'], isNull);
    expect(gateway.pullCalls[0]['limit'], 200);
    expect(gateway.pullCalls[1]['cursor'], 'evt-199');
    expect(await prefs.getLastSyncCursor(), 'evt-200');

    final sql = await db.database;
    final count = (await sql.rawQuery('SELECT COUNT(*) AS total FROM expenses')).first['total'] as num;
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
      'note': 'local',
      'created_at': DateTime.now().toIso8601String(),
    });
    await prefs.setLastSyncAt('2026-02-23T00:00:00.000Z');
    gateway.pullResponses.add({'events': <Map<String, dynamic>>[], 'next_cursor': null});

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
}
