import 'dart:convert';

import '../../../core/storage/local_db.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/utils/uuid_id.dart';
import '../../reports/data/metrics_repository.dart';
import '../domain/customer.dart';

class CustomersRepository {
  CustomersRepository(this._db, {MetricsRepository? metricsRepository})
    : _metricsRepository = metricsRepository;

  final LocalDatabase _db;
  final MetricsRepository? _metricsRepository;

  Future<List<Customer>> listCustomers() async {
    final db = await _db.database;
    final rows = await db.query(
      'customers',
      where: '(is_deleted IS NULL OR is_deleted = 0)',
      // Owing customers first (so "Pay" actions are easy to find), then
      // alphabetical for predictable browsing.
      orderBy:
          'CASE WHEN COALESCE(balance, 0) > 0 THEN 0 ELSE 1 END, name COLLATE NOCASE ASC, updated_at DESC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<String> addCustomer({required String name, String? phone}) async {
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    final now = DateTime.now().toIso8601String();
    final id = newUuidV4();

    await db.transaction((txn) async {
      await txn.insert('customers', {
        'id': id,
        'name': name,
        'phone': phone,
        'address': null,
        'notes': null,
        'balance': 0,
        'created_at': now,
        'is_deleted': 0,
        'updated_at': now,
      });

      await txn.insert('sync_queue', {
        'op_id': newUuidV4(),
        'store_id': activeStoreId,
        'entity': 'customer',
        'entity_id': id,
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': id,
          'name': name,
          'phone': phone,
          'balance': 0,
          'updated_at': now,
        }),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
    });
    await _refreshLocalIntelligence();
    return id;
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT * FROM customers WHERE id = ? AND (is_deleted IS NULL OR is_deleted = 0)',
      [id],
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<List<Map<String, dynamic>>> getCustomerLedger(
    String customerId,
  ) async {
    final db = await _db.database;
    final salesRows = await db.rawQuery(
      '''
      SELECT id, created_at, total_amount as amount,
             'SALE' as entry_type, sale_type, null as note
      FROM sales
      WHERE customer_id = ? AND sale_type = 'CREDIT'
    ''',
      [customerId],
    );
    final paymentRows = await db.rawQuery(
      '''
      SELECT id, created_at, amount,
             'PAYMENT' as entry_type, null as sale_type, note
      FROM customer_payments
      WHERE customer_id = ?
    ''',
      [customerId],
    );
    final all = [...salesRows, ...paymentRows];
    all.sort(
      (a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String),
    );
    return all;
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'customers',
      {
        'name': customer.name,
        'phone': customer.phone,
        'address': customer.address,
        'notes': customer.notes,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    await _refreshLocalIntelligence();
  }

  Future<void> softDeleteCustomer(String id) async {
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'customers',
        {'is_deleted': 1, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('sync_queue', {
        'op_id': newUuidV4(),
        'store_id': activeStoreId,
        'entity': 'customer',
        'entity_id': id,
        'operation': 'DELETE',
        'payload': jsonEncode({
          'id': id,
          'is_deleted': true,
          'updated_at': now,
          'deleted_at': now,
        }),
        'created_at': now,
        'updated_at': now,
        'synced': 0,
        'status': 'pending',
        'retry_count': 0,
      });
    });
    await _refreshLocalIntelligence();
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String method = 'CASH',
    String? note,
  }) async {
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    final now = DateTime.now().toIso8601String();
    if (amount <= 0) throw StateError('Amount must be greater than zero');

    await db.transaction((txn) async {
      final rows = await txn.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Customer not found');
      final row = rows.first;
      final balance = (row['balance'] as num).toDouble();
      if (amount > balance) throw StateError('Amount cannot exceed balance');
      final nextBalance = balance - amount;

      final paymentId = newUuidV4();
      await txn.insert('customer_payments', {
        'id': paymentId,
        'customer_id': customerId,
        'method': method.toUpperCase(),
        'amount': amount,
        'note': note?.trim().isEmpty ?? true ? null : note?.trim(),
        'created_at': now,
      });

      await txn.update(
        'customers',
        {'balance': nextBalance, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      await txn.insert('sync_queue', {
        'op_id': newUuidV4(),
        'store_id': activeStoreId,
        'entity': 'customer_payment',
        'entity_id': paymentId,
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': paymentId,
          'customer_id': customerId,
          'method': method.toUpperCase(),
          'amount': amount,
          'note': note,
          'created_at': now,
        }),
        'created_at': now,
        'updated_at': now,
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
      // Keep local customer flows fast/reliable even if analytics cache refresh fails.
    }
  }
}
