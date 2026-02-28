import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../storage/local_db.dart';
import '../storage/preferences.dart';
import '../utils/uuid_id.dart';
import '../date/business_time.dart';
import '../config/app_config.dart';
import '../sync/sync_error_mapper.dart';
import 'backend_gateway.dart';
import 'session_service.dart';

class SyncRunResult {
  const SyncRunResult({
    this.pendingAtStart = 0,
    this.pushedEvents = 0,
    this.ackedEvents = 0,
    this.failedEvents = 0,
    this.pulledEvents = 0,
    this.appliedEvents = 0,
  });

  final int pendingAtStart;
  final int pushedEvents;
  final int ackedEvents;
  final int failedEvents;
  final int pulledEvents;
  final int appliedEvents;

  bool get hasFailures => failedEvents > 0;
}

class SyncLastRunMeta {
  const SyncLastRunMeta({required this.result, required this.durationMs});

  final SyncRunResult result;
  final int durationMs;
}

class SyncService {
  SyncService(
    this._db,
    this._gateway,
    this._prefs,
    this._session, {
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
    int pushChunkSize = AppConfig.syncPushChunkSize,
    int pullChunkSize = AppConfig.syncPullChunkSize,
  }) : _connectivityCheck =
           connectivityCheck ?? (() => Connectivity().checkConnectivity()),
       _pushChunkSize = pushChunkSize <= 0 ? 50 : pushChunkSize,
       _pullChunkSize = pullChunkSize <= 0 ? 100 : pullChunkSize;

  final int _pushChunkSize;
  final int _pullChunkSize;

  final LocalDatabase _db;
  final BackendGateway _gateway;
  final AppPreferences _prefs;
  final SessionService _session;
  final Future<List<ConnectivityResult>> Function() _connectivityCheck;
  static const int _maxRetryCount = 5;
  static const int _baseRetrySeconds = 5;

  Map<String, dynamic> _normalizeOutgoingPayload(Map<String, dynamic> payload) {
    Object? normalize(Object? value, {String? key}) {
      if (value is Map) {
        return <String, dynamic>{
          for (final entry in value.entries)
            entry.key.toString(): normalize(entry.value, key: entry.key.toString()),
        };
      }
      if (value is List) {
        return value.map((item) => normalize(item)).toList();
      }
      if (key != null && (key == 'created_at' || key == 'updated_at' || key == 'deleted_at' || key.endsWith('_at'))) {
        return BusinessTime.normalizeUtcIso(value);
      }
      return value;
    }

    return Map<String, dynamic>.from(
      normalize(payload) as Map<String, dynamic>,
    );
  }

  Future<int> processPendingSync({required String localeCode}) async {
    final result = await processPendingSyncDetailed(localeCode: localeCode);
    return result.pendingAtStart;
  }

