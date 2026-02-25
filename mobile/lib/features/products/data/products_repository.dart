import 'dart:convert';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/utils/uuid_id.dart';
import '../../reports/data/metrics_repository.dart';
import '../domain/product.dart';
import '../domain/stock_movement.dart';

class ProductsRepository {
  ProductsRepository(this._db, {MetricsRepository? metricsRepository})
    : _metricsRepository = metricsRepository;

  final LocalDatabase _db;
  final MetricsRepository? _metricsRepository;

  Future<List<Product>> searchProducts(String query) async {
    final db = await _db.database;
    final q = query.trim();
    final rows = await db.query(
      'products',
      where: q.isEmpty ? null : 'name LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%'],
      orderBy: 'name ASC',
      limit: 30,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> recentProducts() async {
    final db = await _db.database;
    final rows = await db.query(
      'products',
      orderBy: 'updated_at DESC',
      limit: AppConstants.quickRecentProductsLimit,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> listProducts() async {
    final db = await _db.database;
    final rows = await db.query('products', orderBy: 'updated_at DESC');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> addProduct({
    required String name,
    required double sellPrice,
    double costPrice = 0,
    required double stockQty,
    double lowStockThreshold = 0,
    String unit = 'piece',
    String? category,
  }) async {
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    final now = DateTime.now().toIso8601String();
    final id = newUuidV4();

    await db.transaction((txn) async {
      await txn.insert('products', {
        'id': id,
        'name': name,
        'sell_price': sellPrice,
        'cost_price': costPrice,
        'stock_qty': stockQty,
        'low_stock_threshold': lowStockThreshold,
        'unit': unit,
        'category': category,
        'updated_at': now,
      });

      await txn.insert('sync_queue', {
        'op_id': newUuidV4(),
        'store_id': activeStoreId,
        'entity': 'product',
        'entity_id': id,
        'operation': 'UPSERT',
        'payload': jsonEncode({
          'id': id,
          'name': name,
          'sell_price': sellPrice,
          'cost_price': costPrice,
          'stock_qty': stockQty,
          'low_stock_threshold': lowStockThreshold,
          'unit': unit,
          'category': category,
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
  }

  Future<Product?> getProductById(String id) async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT * FROM products WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<StockMovement>> getStockMovements(String productId) async {
    final db = await _db.database;
    // Try stock_movements table first, fall back to sync_queue for history
    try {
      final rows = await db.rawQuery(
        '''
        SELECT * FROM stock_movements
        WHERE product_id = ?
        ORDER BY created_at DESC
        LIMIT 50
      ''',
        [productId],
      );
      return rows.map((r) => StockMovement.fromMap(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateProduct(Product product) async {
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    final now = DateTime.now().toIso8601String();
    await db.update(
      'products',
      {
        'name': product.name,
        'sell_price': product.sellPrice,
        'cost_price': product.costPrice,
        'low_stock_threshold': product.lowStockThreshold,
        'unit': product.unit,
        'category': product.category,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await db.insert('sync_queue', {
      'op_id': newUuidV4(),
      'store_id': activeStoreId,
      'entity': 'product',
      'entity_id': product.id,
      'operation': 'UPSERT',
      'payload': jsonEncode({
        'id': product.id,
        'name': product.name,
        'sell_price': product.sellPrice,
        'cost_price': product.costPrice,
        'stock_qty': product.stockQty,
        'low_stock_threshold': product.lowStockThreshold,
        'unit': product.unit,
        'category': product.category,
        'updated_at': now,
      }),
      'created_at': now,
      'updated_at': now,
      'synced': 0,
      'status': 'pending',
      'retry_count': 0,
    });
    await _refreshLocalIntelligence();
  }

  Future<void> adjustStock({
    required String productId,
    required double delta,
    required String reason,
    String? note,
  }) async {
    return adjustStockLegacy(
      productId: productId,
      deltaQty: delta,
      reason: reason,
    );
  }

  Future<void> adjustStockLegacy({
    required String productId,
    required double deltaQty,
    required String reason,
  }) async {
    final db = await _db.database;
    final activeStoreId = await AppPreferences().getActiveStoreId();
    final now = DateTime.now().toIso8601String();
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw StateError('Reason is required');
    }
    await db.transaction((txn) async {
      final rows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Product not found');
      final row = rows.first;
      final currentQty = (row['stock_qty'] as num).toDouble();
      final nextQty = currentQty + deltaQty;
      if (nextQty < 0) {
        throw StateError('Stock cannot go below zero');
      }

      await txn.update(
        'products',
        {'stock_qty': nextQty, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [productId],
      );

      await txn.insert('sync_queue', {
        'op_id': newUuidV4(),
        'store_id': activeStoreId,
        'entity': 'product',
        'entity_id': productId,
        'operation': 'ADJUST_STOCK',
        'payload': jsonEncode({
          'id': productId,
          'delta_qty': deltaQty,
          'reason': cleanReason,
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
  }

  Future<void> _refreshLocalIntelligence() async {
    try {
      await _metricsRepository?.recomputeLocalCaches();
    } catch (_) {
      // Product writes should succeed even if intelligence cache refresh fails.
    }
  }
}
