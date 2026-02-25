import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/storage/local_db.dart';
import 'alerts_repository.dart';

class MetricsRepository {
  MetricsRepository(this._db, this._alerts);

  final LocalDatabase _db;
  final AlertsRepository _alerts;

  Future<void> recomputeLocalCaches() async {
    final db = await _db.database;
    late final List<Map<String, dynamic>> alerts;
    await db.transaction((txn) async {
      final customerMetrics = await _computeCustomerMetrics(txn);
      await _writeCustomerMetrics(
        txn,
        customerMetrics['items'] as List<Map<String, dynamic>>,
      );

      final productMetrics = await _computeProductMetrics(txn);
      await _writeProductMetrics(
        txn,
        productMetrics['items'] as List<Map<String, dynamic>>,
      );

      final businessMetrics = await _computeBusinessMetrics(
        txn,
        customerMetrics,
        productMetrics,
      );
      await _writeBusinessMetrics(txn, businessMetrics);

      alerts = _computeAlerts(
        customerMetrics,
        productMetrics,
        txnNowIso: DateTime.now().toIso8601String(),
      );
    });
    await _alerts.replaceOpenAlerts(alerts);
  }

  Future<Map<String, dynamic>> _computeCustomerMetrics(
    DatabaseExecutor txn,
  ) async {
    final customers = await txn.query(
      'customers',
      columns: ['id', 'name', 'phone', 'balance', 'is_deleted'],
      where: 'COALESCE(is_deleted, 0) = 0',
    );
    final saleRows = await txn.rawQuery('''
      SELECT s.id, s.customer_id, s.created_at, s.total_amount,
             SUM(CASE WHEN UPPER(COALESCE(sp.method, '')) = 'CREDIT' THEN COALESCE(sp.amount, 0) ELSE 0 END) AS credit_amount
      FROM sales s
      LEFT JOIN sale_payments sp ON sp.sale_id = s.id
      WHERE s.customer_id IS NOT NULL
      GROUP BY s.id, s.customer_id, s.created_at, s.total_amount
      ORDER BY s.created_at ASC
    ''');
    final paymentRows = await txn.query(
      'customer_payments',
      columns: ['customer_id', 'amount', 'created_at'],
      orderBy: 'created_at ASC',
    );

    final paymentsByCustomer = <String, double>{};
    for (final row in paymentRows) {
      final cid = row['customer_id']?.toString();
      if (cid == null || cid.isEmpty) continue;
      paymentsByCustomer[cid] =
          (paymentsByCustomer[cid] ?? 0) + _toDouble(row['amount']);
    }

    final salesByCustomer = <String, List<Map<String, dynamic>>>{};
    for (final row in saleRows) {
      final cid = row['customer_id']?.toString();
      if (cid == null || cid.isEmpty) continue;
      final creditAmount = _toDouble(row['credit_amount']);
      if (creditAmount <= 0) continue;
      salesByCustomer
          .putIfAbsent(cid, () => [])
          .add(Map<String, dynamic>.from(row));
    }

    final now = DateTime.now();
    final items = <Map<String, dynamic>>[];
    final totals = {'d0_7': 0.0, 'd8_30': 0.0, 'd31_60': 0.0, 'd60_plus': 0.0};
    var totalOutstanding = 0.0;
    var totalOverdue = 0.0;
    var highRiskCount = 0;
    final computedAt = now.toIso8601String();

    for (final c in customers) {
      final customerId = c['id']?.toString() ?? '';
      if (customerId.isEmpty) continue;
      final customerSales =
          salesByCustomer[customerId] ?? const <Map<String, dynamic>>[];
      var remainingPaymentCredit = paymentsByCustomer[customerId] ?? 0.0;
      final aging = {'d0_7': 0.0, 'd8_30': 0.0, 'd31_60': 0.0, 'd60_plus': 0.0};
      var oldestDueDays = 0;
      var avgInvoiceAmount = 0.0;
      if (customerSales.isNotEmpty) {
        avgInvoiceAmount =
            customerSales
                .map((s) => _toDouble(s['credit_amount']))
                .fold(0.0, (a, b) => a + b) /
            customerSales.length;
      }

      for (final sale in customerSales) {
        final creditAmount = _toDouble(sale['credit_amount']);
        if (creditAmount <= 0) continue;
        final applied =
            remainingPaymentCredit <= 0
                ? 0.0
                : (remainingPaymentCredit >= creditAmount
                    ? creditAmount
                    : remainingPaymentCredit);
        remainingPaymentCredit -= applied;
        final outstanding = creditAmount - applied;
        if (outstanding <= 0) continue;

        final createdAt =
            DateTime.tryParse(sale['created_at']?.toString() ?? '')?.toLocal();
        if (createdAt == null) continue;
        final ageDays =
            DateTime(now.year, now.month, now.day)
                .difference(
                  DateTime(createdAt.year, createdAt.month, createdAt.day),
                )
                .inDays;
        if (ageDays > oldestDueDays) oldestDueDays = ageDays;
        final key =
            ageDays <= 7
                ? 'd0_7'
                : ageDays <= 30
                ? 'd8_30'
                : ageDays <= 60
                ? 'd31_60'
                : 'd60_plus';
        aging[key] = (aging[key] ?? 0) + outstanding;
      }

      final outstandingAmount = _toDouble(c['balance']);
      totalOutstanding += outstandingAmount;
      if (oldestDueDays > 0) totalOverdue += outstandingAmount;

      // Simplified local v1 defaults for unavailable historical payment behavior.
      const avgDaysToPay = 14.0;
      const onTimeRate = 0.5;
      const paymentFrequency30d = 0.0;
      final scoreBundle = _scoreRisk(
        oldestDueDays: oldestDueDays,
        avgDaysToPay: avgDaysToPay,
        onTimeRate: onTimeRate,
        outstandingAmount: outstandingAmount,
        avgInvoiceAmount:
            avgInvoiceAmount <= 0
                ? (outstandingAmount > 0 ? outstandingAmount : 1)
                : avgInvoiceAmount,
      );
      if ((scoreBundle['risk_level'] as String) == 'red') highRiskCount += 1;

      totals['d0_7'] = (totals['d0_7'] ?? 0) + (aging['d0_7'] ?? 0);
      totals['d8_30'] = (totals['d8_30'] ?? 0) + (aging['d8_30'] ?? 0);
      totals['d31_60'] = (totals['d31_60'] ?? 0) + (aging['d31_60'] ?? 0);
      totals['d60_plus'] = (totals['d60_plus'] ?? 0) + (aging['d60_plus'] ?? 0);

      items.add({
        'customer_id': customerId,
        'customer_name': (c['name'] ?? 'Customer').toString(),
        'phone': c['phone']?.toString(),
        'outstanding_amount': outstandingAmount,
        'oldest_due_days': oldestDueDays,
        'avg_days_to_pay': avgDaysToPay,
        'on_time_rate': onTimeRate,
        'payment_frequency_30d': paymentFrequency30d,
        'risk_score': scoreBundle['risk_score'],
        'risk_level': scoreBundle['risk_level'],
        'factors': scoreBundle['factors'],
        'aging': aging,
        'computed_at': computedAt,
      });
    }

    return {
      'items': items,
      'totals': totals,
      'total_outstanding': totalOutstanding,
      'total_overdue': totalOverdue,
      'high_risk_count': highRiskCount,
      'computed_at': computedAt,
    };
  }

