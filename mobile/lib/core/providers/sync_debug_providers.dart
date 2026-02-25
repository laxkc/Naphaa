import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

class SyncQueueRowData {
  const SyncQueueRowData({
    required this.id,
    required this.opId,
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.status,
    required this.retryCount,
    required this.lastError,
    required this.createdAt,
    required this.updatedAt,
    required this.synced,
  });

  final int id;
  final String? opId;
  final String entity;
  final String? entityId;
  final String operation;
  final String status;
  final int retryCount;
  final String? lastError;
  final String createdAt;
  final String? updatedAt;
  final bool synced;
}

final syncQueueRowsProvider = FutureProvider<List<SyncQueueRowData>>((ref) async {
  final db = await ref.watch(localDatabaseProvider).database;
  final activeStoreId = await ref.watch(preferencesProvider).getActiveStoreId();
  final rows = await db.query(
    'sync_queue',
    where:
        '(? IS NULL OR store_id IS NULL OR store_id = ?)',
    whereArgs: [activeStoreId, activeStoreId],
    orderBy: 'synced ASC, CASE status WHEN "failed" THEN 0 WHEN "pending" THEN 1 ELSE 2 END, created_at DESC',
  );
  return rows
      .map(
        (row) => SyncQueueRowData(
          id: (row['id'] as num?)?.toInt() ?? 0,
          opId: row['op_id']?.toString(),
          entity: row['entity']?.toString() ?? 'unknown',
          entityId: row['entity_id']?.toString(),
          operation: row['operation']?.toString() ?? '',
          status: row['status']?.toString() ?? ((row['synced'] as num?) == 1 ? 'synced' : 'pending'),
          retryCount: (row['retry_count'] as num?)?.toInt() ?? 0,
          lastError: row['last_error']?.toString(),
          createdAt: row['created_at']?.toString() ?? '',
          updatedAt: row['updated_at']?.toString(),
          synced: (row['synced'] as num?) == 1,
        ),
      )
      .toList();
});
