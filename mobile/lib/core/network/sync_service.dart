import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../storage/local_db.dart';
import '../storage/preferences.dart';
import '../utils/uuid_id.dart';
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

class SyncService {
  SyncService(
    this._db,
    this._gateway,
    this._prefs,
    this._session, {
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
  }) : _connectivityCheck =
           connectivityCheck ?? (() => Connectivity().checkConnectivity());

  static const int _pushChunkSize = 100;
  static const int _pullChunkSize = 200;

  final LocalDatabase _db;
  final BackendGateway _gateway;
  final AppPreferences _prefs;
  final SessionService _session;
  final Future<List<ConnectivityResult>> Function() _connectivityCheck;

  Future<int> processPendingSync({required String localeCode}) async {
    final result = await processPendingSyncDetailed(localeCode: localeCode);
    return result.pendingAtStart;
  }

  Future<SyncRunResult> processPendingSyncDetailed({
    required String localeCode,
  }) async {
    var result = const SyncRunResult();
    final connectivity = await _connectivityCheck();
    final hasNetwork = connectivity.any((it) => it != ConnectivityResult.none);
    if (!hasNetwork) return result;

    try {
      await _session.ensureReady(localeCode: localeCode);
    } catch (_) {
      return result;
    }

    final db = await _db.database;
    final deviceId = await _prefs.getOrCreateDeviceId();
    final localSalesCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sales')) ??
        0;
    final localCustomersCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;
    final localExpensesCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM expenses')) ??
        0;
    final hasLocalBusinessData =
        localSalesCount > 0 || localCustomersCount > 0 || localExpensesCount > 0;

    final pending = await db.query(
      'sync_queue',
      where: "synced = 0 AND COALESCE(status, 'pending') IN ('pending', 'failed')",
      orderBy: 'id ASC',
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
      final startedAt = DateTime.now().toIso8601String();
      final markSyncing = db.batch();
      final rowsWithOpIds = <Map<String, dynamic>>[];
      for (final id in ids) {
        final row = pending.firstWhere((e) => e['id'] == id);
        var opId = row['op_id'] as String?;
        if (opId == null || opId.isEmpty) {
          opId = newUuidV4();
          markSyncing.update(
            'sync_queue',
            {
              'op_id': opId,
              'status': 'syncing',
              'updated_at': startedAt,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          rowsWithOpIds.add({...row, 'op_id': opId});
          continue;
        }
        rowsWithOpIds.add(row);
        markSyncing.update(
          'sync_queue',
          {
            'status': 'syncing',
            'updated_at': startedAt,
          },
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
                      'payload': {
                        ...Map<String, dynamic>.from(
                          jsonDecode(row['payload'] as String) as Map,
                        ),
                        'schema_version': 1,
                      },
                    },
                  )
                  .toList();
          final pushResult = await _gateway.pushSync(events);
          final ackedOpIds = pushResult.ackedOpIds.toSet();
          final failedByOpId = <String, String>{
            for (final failed in pushResult.failedEvents)
              if (failed.opId != null && failed.opId!.isNotEmpty)
                failed.opId!: '${failed.code}: ${failed.message}',
          };

          final batch = db.batch();
          final now = DateTime.now().toIso8601String();
          for (final row in chunk) {
            final id = row['id'] as int;
            final opId = row['op_id'] as String?;
            final acked = opId != null && ackedOpIds.contains(opId);
            batch.update(
              'sync_queue',
              {
                'synced': acked ? 1 : 0,
                'status': acked ? 'synced' : 'failed',
                'last_error':
                    acked
                        ? null
                        : (failedByOpId[opId] ?? 'Server did not acknowledge event'),
                'updated_at': now,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            if (!acked) {
              batch.rawUpdate(
                '''
                UPDATE sync_queue
                SET retry_count = COALESCE(retry_count, 0) + 1
                WHERE id = ?
                ''',
                [id],
              );
            }
          }
          result = SyncRunResult(
            pendingAtStart: result.pendingAtStart,
            pushedEvents: pushedEvents,
            ackedEvents: result.ackedEvents + ackedOpIds.length,
            failedEvents: result.failedEvents + (chunk.length - ackedOpIds.length),
            pulledEvents: result.pulledEvents,
            appliedEvents: result.appliedEvents,
          );
          await batch.commit(noResult: true);
        }
      } catch (e) {
        final now = DateTime.now().toIso8601String();
        final msg = e.toString();
        final safeMsg = msg.length > 500 ? msg.substring(0, 500) : msg;
        final batch = db.batch();
        for (final id in ids) {
          batch.rawUpdate(
            '''
            UPDATE sync_queue
            SET status = 'failed',
                retry_count = COALESCE(retry_count, 0) + 1,
                last_error = ?,
                updated_at = ?
            WHERE id = ?
            ''',
            [safeMsg, now, id],
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
    while (true) {
      final pullBody = await _gateway.pullSync(
        cursor: activeCursor,
        since: activeCursor == null ? legacySince : null,
        limit: _pullChunkSize,
      );
      final pulled =
          (pullBody['events'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

      if (pulled.isNotEmpty) {
        await db.transaction((txn) async {
          for (final event in pulled) {
            await _applyEvent(txn, event);
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

      final nextCursor = pullBody['next_cursor']?.toString();
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
    await _prefs.setLastSyncAt(DateTime.now().toIso8601String());
    return result;
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
                payload['updated_at'] ?? DateTime.now().toIso8601String(),
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
            payload['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (entity == 'customer') {
      final operation = (event['operation'] ?? '').toString().toUpperCase();
      if (operation == 'DELETE') {
        final customerId = payload['id']?.toString();
        if (customerId == null || customerId.isEmpty) return;
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
        'is_deleted': (payload['is_deleted'] == true) ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
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
        'created_at': payload['created_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.rawUpdate(
        'UPDATE customers SET balance = MAX(balance - ?, 0), updated_at = ? WHERE id = ?',
        [amount, DateTime.now().toIso8601String(), customerId],
      );
      return;
    }

    if (entity == 'expense') {
      final operation = (event['operation'] ?? '').toString().toUpperCase();
      if (operation == 'DELETE') {
        final expenseId = payload['id']?.toString();
        if (expenseId == null || expenseId.isEmpty) return;
        await txn.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
        return;
      }
      await txn.insert('expenses', {
        'id': payload['id'],
        'category': payload['category'],
        'amount': (payload['amount'] as num?)?.toDouble() ?? 0,
        'note': payload['note'],
        'created_at': payload['created_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    if (entity == 'sale') {
      final saleId = payload['id']?.toString();
      if (saleId == null || saleId.isEmpty) return;

      await txn.insert('sales', {
        'id': saleId,
        'sale_type': payload['sale_type'] ?? 'CASH',
        'payment_method': payload['payment_method'] ?? 'CASH',
        'customer_id': payload['customer_id'],
        'total_amount': (payload['total_amount'] as num?)?.toDouble() ?? 0,
        'created_at': payload['created_at'] ?? DateTime.now().toIso8601String(),
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
              payload['created_at'] ?? DateTime.now().toIso8601String(),
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
                payment['created_at']?.toString() ??
                DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
  }
}
