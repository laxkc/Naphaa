import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_digital/core/sync/sync_queue.dart';

import '../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pendingEvents excludes blocked and future failed retries', () async {
    final db = await createTestDb('sync_queue_pending_gate');
    final sql = await db.database;
    final queue = SyncQueueService(db);
    final now = DateTime.now();

    await sql.insert('sync_queue', {
      'op_id': 'op-pending',
      'entity': 'expense',
      'entity_id': 'e1',
      'operation': 'UPSERT',
      'payload': '{"id":"e1"}',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
    });
    await sql.insert('sync_queue', {
      'op_id': 'op-failed-future',
      'entity': 'expense',
      'entity_id': 'e2',
      'operation': 'UPSERT',
      'payload': '{"id":"e2"}',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'synced': 0,
      'status': 'failed',
      'retry_count': 1,
      'next_retry_at': now.add(const Duration(minutes: 10)).toIso8601String(),
    });
    await sql.insert('sync_queue', {
      'op_id': 'op-blocked',
      'entity': 'expense',
      'entity_id': 'e3',
      'operation': 'UPSERT',
      'payload': '{"id":"e3"}',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'synced': 0,
      'status': 'blocked',
      'retry_count': 5,
    });

    final pending = await queue.pendingEvents();
    expect(pending, hasLength(1));
    expect(pending.single['op_id'], 'op-pending');

    await db.reset();
  });
}
