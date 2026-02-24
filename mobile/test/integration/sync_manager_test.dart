import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/sync/sync_manager.dart';
import 'package:sme_digital/core/sync/sync_queue.dart';

import '../helpers/test_db.dart';

void main() {
  test('sync manager marks pending events as synced', () async {
    final db = await createTestDb('sync_manager');
    final queue = SyncQueueService(db);

    await queue.enqueue(
      entity: 'sale',
      operation: 'UPSERT',
      payload: {'id': 's1'},
    );
    await queue.enqueue(
      entity: 'sale',
      operation: 'UPSERT',
      payload: {'id': 's2'},
    );

    final manager = SyncManager(queue);
    final count = await manager.processPendingSync();
    expect(count, 2);

    final pending = await queue.pendingEvents();
    expect(pending, isEmpty);

    await db.reset();
  });
}