  Future<SyncRunResult> processPendingSyncDetailed({
    required String localeCode,
  }) async {
    final startedAt = DateTime.now();
    var result = const SyncRunResult();
    final connectivity = await _connectivityCheck();
    final hasNetwork = connectivity.any((it) => it != ConnectivityResult.none);
    if (!hasNetwork) {
      _logRun('skip_offline', result, startedAt);
      return result;
    }

    try {
      await _session.ensureReady(localeCode: localeCode);
    } on SessionAuthException {
      rethrow;
    } catch (_) {
      _logRun('skip_session_not_ready', result, startedAt);
      return result;
    }

    final db = await _db.database;
    final deviceId = await _prefs.getOrCreateDeviceId();
    final activeStoreId = await _prefs.getActiveStoreId();
    if (activeStoreId != null && activeStoreId.isNotEmpty) {
      final nowIso = BusinessTime.nowUtcIso();
      await db.rawUpdate(
        '''
        UPDATE sync_queue
        SET status = 'archived',
            last_error = COALESCE(last_error, 'Archived: queued under a different account/store'),
            updated_at = ?
        WHERE synced = 0
          AND store_id IS NOT NULL
          AND store_id != ?
          AND COALESCE(status, 'pending') != 'archived'
        ''',
        [nowIso, activeStoreId],
      );
    }
    final localSalesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sales'),
        ) ??
        0;
    final localCustomersCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;
    final localExpensesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM expenses'),
        ) ??
        0;
    final hasLocalBusinessData =
        localSalesCount > 0 ||
        localCustomersCount > 0 ||
        localExpensesCount > 0;

    final nowIso = BusinessTime.nowUtcIso();
    final hasStoreScope = activeStoreId != null && activeStoreId.isNotEmpty;
    final pending = await db.query(
      'sync_queue',
      where:
          "synced = 0 AND (COALESCE(status, 'pending') = 'pending' OR "
          "(COALESCE(status, 'pending') = 'failed' AND "
          "(next_retry_at IS NULL OR next_retry_at <= ?))) "
          "${hasStoreScope ? 'AND (store_id IS NULL OR store_id = ?)' : ''}",
      whereArgs: hasStoreScope ? [nowIso, activeStoreId] : [nowIso],
      // Prioritize new pending dependencies (e.g. product UPSERT recovery) before
      // retrying older failed rows such as dependent sale events.
      orderBy:
          "CASE COALESCE(status, 'pending') WHEN 'pending' THEN 0 WHEN 'failed' THEN 1 ELSE 2 END, id ASC",
    );
    result = SyncRunResult(
      pendingAtStart: pending.length,
      pushedEvents: result.pushedEvents,
      ackedEvents: result.ackedEvents,
      failedEvents: result.failedEvents,
      pulledEvents: result.pulledEvents,
      appliedEvents: result.appliedEvents,
    );

    if (pending.isNotEmpty) {
      final ids = pending.map((e) => e['id'] as int).toList();
      final startedAt = BusinessTime.nowUtcIso();
      final markSyncing = db.batch();
      final rowsWithOpIds = <Map<String, dynamic>>[];
      for (final id in ids) {
        final row = pending.firstWhere((e) => e['id'] == id);
        var opId = row['op_id'] as String?;
        if (opId == null || opId.isEmpty) {
          opId = newUuidV4();
          markSyncing.update(
            'sync_queue',
            {'op_id': opId, 'status': 'syncing', 'updated_at': startedAt},
            where: 'id = ?',
            whereArgs: [id],
          );
          rowsWithOpIds.add({...row, 'op_id': opId});
          continue;
        }
        rowsWithOpIds.add(row);
        markSyncing.update(
          'sync_queue',
          {'status': 'syncing', 'updated_at': startedAt},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await markSyncing.commit(noResult: true);

      try {
        for (var i = 0; i < rowsWithOpIds.length; i += _pushChunkSize) {
          final chunk = rowsWithOpIds.skip(i).take(_pushChunkSize).toList();
          final pushedEvents = result.pushedEvents + chunk.length;
          final events =
              chunk
                  .map(
                    (row) => {
                      'op_id': row['op_id'],
                      'device_id': deviceId,
                      'entity': row['entity'],
                      'operation': row['operation'],
                      'payload': _normalizeOutgoingPayload({
                        ...Map<String, dynamic>.from(
                          jsonDecode(row['payload'] as String) as Map,
                        ),
                        'schema_version': 1,
                      }),
                    },
                  )
                  .toList();
          final pushResult = await _gateway.pushSync(events);
          final ackedOpIds = pushResult.ackedOpIds.toSet();
          final failedByOpId = <String, String>{
            for (final failed in pushResult.failedEvents)
              if (failed.opId != null && failed.opId!.isNotEmpty)
                failed.opId!:
                    SyncErrorMapper.fromFailedEvent(failed).userMessage,
          };
          for (final failed in pushResult.failedEvents) {
            if (failed.entity?.toLowerCase() == 'sale' &&
                failed.code == 'PRODUCT_NOT_FOUND' &&
                failed.opId != null &&
                failed.opId!.isNotEmpty) {
              final sourceRow = chunk.cast<Map<String, dynamic>?>().firstWhere(
                (row) => row?['op_id'] == failed.opId,
                orElse: () => null,
              );
              if (sourceRow != null) {
                await _enqueueMissingProductDependenciesForSale(db, sourceRow);
              }
            }
          }
          for (final failed in pushResult.failedEvents) {
            final mapped = SyncErrorMapper.fromFailedEvent(failed);
            developer.log(
              'sync_push_failed category=${mapped.category.name} opId=${failed.opId ?? '-'} detail=${mapped.developerDetail}',
              name: 'app.sync',
            );
          }

          final batch = db.batch();
          final now = BusinessTime.nowUtcIso();
          for (final row in chunk) {
            final id = row['id'] as int;
            final opId = row['op_id'] as String?;
            final acked = opId != null && ackedOpIds.contains(opId);
            batch.update(
              'sync_queue',
              {
                'synced': acked ? 1 : 0,
                'status': acked ? 'synced' : 'failed',
                'next_retry_at':
                    acked ? null : _nextRetryAtIso(_nextRetryCount(row)),
                'last_error':
                    acked
                        ? null
                        : (failedByOpId[opId] ??
                            'Sync failed on server. We will retry automatically.'),
                'retry_count':
                    acked ? row['retry_count'] : _nextRetryCount(row),
                'updated_at': now,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            if (!acked && _nextRetryCount(row) >= _maxRetryCount) {
              batch.update(
                'sync_queue',
                {
                  'status': 'blocked',
                  'next_retry_at': null,
                  'last_error':
                      '${failedByOpId[opId] ?? 'Sync failed on server.'} Max retries reached. Please review in Sync Diagnostics.',
                  'updated_at': now,
                },
                where: 'id = ?',
                whereArgs: [id],
              );
            }
          }
          result = SyncRunResult(
            pendingAtStart: result.pendingAtStart,
            pushedEvents: pushedEvents,
            ackedEvents: result.ackedEvents + ackedOpIds.length,
            failedEvents:
                result.failedEvents + (chunk.length - ackedOpIds.length),
            pulledEvents: result.pulledEvents,
            appliedEvents: result.appliedEvents,
          );
          await batch.commit(noResult: true);
        }
      } catch (e) {
        final now = BusinessTime.nowUtcIso();
        final mapped = SyncErrorMapper.fromException(e);
        final safeMsg = mapped.userMessage;
        developer.log(
          'sync_push_exception category=${mapped.category.name} detail=${mapped.developerDetail}',
          name: 'app.sync',
        );
        final batch = db.batch();
        for (final row in rowsWithOpIds) {
          final id = row['id'] as int;
          final nextRetryCount = _nextRetryCount(row);
          final blocked = nextRetryCount >= _maxRetryCount;
          batch.update(
            'sync_queue',
            {
              'status': blocked ? 'blocked' : 'failed',
              'retry_count': nextRetryCount,
              'next_retry_at': blocked ? null : _nextRetryAtIso(nextRetryCount),
              'last_error':
                  blocked
                      ? '$safeMsg Max retries reached. Please review in Sync Diagnostics.'
                      : safeMsg,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
        result = SyncRunResult(
          pendingAtStart: result.pendingAtStart,
          pushedEvents: result.pushedEvents,
          ackedEvents: result.ackedEvents,
          failedEvents: result.failedEvents + ids.length,
          pulledEvents: result.pulledEvents,
          appliedEvents: result.appliedEvents,
        );
        await batch.commit(noResult: true);
      }
    }

    final localCursor = await _prefs.getLastSyncCursor();
    final localSince = await _prefs.getLastSyncAt();
    final since =
        (hasLocalBusinessData &&
                (localCursor == null || localCursor.isEmpty) &&
                localSince != null &&
                localSince.isNotEmpty)
            ? localSince
            : null;
    var activeCursor =
        (localCursor != null && localCursor.isNotEmpty) ? localCursor : null;
    var legacySince = since;
    var pulledCustomerFinancialChanges = false;
    while (true) {
      final pullBody = await _gateway.pullSync(
        cursor: activeCursor,
        since: activeCursor == null ? legacySince : null,
        limit: _pullChunkSize,
      );
      final pulled = pullBody.events;

      if (pulled.isNotEmpty) {
        final shouldReconcileCustomerBalances = pulled.any(
          (event) => switch (event.entity) {
            'sale' => true,
            'customer_payment' => true,
            'customer' => true,
            _ => false,
          },
        );
        pulledCustomerFinancialChanges =
            pulledCustomerFinancialChanges || shouldReconcileCustomerBalances;
        await db.transaction((txn) async {
          for (final event in pulled) {
            await _applyEvent(txn, {
              'id': event.id,
              'entity': event.entity,
              'operation': event.operation,
              'payload': event.payload,
              if (event.createdAt != null)
                'created_at': event.createdAt!.toIso8601String(),
            });
          }
          if (shouldReconcileCustomerBalances) {
            await _reconcileCustomerBalances(txn);
          }
        });
        result = SyncRunResult(
          pendingAtStart: result.pendingAtStart,
          pushedEvents: result.pushedEvents,
          ackedEvents: result.ackedEvents,
          failedEvents: result.failedEvents,
          pulledEvents: result.pulledEvents + pulled.length,
          appliedEvents: result.appliedEvents + pulled.length,
        );
      }

      final nextCursor = pullBody.nextCursor;
      if (nextCursor != null && nextCursor.isNotEmpty) {
        activeCursor = nextCursor;
        await _prefs.setLastSyncCursor(nextCursor);
      }

      if (pulled.length < _pullChunkSize) {
        break;
      }
      // After first page, only continue with cursor pagination.
      legacySince = null;
    }
    // Safety repair for older local data that may have stale customer balances even
    // when the current sync pull returns 0 events.
    if (!pulledCustomerFinancialChanges) {
      await db.transaction((txn) async {
        await _reconcileCustomerBalances(txn);
      });
    }
    await _refreshIntelligenceCaches();
    await _prefs.setLastSyncAt(BusinessTime.nowUtcIso());
    _logRun('success', result, startedAt);
    return result;
  }

  Future<void> _refreshIntelligenceCaches() async {
    try {
      final db = await _db.database;
      final customerBody = await _gateway.getCustomerMetrics(limit: 500);
      final alertBody = await _gateway.getAlerts(limit: 100);
      final productBody = await _gateway.getProductMetrics(
        limit: 500,
        windowDays: 30,
        deadStockDays: 30,
      );
      final businessBody = await _gateway.getBusinessMetrics();
      await db.transaction((txn) async {
        await _overwriteCustomerMetricsCache(txn, customerBody);
        await _overwriteAlertsCache(txn, alertBody);
        await _overwriteProductMetricsCache(txn, productBody);
        await _overwriteBusinessMetricsCache(txn, businessBody);
      });
    } catch (e) {
      developer.log(
        'intelligence_cache_refresh_skip error=$e',
        name: 'app.sync',
      );
    }
  }

  int _nextRetryCount(Map<String, dynamic> row) {
    final current = (row['retry_count'] as num?)?.toInt() ?? 0;
    return current + 1;
  }

  String _nextRetryAtIso(int retryCount) {
    final retryStep = retryCount <= 0 ? 1 : retryCount;
    final seconds = _baseRetrySeconds * (1 << (retryStep - 1));
    final clampedSeconds = seconds > 300 ? 300 : seconds;
    return DateTime.now()
        .add(Duration(seconds: clampedSeconds))
        .toIso8601String();
  }

  Future<void> _overwriteCustomerMetricsCache(
    DatabaseExecutor txn,
    Map<String, dynamic> body,
  ) async {
    final now = BusinessTime.nowUtcIso();
    final items = (body['items'] as List? ?? const []).whereType<Map>();
    await txn.delete('customer_metrics');
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw);
      final customerId = item['customer_id']?.toString();
      if (customerId == null || customerId.isEmpty) continue;
      await txn.insert('customer_metrics', {
        'customer_id': customerId,
        'outstanding_amount': _toDoubleAny(item['outstanding_amount']),
        'oldest_due_days': _toIntAny(item['oldest_due_days']),
        'avg_days_to_pay': _toDoubleAny(item['avg_days_to_pay']),
        'on_time_rate': _toDoubleAny(item['on_time_rate']),
        'payment_frequency_30d': _toDoubleAny(item['payment_frequency_30d']),
        'risk_score': _toIntAny(item['risk_score']),
        'risk_level': (item['risk_level'] ?? 'green').toString(),
        'explanation_json':
            item['factors'] == null ? null : jsonEncode(item['factors']),
        'version': _toIntAny(item['version'], fallback: 1),
        'computed_at': (item['computed_at'] ?? now).toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _overwriteAlertsCache(
    DatabaseExecutor txn,
    Map<String, dynamic> body,
  ) async {
    final items = (body['items'] as List? ?? const []).whereType<Map>();
    await txn.delete('alerts');
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw);
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      await txn.insert('alerts', {
        'id': id,
        'type': (item['type'] ?? 'generic').toString(),
        'entity_type': (item['entity_type'] ?? 'business').toString(),
        'entity_id': item['entity_id']?.toString(),
        'severity': (item['severity'] ?? 'info').toString(),
        'title': (item['title'] ?? 'Alert').toString(),
        'body': (item['body'] ?? '').toString(),
        'action_type': item['action_type']?.toString(),
        'action_payload_json':
            item['action_payload'] == null
                ? null
                : jsonEncode(item['action_payload']),
        'created_at':
            BusinessTime.normalizeUtcIso(item['created_at']),
        'resolved_at': item['resolved_at']?.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _overwriteProductMetricsCache(
    DatabaseExecutor txn,
    Map<String, dynamic> body,
  ) async {
    final items = (body['items'] as List? ?? const []).whereType<Map>();
    await txn.delete('product_metrics');
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw);
      final productId = item['product_id']?.toString();
      if (productId == null || productId.isEmpty) continue;
      await txn.insert('product_metrics', {
        'product_id': productId,
        'product_name': (item['product_name'] ?? 'Product').toString(),
        'stock_qty': _toDoubleAny(item['stock_qty']),
        'cost_price':
            item['cost_price'] == null
                ? null
                : _toDoubleAny(item['cost_price']),
        'qty_sold_7d': _toDoubleAny(item['qty_sold_7d']),
        'qty_sold_30d': _toDoubleAny(item['qty_sold_30d']),
        'revenue_30d': _toDoubleAny(item['revenue_30d']),
        'profit_30d':
            item['profit_30d'] == null
                ? null
                : _toDoubleAny(item['profit_30d']),
        'last_sale_at': item['last_sale_at']?.toString(),
        'dead_stock': item['dead_stock'] == true ? 1 : 0,
        'dead_stock_value':
            item['dead_stock_value'] == null
                ? null
                : _toDoubleAny(item['dead_stock_value']),
        'computed_at':
            BusinessTime.normalizeUtcIso(item['computed_at']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _overwriteBusinessMetricsCache(
    DatabaseExecutor txn,
    Map<String, dynamic> body,
  ) async {
    final now = BusinessTime.nowUtcIso();
    await txn.insert('business_metrics_cache', {
      'cache_key': 'default',
      'from_date': body['period_start']?.toString(),
      'to_date': body['period_end']?.toString(),
      'payload_json': jsonEncode(body),
      'computed_at': (body['computed_at'] ?? now).toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _enqueueMissingProductDependenciesForSale(
    Database db,
    Map<String, dynamic> saleQueueRow,
  ) async {
    final activeStoreId = await _prefs.getActiveStoreId();
    final payloadRaw = saleQueueRow['payload'] as String?;
    if (payloadRaw == null || payloadRaw.isEmpty) return;
    Map<String, dynamic> payload;
    try {
      payload = Map<String, dynamic>.from(jsonDecode(payloadRaw) as Map);
    } catch (_) {
      return;
    }
    final items = (payload['items'] as List? ?? const []);
    final productIds = <String>{
      for (final raw in items)
        if (raw is Map &&
            raw['product_id']?.toString().trim().isNotEmpty == true)
          raw['product_id'].toString().trim(),
    };
    if (productIds.isEmpty) return;

    final now = BusinessTime.nowUtcIso();
    for (final productId in productIds) {
      final hasStoreScope = activeStoreId != null && activeStoreId.isNotEmpty;
      final existingPending =
          Sqflite.firstIntValue(
            await db.rawQuery('''
              SELECT 1
              FROM sync_queue
              WHERE entity = 'product'
                AND entity_id = ?
                AND operation = 'UPSERT'
                AND synced = 0
                AND COALESCE(status, 'pending') IN ('pending', 'syncing', 'failed', 'blocked')
                ${hasStoreScope ? 'AND (store_id IS NULL OR store_id = ?)' : ''}
              LIMIT 1
              ''', hasStoreScope ? [productId, activeStoreId] : [productId]),
          ) ??
          0;
      if (existingPending == 1) continue;

      final rows = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) continue;
      final row = rows.first;
      await db.insert('sync_queue', {
        'op_id': newUuidV4(),
        'store_id': activeStoreId,
        'entity': 'product',
        'entity_id': productId,
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': productId,
          'name': row['name'],
          'sell_price': (row['sell_price'] as num?)?.toDouble() ?? 0,
          'cost_price': (row['cost_price'] as num?)?.toDouble() ?? 0,
          'stock_qty': (row['stock_qty'] as num?)?.toDouble() ?? 0,
          'low_stock_threshold':
              (row['low_stock_threshold'] as num?)?.toDouble() ?? 0,
          'unit': (row['unit'] ?? 'piece').toString(),
          'category': row['category']?.toString(),
          'updated_at': row['updated_at']?.toString() ?? now,
        }),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
    }
  }

  Future<SyncLastRunMeta> processPendingSyncWithMeta({
    required String localeCode,
  }) async {
    final started = DateTime.now();
    final result = await processPendingSyncDetailed(localeCode: localeCode);
    final durationMs = DateTime.now().difference(started).inMilliseconds;
    return SyncLastRunMeta(result: result, durationMs: durationMs);
  }

  void _logRun(String phase, SyncRunResult result, DateTime startedAt) {
    final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
    developer.log(
      'sync_run phase=$phase pending=${result.pendingAtStart} pushed=${result.pushedEvents} '
      'acked=${result.ackedEvents} failed=${result.failedEvents} pulled=${result.pulledEvents} '
      'applied=${result.appliedEvents} pushChunk=$_pushChunkSize pullChunk=$_pullChunkSize '
      'durationMs=$durationMs',
      name: 'app.sync',
    );
  }

  Future<void> _applyEvent(
    DatabaseExecutor txn,
    Map<String, dynamic> event,
  ) async {
    final entity = (event['entity'] ?? '').toString();
    final payload = Map<String, dynamic>.from(
      event['payload'] as Map? ?? const {},
    );

    if (entity == 'product') {
      final operation = (event['operation'] ?? '').toString().toUpperCase();
      if (operation == 'DELETE') {
        final productId = payload['id']?.toString();
        if (productId == null || productId.isEmpty) return;
        // Cache-prune policy: backend keeps product soft-delete history; mobile cache
        // removes hidden products to keep local queries/simple UI fast.
        await txn.delete('products', where: 'id = ?', whereArgs: [productId]);
        return;
      }
      if (operation == 'ADJUST_STOCK') {
        final productId = payload['id']?.toString();
        final delta = (payload['delta_qty'] as num?)?.toDouble() ?? 0;
        if (productId == null || productId.isEmpty) return;
        final current = await txn.query(
          'products',
          columns: ['stock_qty'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (current.isEmpty) return;
        final currentQty = (current.first['stock_qty'] as num).toDouble();
        final nextQty = currentQty + delta;
        if (nextQty < 0) return;
        await txn.update(
          'products',
          {
            'stock_qty': nextQty,
            'updated_at':
                BusinessTime.normalizeUtcIso(payload['updated_at']),
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
        return;
      }

      await txn.insert('products', {
        'id': payload['id'],
        'name': payload['name'],
        'sell_price': (payload['sell_price'] as num?)?.toDouble() ?? 0,
        'cost_price': (payload['cost_price'] as num?)?.toDouble() ?? 0,
        'stock_qty': (payload['stock_qty'] as num?)?.toDouble() ?? 0,
        'low_stock_threshold':
            (payload['low_stock_threshold'] as num?)?.toDouble() ?? 0,
        'unit': (payload['unit'] ?? 'piece').toString(),
        'category': payload['category']?.toString(),
        'updated_at':
            BusinessTime.normalizeUtcIso(payload['updated_at']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (entity == 'customer') {
      final operation = (event['operation'] ?? '').toString().toUpperCase();
      if (operation == 'DELETE') {
        final customerId = payload['id']?.toString();
        if (customerId == null || customerId.isEmpty) return;
        // Customer history matters for ledgers/credit views, so mobile keeps a local
        // tombstone instead of hard-deleting the cache row.
        await txn.update(
          'customers',
          {
            'is_deleted': 1,
            'updated_at':
                payload['updated_at']?.toString() ??
                DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [customerId],
        );
        return;
      }
      await txn.insert('customers', {
        'id': payload['id'],
        'name': payload['name'],
        'phone': payload['phone'],
        'balance': (payload['balance'] as num?)?.toDouble() ?? 0,
        'created_at': BusinessTime.normalizeUtcIso(payload['created_at']),
        'is_deleted': (payload['is_deleted'] == true) ? 1 : 0,
        'updated_at': BusinessTime.normalizeUtcIso(payload['updated_at']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (entity == 'customer_payment') {
      final customerId = payload['customer_id']?.toString();
      if (customerId == null || customerId.isEmpty) return;
      final amount = (payload['amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) return;

      await txn.insert('customer_payments', {
        'id': payload['id'] ?? '${customerId}_${payload['created_at']}',
        'customer_id': customerId,
        'method': (payload['method'] ?? 'CASH').toString().toUpperCase(),
        'amount': amount,
        'note': payload['note'],
        'payment_date_ad':
            payload['payment_date_ad']?.toString() ??
            _businessDateFromPayload(payload),
        'created_at': BusinessTime.normalizeUtcIso(payload['created_at']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.rawUpdate(
        'UPDATE customers SET balance = MAX(balance - ?, 0), updated_at = ? WHERE id = ?',
        [amount, BusinessTime.nowUtcIso(), customerId],
      );
      return;
    }

    if (entity == 'expense') {
      final operation = (event['operation'] ?? '').toString().toUpperCase();
      if (operation == 'DELETE') {
        final expenseId = payload['id']?.toString();
        if (expenseId == null || expenseId.isEmpty) return;
        // Cache-prune policy: backend is the audit source of truth (soft delete);
        // mobile removes deleted expenses from the local cache.
        await txn.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
        return;
      }
      await txn.insert('expenses', {
        'id': payload['id'],
        'category': payload['category'],
        'amount': (payload['amount'] as num?)?.toDouble() ?? 0,
        'note': payload['note'],
        'expense_date_ad':
            payload['expense_date_ad']?.toString() ??
            _businessDateFromPayload(payload),
        'created_at': BusinessTime.normalizeUtcIso(payload['created_at']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (entity == 'sale') {
      final saleId = payload['id']?.toString();
      if (saleId == null || saleId.isEmpty) return;
      final existingSaleRows = await txn.query(
        'sales',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      // Sale events are append-only snapshots in current sync contract. Skip if
      // already applied to avoid double stock/customer-balance effects.
      if (existingSaleRows.isNotEmpty) return;

      await txn.insert('sales', {
        'id': saleId,
        'sale_type': payload['sale_type'] ?? 'CASH',
        'payment_method': payload['payment_method'] ?? 'CASH',
        'customer_id': payload['customer_id'],
        'total_amount': (payload['total_amount'] as num?)?.toDouble() ?? 0,
        'sale_date_ad':
            payload['sale_date_ad']?.toString() ?? _businessDateFromPayload(payload),
        'created_at': BusinessTime.normalizeUtcIso(payload['created_at']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      final items = (payload['items'] as List? ?? const []);
      for (final it in items) {
        final item = Map<String, dynamic>.from(it as Map);
        await txn.insert('sale_items', {
          'id': '${saleId}_${item['product_id']}_${item['qty']}',
          'sale_id': saleId,
          'product_id': item['product_id'],
          'qty': (item['qty'] as num?)?.toDouble() ?? 0,
          'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0,
          'line_total':
              ((item['qty'] as num?)?.toDouble() ?? 0) *
              ((item['unit_price'] as num?)?.toDouble() ?? 0),
        });
      }

      await txn.delete(
        'sale_payments',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final payments = (payload['payments'] as List? ?? const []);
      if (payments.isEmpty) {
        final total = (payload['total_amount'] as num?)?.toDouble() ?? 0;
        await txn.insert('sale_payments', {
          'id': '${saleId}_payment',
          'sale_id': saleId,
          'method': (payload['payment_method'] ?? 'CASH').toString(),
          'amount': total,
          'created_at':
              BusinessTime.normalizeUtcIso(payload['created_at']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        for (final p in payments) {
          final payment = Map<String, dynamic>.from(p as Map);
          await txn.insert('sale_payments', {
            'id':
                payment['id']?.toString() ??
                '${saleId}_${payment['method']}_${payment['amount']}',
            'sale_id': saleId,
            'method': payment['method'],
            'amount': (payment['amount'] as num?)?.toDouble() ?? 0,
            'created_at':
                BusinessTime.normalizeUtcIso(payment['created_at']),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      final customerId = payload['customer_id']?.toString();
      final creditAmount = _saleCreditAmount(payload);
      if (customerId != null && customerId.isNotEmpty && creditAmount > 0) {
        await txn.rawUpdate(
          '''
          UPDATE customers
          SET balance = COALESCE(balance, 0) + ?,
              updated_at = ?
          WHERE id = ?
          ''',
          [creditAmount, BusinessTime.nowUtcIso(), customerId],
        );
      }
    }
  }

  String _businessDateFromPayload(Map<String, dynamic> payload) {
    final createdAt = payload['created_at'];
    final parsed =
        createdAt == null ? null : DateTime.tryParse(createdAt.toString());
    return BusinessTime.businessDateAd(
      timestampUtc: (parsed ?? BusinessTime.nowUtc()).toUtc(),
    );
  }

  double _saleCreditAmount(Map<String, dynamic> payload) {
    final payments = payload['payments'];
    if (payments is List && payments.isNotEmpty) {
      var total = 0.0;
      for (final raw in payments) {
        if (raw is! Map) continue;
        final method = (raw['method'] ?? '').toString().toUpperCase();
        if (method != 'CREDIT') continue;
        total +=
            (raw['amount'] as num?)?.toDouble() ??
            double.tryParse(raw['amount']?.toString() ?? '') ??
            0.0;
      }
      return total;
    }
    final saleType = (payload['sale_type'] ?? '').toString().toUpperCase();
    if (saleType == 'CREDIT') {
      return (payload['total_amount'] as num?)?.toDouble() ??
          double.tryParse(payload['total_amount']?.toString() ?? '') ??
          0.0;
    }
    return 0.0;
  }

  double _toDoubleAny(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _toIntAny(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _reconcileCustomerBalances(DatabaseExecutor txn) async {
    // Rebuild receivable balances from local financial facts. This repairs stale
    // balances from older app versions that synced sales without updating
    // customers.balance locally.
    await txn.rawUpdate(
      '''
      UPDATE customers
      SET balance = 0,
          updated_at = COALESCE(updated_at, ?)
      ''',
      [BusinessTime.nowUtcIso()],
    );

    await txn.rawUpdate(
      '''
      UPDATE customers
      SET balance = COALESCE((
            SELECT SUM(sp.amount)
            FROM sales s
            JOIN sale_payments sp ON sp.sale_id = s.id
            WHERE s.customer_id = customers.id
              AND UPPER(COALESCE(sp.method, '')) = 'CREDIT'
          ), 0)
          - COALESCE((
            SELECT SUM(cp.amount)
            FROM customer_payments cp
            WHERE cp.customer_id = customers.id
          ), 0),
          updated_at = ?
      ''',
      [BusinessTime.nowUtcIso()],
    );

    await txn.rawUpdate(
      '''
      UPDATE customers
      SET balance = 0,
          updated_at = ?
      WHERE balance < 0
      ''',
      [BusinessTime.nowUtcIso()],
    );
  }
}
