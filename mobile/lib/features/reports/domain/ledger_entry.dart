class LedgerEntryItem {
  const LedgerEntryItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.entryType,
    required this.direction,
    required this.amount,
    required this.createdAt,
    this.customerId,
    this.saleId,
    this.metadata,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String entryType;
  final String direction;
  final double amount;
  final DateTime createdAt;
  final String? customerId;
  final String? saleId;
  final Map<String, dynamic>? metadata;

  factory LedgerEntryItem.fromJson(Map<String, dynamic> json) {
    return LedgerEntryItem(
      id: json['id']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString() ?? '',
      entryType: json['entry_type']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'IN',
      amount: _toDouble(json['amount']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      customerId: json['customer_id']?.toString(),
      saleId: json['sale_id']?.toString(),
      metadata: json['metadata_json'] is Map
          ? Map<String, dynamic>.from(json['metadata_json'] as Map)
          : null,
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
