import 'dart:convert';

import '../storage/local_db.dart';
import '../utils/uuid_id.dart';

class SyncQueueService {
  SyncQueueService(this._db);

  final LocalDatabase _db;

  Future<void> enqueue({
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
    String? entityId,
  }) async {
    final database = await _db.database;
    final now = DateTime.now().toIso8601String();
    await database.insert('sync_queue', {
      'op_id': newUuidV4(),
      'entity': entity,
      'entity_id': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': now,
      'updated_at': now,
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
      'last_error': null,
    });
  }

  Future<List<Map<String, dynamic>>> pendingEvents() async {
    final database = await _db.database;
    return database.query(
      'sync_queue',
      where: "synced = 0 AND COALESCE(status, 'pending') IN ('pending', 'failed')",
      orderBy: 'id ASC',
    );
  }

  Future<void> markSynced(int id) async {
    final database = await _db.database;
    await database.update(
      'sync_queue',
      {
        'synced': 1,
        'status': 'synced',
        'last_error': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
