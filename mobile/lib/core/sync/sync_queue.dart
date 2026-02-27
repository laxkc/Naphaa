import 'dart:convert';

import '../storage/local_db.dart';
import '../storage/preferences.dart';
import '../utils/uuid_id.dart';

class SyncQueueService {
  SyncQueueService(this._db);

  final LocalDatabase _db;
  final AppPreferences _prefs = AppPreferences();

  Future<void> enqueue({
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
    String? entityId,
  }) async {
    final database = await _db.database;
    final now = DateTime.now().toIso8601String();
    final activeStoreId = await _prefs.getActiveStoreId();
    await database.insert('sync_queue', {
      'op_id': newUuidV4(),
      'store_id': activeStoreId,
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
    final activeStoreId = await _prefs.getActiveStoreId();
    final hasStoreScope = activeStoreId != null && activeStoreId.isNotEmpty;
    return database.query(
      'sync_queue',
      where:
          "synced = 0 AND (COALESCE(status, 'pending') = 'pending' OR "
          "(COALESCE(status, 'pending') = 'failed' AND "
          "(next_retry_at IS NULL OR next_retry_at <= ?))) "
          "${hasStoreScope ? 'AND (store_id IS NULL OR store_id = ?)' : ''}",
      whereArgs:
          hasStoreScope
              ? [DateTime.now().toIso8601String(), activeStoreId]
              : [DateTime.now().toIso8601String()],
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
