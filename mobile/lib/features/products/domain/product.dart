class Product {
  Product({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.stockQty,
    this.costPrice = 0,
    this.lowStockThreshold = 0,
    this.unit = 'piece',
    this.category,
    this.createdAt,
  });

  final String id;
  final String name;
  final double sellPrice;
  final double costPrice;
  final double stockQty;
  final double lowStockThreshold;
  final String unit;
  final String? category;
  final DateTime? createdAt;

  double get margin =>
      costPrice > 0 ? ((sellPrice - costPrice) / costPrice) * 100 : 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      sellPrice: (map['sell_price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num? ?? 0).toDouble(),
      stockQty: (map['stock_qty'] as num).toDouble(),
      lowStockThreshold: (map['low_stock_threshold'] as num? ?? 0).toDouble(),
      unit: map['unit'] as String? ?? 'piece',
      category: map['category'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sell_price': sellPrice,
      'cost_price': costPrice,
      'stock_qty': stockQty,
      'low_stock_threshold': lowStockThreshold,
      'unit': unit,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? sellPrice,
    double? costPrice,
    double? stockQty,
    double? lowStockThreshold,
    String? unit,
    String? category,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQty: stockQty ?? this.stockQty,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
