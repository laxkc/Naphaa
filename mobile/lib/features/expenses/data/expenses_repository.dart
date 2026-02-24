import 'dart:convert';

import '../../../core/storage/local_db.dart';
import '../../../core/utils/uuid_id.dart';
import '../domain/expense.dart';

class ExpensesRepository {
  ExpensesRepository(this._db);

  final LocalDatabase _db;

  Future<List<Expense>> listExpenses() async {
    final db = await _db.database;
    final rows = await db.query('expenses', orderBy: 'created_at DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    String? note,
  }) async {
    final db = await _db.database;
    final id = newUuidV4();
    final createdAt = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert('expenses', {
        'id': id,
        'category': category.toUpperCase(),
        'amount': amount,
        'note': note,
        'created_at': createdAt,
      });

      await txn.insert('sync_queue', {
        'op_id': newUuidV4(),
        'entity': 'expense',
        'entity_id': id,
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': id,
          'category': category.toUpperCase(),
          'amount': amount,
          'note': note,
          'created_at': createdAt,
        }),
        'created_at': createdAt,
        'updated_at': createdAt,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
    });
  }
}
