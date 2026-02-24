import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sme_digital/core/storage/local_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'migrates local db from v2 to v3 with contract tables/columns',
    () async {
      const dbName = 'test_migration_v2_to_v3.db';
      final path = join(await getDatabasesPath(), dbName);
      await deleteDatabase(path);

      // Create a legacy v2 shape explicitly.
      final legacy = await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE sales (
            id TEXT PRIMARY KEY,
            sale_type TEXT NOT NULL,
            customer_id TEXT,
            total_amount REAL NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
          await db.execute('''
          CREATE TABLE customer_payments (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        },
      );
      await legacy.close();

      // Opening through LocalDatabase should apply v3 migration.
      final db = LocalDatabase(dbName: dbName);
      final upgraded = await db.database;

      final salesInfo = await upgraded.rawQuery('PRAGMA table_info(sales)');
      final customerPaymentInfo = await upgraded.rawQuery(
        'PRAGMA table_info(customer_payments)',
      );
      final tables = await upgraded.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );

      final salesColumns = salesInfo.map((c) => c['name'] as String).toSet();
      final customerPaymentColumns =
          customerPaymentInfo.map((c) => c['name'] as String).toSet();
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(salesColumns.contains('payment_method'), isTrue);
      expect(customerPaymentColumns.contains('method'), isTrue);
      expect(tableNames.contains('sale_payments'), isTrue);
      expect(tableNames.contains('sale_refunds'), isTrue);
      expect(tableNames.contains('sale_refund_items'), isTrue);
      expect(tableNames.contains('stock_movements'), isTrue);

      await upgraded.close();
      await deleteDatabase(path);
    },
  );

  test(
    'migrates local db from v5 to v6 adding customer profile and soft-delete columns',
    () async {
      const dbName = 'test_migration_v5_to_v6.db';
      final path = join(await getDatabasesPath(), dbName);
      await deleteDatabase(path);

      final legacy = await openDatabase(
        path,
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE customers (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              phone TEXT,
              balance REAL NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.insert('customers', {
            'id': 'c1',
            'name': 'Ram',
            'phone': '9800000001',
            'balance': 10,
            'updated_at': DateTime.now().toIso8601String(),
          });
        },
      );
      await legacy.close();

      final db = LocalDatabase(dbName: dbName);
      final upgraded = await db.database;
      final info = await upgraded.rawQuery('PRAGMA table_info(customers)');
      final cols = info.map((c) => c['name'] as String).toSet();
      expect(cols.contains('address'), isTrue);
      expect(cols.contains('notes'), isTrue);
      expect(cols.contains('created_at'), isTrue);
      expect(cols.contains('is_deleted'), isTrue);

      final rows = await upgraded.query('customers', where: 'id = ?', whereArgs: ['c1']);
      expect(rows, isNotEmpty);
      expect((rows.first['is_deleted'] as num?)?.toInt() ?? 0, 0);

      await upgraded.close();
      await deleteDatabase(path);
    },
  );

  test(
    'migrates local db from v6 to v7 adding sync_queue outbox columns and backfill',
    () async {
      const dbName = 'test_migration_v6_to_v7.db';
      final path = join(await getDatabasesPath(), dbName);
      await deleteDatabase(path);

      final legacy = await openDatabase(
        path,
        version: 6,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entity TEXT NOT NULL,
              operation TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.insert('sync_queue', {
            'entity': 'sale',
            'operation': 'UPSERT',
            'payload': '{"id":"s1"}',
            'created_at': '2026-02-23T00:00:00.000Z',
            'synced': 0,
          });
          await db.insert('sync_queue', {
            'entity': 'product',
            'operation': 'UPSERT',
            'payload': '{"id":"p1"}',
            'created_at': '2026-02-23T00:00:01.000Z',
            'synced': 1,
          });
        },
      );
      await legacy.close();

      final db = LocalDatabase(dbName: dbName);
      final upgraded = await db.database;
      final info = await upgraded.rawQuery('PRAGMA table_info(sync_queue)');
      final cols = info.map((c) => c['name'] as String).toSet();
      expect(cols.contains('op_id'), isTrue);
      expect(cols.contains('entity_id'), isTrue);
      expect(cols.contains('status'), isTrue);
      expect(cols.contains('retry_count'), isTrue);
      expect(cols.contains('last_error'), isTrue);
      expect(cols.contains('updated_at'), isTrue);

      final rows = await upgraded.query('sync_queue', orderBy: 'id ASC');
      expect(rows.length, 2);
      expect(rows[0]['status'], 'pending');
      expect(rows[1]['status'], 'synced');
      expect(rows[0]['updated_at'], rows[0]['created_at']);
      expect(rows[1]['updated_at'], rows[1]['created_at']);

      await upgraded.close();
      await deleteDatabase(path);
    },
  );
}
