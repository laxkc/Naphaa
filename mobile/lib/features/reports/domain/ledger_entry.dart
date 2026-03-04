import 'dart:convert';

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
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      customerId: json['customer_id']?.toString(),
      saleId: json['sale_id']?.toString(),
      metadata: _parseMetadata(json['metadata_json']),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, dynamic>? _parseMetadata(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}
