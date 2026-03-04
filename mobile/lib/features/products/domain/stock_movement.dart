class StockMovement {
  StockMovement({
    required this.id,
    required this.productId,
    required this.delta,
    required this.reason,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String productId;
  final double delta; // positive = add, negative = remove
  final String reason; // SALE, RETURN, ADJUSTMENT, RECEIVED, DAMAGED
  final DateTime createdAt;
  final String? note;

  bool get isAddition => delta > 0;

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      delta: (map['delta'] as num? ?? map['delta_qty'] as num? ?? 0).toDouble(),
      reason:
          map['reason'] as String? ??
          map['movement_type'] as String? ??
          'ADJUSTMENT',
      createdAt: DateTime.parse(map['created_at'] as String),
      note: map['note'] as String? ?? map['reference_id'] as String?,
    );
  }
}
