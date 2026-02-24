import '../network/sync_service.dart';
import 'sync_queue.dart';

class SyncManager {
  SyncManager(this._queue) : _service = null;
  SyncManager.remote(this._service) : _queue = null;

  final SyncService? _service;
  final SyncQueueService? _queue;

  Future<int> processPendingSync({String localeCode = 'ne'}) async {
    final result = await processPendingSyncDetailed(localeCode: localeCode);
    return result.pendingAtStart;
  }

  Future<SyncRunResult> processPendingSyncDetailed({String localeCode = 'ne'}) async {
    final service = _service;
    if (service != null) {
      return service.processPendingSyncDetailed(localeCode: localeCode);
    }

    final queue = _queue;
    if (queue == null) return const SyncRunResult();
    final pending = await queue.pendingEvents();
    for (final event in pending) {
      await queue.markSynced(event['id'] as int);
    }
    return SyncRunResult(
      pendingAtStart: pending.length,
      pushedEvents: pending.length,
      ackedEvents: pending.length,
      failedEvents: 0,
      pulledEvents: 0,
      appliedEvents: 0,
    );
  }

  Future<SyncLastRunMeta> processPendingSyncWithMeta({String localeCode = 'ne'}) async {
    final service = _service;
    if (service != null) {
      return service.processPendingSyncWithMeta(localeCode: localeCode);
    }
    final result = await processPendingSyncDetailed(localeCode: localeCode);
    return SyncLastRunMeta(result: result, durationMs: 0);
  }
}
