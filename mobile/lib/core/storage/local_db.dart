import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase({this.dbName = 'sme_digital.db'});

  static final LocalDatabase instance = LocalDatabase();

  final String dbName;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, dbName),
      version: 7,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS customer_payments (
              id TEXT PRIMARY KEY,
              customer_id TEXT NOT NULL,
              amount REAL NOT NULL,
              note TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'CASH'",
          );
          await db.execute(
            "ALTER TABLE customer_payments ADD COLUMN method TEXT NOT NULL DEFAULT 'CASH'",
          );
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sale_payments (
              id TEXT PRIMARY KEY,
              sale_id TEXT NOT NULL,
              method TEXT NOT NULL,
              amount REAL NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sale_refunds (
              id TEXT PRIMARY KEY,
              sale_id TEXT NOT NULL,
              amount REAL NOT NULL,
              reason TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sale_refund_items (
              id TEXT PRIMARY KEY,
              refund_id TEXT NOT NULL,
              sale_id TEXT NOT NULL,
              product_id TEXT NOT NULL,
              qty REAL NOT NULL,
              unit_price REAL NOT NULL,
              line_total REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS stock_movements (
              id TEXT PRIMARY KEY,
              product_id TEXT NOT NULL,
              movement_type TEXT NOT NULL,
              delta_qty REAL NOT NULL,
              reference_id TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          // Add product fields introduced after early schema versions.
          try {
            await db.execute(
              "ALTER TABLE products ADD COLUMN cost_price REAL NOT NULL DEFAULT 0",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'piece'",
            );
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE products ADD COLUMN category TEXT");
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute(
              "ALTER TABLE products ADD COLUMN low_stock_threshold REAL NOT NULL DEFAULT 0",
            );
          } catch (_) {}
        }
        if (oldVersion < 6) {
          // Customer schema fields used by newer repository/model code.
          try {
            await db.execute("ALTER TABLE customers ADD COLUMN address TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE customers ADD COLUMN notes TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE customers ADD COLUMN created_at TEXT");
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE customers ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0",
            );
          } catch (_) {}
        }
        if (oldVersion < 7) {
          try {
            await db.execute("ALTER TABLE sync_queue ADD COLUMN op_id TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE sync_queue ADD COLUMN entity_id TEXT");
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE sync_queue ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE sync_queue ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0",
            );
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE sync_queue ADD COLUMN last_error TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE sync_queue ADD COLUMN updated_at TEXT");
          } catch (_) {}
          try {
            await db.execute(
              "UPDATE sync_queue SET status = CASE WHEN synced = 1 THEN 'synced' ELSE 'pending' END",
            );
          } catch (_) {}
          try {
            await db.execute(
              "UPDATE sync_queue SET updated_at = created_at WHERE updated_at IS NULL",
            );
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sell_price REAL NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        stock_qty REAL NOT NULL,
        low_stock_threshold REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'piece',
        category TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        balance REAL NOT NULL DEFAULT 0,
        created_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        sale_type TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'CASH',
        customer_id TEXT,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        qty REAL NOT NULL,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_payments (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_refunds (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        amount REAL NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_refund_items (
        id TEXT PRIMARY KEY,
        refund_id TEXT NOT NULL,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        qty REAL NOT NULL,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        delta_qty REAL NOT NULL,
        reference_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_payments (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'CASH',
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        op_id TEXT,
        entity TEXT NOT NULL,
        entity_id TEXT,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
  }

  Future<void> reset() async {
    final current = _database;
    if (current != null && current.isOpen) {
      await current.close();
    }
    _database = null;
    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, dbName));
  }

  Future<void> seedIfEmpty() async {
    final db = await database;
    final rows =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
    if (rows > 0) return;

    final now = DateTime.now().toIso8601String();
    await db.insert('products', {
      'id': _id(),
      'name': 'Rice',
      'sell_price': 120.0,
      'stock_qty': 80.0,
      'updated_at': now,
    });
    await db.insert('products', {
      'id': _id(),
      'name': 'Oil',
      'sell_price': 350.0,
      'stock_qty': 30.0,
      'updated_at': now,
    });
    await db.insert('products', {
      'id': _id(),
      'name': 'Sugar',
      'sell_price': 90.0,
      'stock_qty': 50.0,
      'updated_at': now,
    });
  }

  Future<void> injectRealisticTestData({int salesCount = 100}) async {
    final db = await database;
    final rng = Random(42);
    final now = DateTime.now();
    var seq = 0;

    String nextId(String prefix) {
      seq += 1;
      return '${prefix}_${now.microsecondsSinceEpoch}_$seq';
    }

    final products = <Map<String, dynamic>>[
      {'name': 'Rice 1kg', 'price': 95.0, 'stock': 240.0},
      {'name': 'Rice 5kg', 'price': 470.0, 'stock': 160.0},
      {'name': 'Sunflower Oil 1L', 'price': 365.0, 'stock': 180.0},
      {'name': 'Mustard Oil 1L', 'price': 420.0, 'stock': 120.0},
      {'name': 'Sugar 1kg', 'price': 90.0, 'stock': 220.0},
      {'name': 'Salt 1kg', 'price': 30.0, 'stock': 300.0},
      {'name': 'Lentil Masoor 1kg', 'price': 165.0, 'stock': 180.0},
      {'name': 'Chana Dal 1kg', 'price': 145.0, 'stock': 160.0},
      {'name': 'Noodles Pack', 'price': 25.0, 'stock': 420.0},
      {'name': 'Biscuits Pack', 'price': 20.0, 'stock': 380.0},
      {'name': 'Tea 250g', 'price': 140.0, 'stock': 120.0},
      {'name': 'Milk 1L', 'price': 110.0, 'stock': 160.0},
      {'name': 'Egg Tray', 'price': 460.0, 'stock': 70.0},
      {'name': 'Soap Bar', 'price': 45.0, 'stock': 260.0},
      {'name': 'Detergent 1kg', 'price': 230.0, 'stock': 90.0},
      {'name': 'Toothpaste', 'price': 85.0, 'stock': 140.0},
      {'name': 'Shampoo Sachet', 'price': 10.0, 'stock': 500.0},
      {'name': 'Soft Drink 1.5L', 'price': 155.0, 'stock': 110.0},
      {'name': 'Mineral Water 1L', 'price': 35.0, 'stock': 260.0},
      {'name': 'Instant Coffee', 'price': 190.0, 'stock': 85.0},
    ];

    final customerNames = <String>[
      'Hari',
      'Sita',
      'Gopal',
      'Mina',
      'Ramesh',
      'Bina',
      'Krishna',
      'Nirmala',
      'Suman',
      'Nabin',
      'Anita',
      'Rita',
      'Dipesh',
      'Prakash',
      'Sarita',
      'Asha',
      'Rajan',
      'Puja',
      'Bikash',
      'Sabina',
      'Roshan',
      'Sujan',
      'Pratima',
      'Manish',
      'Samjhana',
    ];

    await db.transaction((txn) async {
      await txn.delete('sale_items');
      await txn.delete('sales');
      await txn.delete('expenses');
      await txn.delete('customers');
      await txn.delete('products');
      await txn.delete('sync_queue');

      final productRecords = <Map<String, dynamic>>[];
      for (final product in products) {
        final row = {
          'id': nextId('product'),
          'name': product['name'] as String,
          'sell_price': product['price'] as double,
          'stock_qty': product['stock'] as double,
          'updated_at': now.toIso8601String(),
        };
        productRecords.add(row);
        await txn.insert('products', row);
      }

      final customerIds = <String>[];
      for (var i = 0; i < customerNames.length; i++) {
        final customerId = nextId('customer');
        customerIds.add(customerId);
        await txn.insert('customers', {
          'id': customerId,
          'name': customerNames[i],
          'phone': '98${(10000000 + i).toString().padLeft(8, '0')}',
          'balance': 0.0,
          'updated_at': now.toIso8601String(),
        });
      }

      final inventory = {
        for (final p in productRecords)
          p['id'] as String: (p['stock_qty'] as double),
      };

      for (var i = 0; i < salesCount; i++) {
        final saleId = nextId('sale');
        final isCredit = rng.nextDouble() < 0.35;
        final customerId =
            isCredit ? customerIds[rng.nextInt(customerIds.length)] : null;
        final itemCount = 1 + rng.nextInt(4);
        final usedProductIds = <String>{};
        var total = 0.0;

        for (var j = 0; j < itemCount; j++) {
          var pick = productRecords[rng.nextInt(productRecords.length)];
          var retries = 0;
          while ((usedProductIds.contains(pick['id']) ||
                  (inventory[pick['id']] ?? 0) < 1) &&
              retries < 10) {
            pick = productRecords[rng.nextInt(productRecords.length)];
            retries++;
          }
          final productId = pick['id'] as String;
          if (usedProductIds.contains(productId) ||
              (inventory[productId] ?? 0) < 1) {
            continue;
          }

          usedProductIds.add(productId);
          final maxQty = min(5, (inventory[productId] ?? 1).floor());
          final qty = max(1, 1 + rng.nextInt(maxQty));
          final unitPrice = pick['sell_price'] as double;
          final lineTotal = qty * unitPrice;
          total += lineTotal;

          inventory[productId] = (inventory[productId] ?? 0) - qty;
          await txn.insert('sale_items', {
            'id': nextId('item'),
            'sale_id': saleId,
            'product_id': productId,
            'qty': qty.toDouble(),
            'unit_price': unitPrice,
            'line_total': lineTotal,
          });
          await txn.update(
            'products',
            {
              'stock_qty': inventory[productId],
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [productId],
          );
        }

        if (total <= 0) continue;

        final saleDate = now.subtract(
          Duration(
            days: rng.nextInt(21),
            hours: rng.nextInt(14),
            minutes: rng.nextInt(60),
          ),
        );

        await txn.insert('sales', {
          'id': saleId,
          'sale_type': isCredit ? 'CREDIT' : 'CASH',
          'payment_method': isCredit ? 'CREDIT' : 'CASH',
          'customer_id': customerId,
          'total_amount': total,
          'created_at': saleDate.toIso8601String(),
        });

        await txn.insert('sale_payments', {
          'id': nextId('salepay'),
          'sale_id': saleId,
          'method': isCredit ? 'CREDIT' : 'CASH',
          'amount': total,
          'created_at': saleDate.toIso8601String(),
        });

        if (isCredit && customerId != null) {
          await txn.rawUpdate(
            'UPDATE customers SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [total, now.toIso8601String(), customerId],
          );
        }

        await txn.insert('sync_queue', {
          'entity': 'sale',
          'operation': 'UPSERT',
          'payload': '{"seeded":true}',
          'created_at': saleDate.toIso8601String(),
          'synced': 1,
        });
      }

      const categories = ['RENT', 'TRANSPORT', 'UTILITIES', 'SALARY', 'OTHER'];
      for (var i = 0; i < 35; i++) {
        final expenseDate = now.subtract(
          Duration(
            days: rng.nextInt(21),
            hours: rng.nextInt(18),
            minutes: rng.nextInt(60),
          ),
        );
        await txn.insert('expenses', {
          'id': nextId('expense'),
          'category': categories[rng.nextInt(categories.length)],
          'amount': 200 + rng.nextInt(3200) + (rng.nextDouble()),
          'note': 'Seeded expense ${i + 1}',
          'created_at': expenseDate.toIso8601String(),
        });
      }
    });
  }

  String _id() {
    final r = Random();
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(16)}${r.nextInt(1 << 20).toRadixString(16)}';
  }
}