  Map<String, dynamic> _scoreRisk({
    required int oldestDueDays,
    required double avgDaysToPay,
    required double onTimeRate,
    required double outstandingAmount,
    required double avgInvoiceAmount,
  }) {
    double clamp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
    final a = clamp(oldestDueDays / 60);
    final b = clamp(avgDaysToPay / 30);
    final c = clamp(1 - onTimeRate);
    final d = clamp(
      outstandingAmount / ((avgInvoiceAmount <= 0 ? 1 : avgInvoiceAmount) * 3),
    );
    final score =
        (100 * ((0.40 * a) + (0.25 * b) + (0.25 * c) + (0.10 * d))).round();
    final level = score < 35 ? 'green' : (score <= 65 ? 'yellow' : 'red');
    return {
      'risk_score': score,
      'risk_level': level,
      'factors': {
        'oldest_due_factor': a,
        'avg_days_to_pay_factor': b,
        'late_behavior_factor': c,
        'outstanding_spike_factor': d,
      },
    };
  }

  Future<void> _writeCustomerMetrics(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> items,
  ) async {
    await txn.delete('customer_metrics');
    for (final item in items) {
      await txn.insert('customer_metrics', {
        'customer_id': item['customer_id'],
        'outstanding_amount': item['outstanding_amount'],
        'oldest_due_days': item['oldest_due_days'],
        'avg_days_to_pay': item['avg_days_to_pay'],
        'on_time_rate': item['on_time_rate'],
        'payment_frequency_30d': item['payment_frequency_30d'],
        'risk_score': item['risk_score'],
        'risk_level': item['risk_level'],
        'explanation_json': jsonEncode(item['factors']),
        'version': 1,
        'computed_at': item['computed_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<Map<String, dynamic>> _computeProductMetrics(
    DatabaseExecutor txn,
  ) async {
    final now = DateTime.now();
    final cutoff30 = now.subtract(const Duration(days: 30));
    final cutoff7 = now.subtract(const Duration(days: 7));
    final products = await txn.query('products');
    final saleItemRows = await txn.rawQuery('''
      SELECT si.product_id, si.qty, si.line_total, si.unit_price, s.created_at
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
    ''');
    final aggregates = <String, Map<String, dynamic>>{};
    for (final row in saleItemRows) {
      final productId = row['product_id']?.toString();
      if (productId == null || productId.isEmpty) continue;
      final createdAt =
          DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
      if (createdAt == null) continue;
      final agg = aggregates.putIfAbsent(
        productId,
        () => {
          'qty_sold_7d': 0.0,
          'qty_sold_30d': 0.0,
          'revenue_30d': 0.0,
          'last_sale_at': null,
          'sale_items': <Map<String, dynamic>>[],
        },
      );
      final qty = _toDouble(row['qty']);
      final lineTotal = _toDouble(row['line_total']);
      if (!createdAt.isBefore(cutoff30)) {
        agg['qty_sold_30d'] = (_toDouble(agg['qty_sold_30d'])) + qty;
        agg['revenue_30d'] = (_toDouble(agg['revenue_30d'])) + lineTotal;
        (agg['sale_items'] as List).add(Map<String, dynamic>.from(row));
      }
      if (!createdAt.isBefore(cutoff7)) {
        agg['qty_sold_7d'] = (_toDouble(agg['qty_sold_7d'])) + qty;
      }
      final prev = agg['last_sale_at']?.toString();
      if (prev == null || createdAt.toIso8601String().compareTo(prev) > 0) {
        agg['last_sale_at'] = createdAt.toIso8601String();
      }
    }

    final items = <Map<String, dynamic>>[];
    var deadStockCount = 0;
    var deadStockValueTotal = 0.0;
    final computedAt = now.toIso8601String();
    for (final p in products) {
      final productId = p['id']?.toString() ?? '';
      if (productId.isEmpty) continue;
      final agg = aggregates[productId] ?? const {};
      final stockQty = _toDouble(p['stock_qty']);
      final costPrice =
          p['cost_price'] == null ? null : _toDouble(p['cost_price']);
      final lastSaleAtRaw = agg['last_sale_at']?.toString();
      final lastSaleAt =
          lastSaleAtRaw == null
              ? null
              : DateTime.tryParse(lastSaleAtRaw)?.toLocal();
      final deadStock =
          stockQty > 0 &&
          (lastSaleAt == null ||
              DateTime(now.year, now.month, now.day)
                      .difference(
                        DateTime(
                          lastSaleAt.year,
                          lastSaleAt.month,
                          lastSaleAt.day,
                        ),
                      )
                      .inDays >
                  30);
      double? deadStockValue;
      if (deadStock && costPrice != null) {
        deadStockValue = stockQty * costPrice;
        deadStockValueTotal += deadStockValue;
      }
      if (deadStock) deadStockCount += 1;

      double? profit30d;
      if (costPrice != null) {
        var pft = 0.0;
        for (final raw in (agg['sale_items'] as List? ?? const [])) {
          final row = Map<String, dynamic>.from(raw as Map);
          final qty = _toDouble(row['qty']);
          final unitPrice = _toDouble(row['unit_price']);
          pft += (unitPrice - costPrice) * qty;
        }
        profit30d = pft;
      }

      items.add({
        'product_id': productId,
        'product_name': (p['name'] ?? 'Product').toString(),
        'stock_qty': stockQty,
        'cost_price': costPrice,
        'qty_sold_7d': _toDouble(agg['qty_sold_7d']),
        'qty_sold_30d': _toDouble(agg['qty_sold_30d']),
        'revenue_30d': _toDouble(agg['revenue_30d']),
        'profit_30d': profit30d,
        'last_sale_at': lastSaleAtRaw,
        'dead_stock': deadStock,
        'dead_stock_value': deadStockValue,
        'computed_at': computedAt,
      });
    }

    items.sort(
      (a, b) =>
          _toDouble(b['revenue_30d']).compareTo(_toDouble(a['revenue_30d'])),
    );
    return {
      'items': items,
      'total_products': items.length,
      'dead_stock_count': deadStockCount,
      'dead_stock_value_total': deadStockValueTotal,
      'computed_at': computedAt,
    };
  }

  Future<void> _writeProductMetrics(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> items,
  ) async {
    await txn.delete('product_metrics');
    for (final item in items) {
      await txn.insert('product_metrics', {
        'product_id': item['product_id'],
        'product_name': item['product_name'],
        'stock_qty': item['stock_qty'],
        'cost_price': item['cost_price'],
        'qty_sold_7d': item['qty_sold_7d'],
        'qty_sold_30d': item['qty_sold_30d'],
        'revenue_30d': item['revenue_30d'],
        'profit_30d': item['profit_30d'],
        'last_sale_at': item['last_sale_at'],
        'dead_stock': (item['dead_stock'] == true) ? 1 : 0,
        'dead_stock_value': item['dead_stock_value'],
        'computed_at': item['computed_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<Map<String, dynamic>> _computeBusinessMetrics(
    DatabaseExecutor txn,
    Map<String, dynamic> customerMetrics,
    Map<String, dynamic> productMetrics,
  ) async {
    final salesTotal = _toDouble(
      (await txn.rawQuery(
        'SELECT COALESCE(SUM(total_amount), 0) AS t FROM sales',
      )).first['t'],
    );
    final expensesTotal = _toDouble(
      (await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS t FROM expenses',
      )).first['t'],
    );
    final profitEst = salesTotal - expensesTotal;
    final margin = salesTotal > 0 ? (profitEst / salesTotal) * 100 : 0.0;
    final outstanding = _toDouble(customerMetrics['total_outstanding']);
    final overdue = _toDouble(customerMetrics['total_overdue']);
    final highRisk = (customerMetrics['high_risk_count'] as num?)?.toInt() ?? 0;
    final deadStockCount =
        (productMetrics['dead_stock_count'] as num?)?.toInt() ?? 0;
    final lowStockCount =
        (await txn.rawQuery('''
      SELECT COUNT(*) AS t
      FROM products
      WHERE COALESCE(low_stock_threshold, 0) > 0
        AND stock_qty <= low_stock_threshold
    ''')).first['t']
            as num;
    final reasons = <String>[];
    var cashRisk = 'low';
    if (overdue > 0)
      reasons.add('Overdue credit NPR ${overdue.toStringAsFixed(2)}');
    if (highRisk > 0) reasons.add('$highRisk high-risk customer(s)');
    if (deadStockCount > 0) reasons.add('$deadStockCount dead-stock item(s)');
    if (profitEst < 0) reasons.add('Estimated profit is negative');
    if (overdue > salesTotal && salesTotal > 0) {
      cashRisk = 'high';
    } else if (overdue > 0 || highRisk > 0 || profitEst < 0) {
      cashRisk = 'medium';
    }
    if (reasons.isEmpty) reasons.add('No major risk signals detected');
    return {
      'sales_total': salesTotal,
      'expenses_total': expensesTotal,
      'profit_est': profitEst,
      'profit_margin': margin,
      'outstanding_total': outstanding,
      'overdue_total': overdue,
      'cash_risk_level': cashRisk,
      'low_stock_count': lowStockCount.toInt(),
      'dead_stock_count': deadStockCount,
      'high_risk_customers': highRisk,
      'open_alerts_count':
          0, // filled after alerts generation; local provisional
      'computed_at': DateTime.now().toIso8601String(),
      'reasons': reasons,
      'source': 'local_cache',
      'provisional': true,
    };
  }

  Future<void> _writeBusinessMetrics(
    DatabaseExecutor txn,
    Map<String, dynamic> payload,
  ) async {
    await txn.insert('business_metrics_cache', {
      'cache_key': 'default',
      'from_date': null,
      'to_date': null,
      'payload_json': jsonEncode(payload),
      'computed_at':
          payload['computed_at']?.toString() ??
          DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  List<Map<String, dynamic>> _computeAlerts(
    Map<String, dynamic> customerMetrics,
    Map<String, dynamic> productMetrics, {
    required String txnNowIso,
  }) {
    final items = <Map<String, dynamic>>[];
    for (final raw in (customerMetrics['items'] as List? ?? const [])) {
      final item = Map<String, dynamic>.from(raw as Map);
      final riskLevel =
          (item['risk_level'] ?? 'green').toString().toLowerCase();
      final outstanding = _toDouble(item['outstanding_amount']);
      final oldestDue = _toInt(item['oldest_due_days']);
      if (outstanding <= 0 || oldestDue <= 7) continue;
      items.add({
        'id': 'credit_${item['customer_id']}',
        'type': 'credit_overdue',
        'entity_type': 'customer',
        'entity_id': item['customer_id']?.toString(),
        'severity': riskLevel == 'red' ? 'critical' : 'warn',
        'title':
            '${item['customer_name'] ?? 'Customer'} credit overdue (${oldestDue}d)',
        'body':
            '${item['customer_name'] ?? 'Customer'} owes NPR ${outstanding.toStringAsFixed(2)}',
        'action_type': 'open_customer',
        'action_payload': {'customer_id': item['customer_id']?.toString()},
        'created_at': txnNowIso,
      });
    }

    for (final raw in (productMetrics['items'] as List? ?? const []).take(10)) {
      final item = Map<String, dynamic>.from(raw as Map);
      if (item['dead_stock'] == true) {
        items.add({
          'id': 'dead_${item['product_id']}',
          'type': 'dead_stock',
          'entity_type': 'product',
          'entity_id': item['product_id']?.toString(),
          'severity': 'warn',
          'title':
              '${item['product_name'] ?? 'Product'} has not moved recently',
          'body': 'Consider discount or reorder review',
          'action_type': 'open_product',
          'action_payload': {'product_id': item['product_id']?.toString()},
          'created_at': txnNowIso,
        });
      }
    }
    return items.take(50).toList();
  }

  double _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  int _toInt(Object? v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
}
