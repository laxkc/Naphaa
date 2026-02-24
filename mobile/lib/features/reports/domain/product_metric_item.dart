class ProductMetricItem {
  const ProductMetricItem({
    required this.productId,
    required this.productName,
    required this.stockQty,
    required this.qtySold7d,
    required this.qtySold30d,
    required this.revenue30d,
    required this.deadStock,
    this.costPrice,
    this.profit30d,
    this.deadStockValue,
    this.lastSaleAt,
  });

  final String productId;
  final String productName;
  final double stockQty;
  final double qtySold7d;
  final double qtySold30d;
  final double revenue30d;
  final bool deadStock;
  final double? costPrice;
  final double? profit30d;
  final double? deadStockValue;
  final DateTime? lastSaleAt;

  factory ProductMetricItem.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    DateTime? dt;
    final raw = json['last_sale_at']?.toString();
    if (raw != null && raw.isNotEmpty) dt = DateTime.tryParse(raw);
    return ProductMetricItem(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Product',
      stockQty: toDouble(json['stock_qty']),
      qtySold7d: toDouble(json['qty_sold_7d']),
      qtySold30d: toDouble(json['qty_sold_30d']),
      revenue30d: toDouble(json['revenue_30d']),
      deadStock: json['dead_stock'] == true,
      costPrice:
          json['cost_price'] == null ? null : toDouble(json['cost_price']),
      profit30d:
          json['profit_30d'] == null ? null : toDouble(json['profit_30d']),
      deadStockValue:
          json['dead_stock_value'] == null
              ? null
              : toDouble(json['dead_stock_value']),
      lastSaleAt: dt,
    );
  }
}
