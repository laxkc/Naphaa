import 'dart:convert';

import '../../../core/storage/local_db.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/date/business_time.dart';
import '../../../core/utils/uuid_id.dart';
import '../../reports/data/metrics_repository.dart';
import '../domain/expense.dart';

class ExpensesRepository {
  ExpensesRepository(
    this._db, {
    AppPreferences? preferences,
    MetricsRepository? metricsRepository,
  }) : _prefs = preferences ?? AppPreferences(),
       _metricsRepository = metricsRepository;

  final LocalDatabase _db;
  final AppPreferences _prefs;
  final MetricsRepository? _metricsRepository;

  Future<List<Expense>> listExpenses() async {
    final db = await _db.database;
    final rows = await db.query(
      'expenses',
      orderBy: 'expense_date_ad DESC, created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    String? note,
  }) async {
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    final id = newUuidV4();
    final createdAt = BusinessTime.nowUtcIso();
    final expenseDateAd = BusinessTime.businessDateAd(
      timezone: await _prefs.getBusinessTimezone(),
    );

    await db.transaction((txn) async {
      await txn.insert('expenses', {
        'id': id,
        'category': category.toUpperCase(),
        'amount': amount,
        'note': note,
        'expense_date_ad': expenseDateAd,
        'created_at': createdAt,
      });

      await txn.insert('sync_queue', {
        'op_id': newUuidV4(),
        'store_id': activeStoreId,
        'entity': 'expense',
        'entity_id': id,
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': id,
          'category': category.toUpperCase(),
          'amount': amount,
          'note': note,
          'expense_date_ad': expenseDateAd,
          'created_at': createdAt,
        }),
        'created_at': createdAt,
        'updated_at': createdAt,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
    });
    await _refreshLocalIntelligence();
  }

  Future<void> _refreshLocalIntelligence() async {
    try {
      await _metricsRepository?.recomputeLocalCaches();
    } catch (_) {
      // Never block the primary local write path on analytics cache refresh.
    }
  }
}
