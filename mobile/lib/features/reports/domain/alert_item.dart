class AlertItem {
  const AlertItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.entityType,
    this.entityId,
    this.actionType,
    this.actionPayload,
    this.createdAt,
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String body;
  final String entityType;
  final String? entityId;
  final String? actionType;
  final Map<String, dynamic>? actionPayload;
  final DateTime? createdAt;

  bool get isCritical => severity.toLowerCase() == 'critical';
  bool get isWarn => severity.toLowerCase() == 'warn';

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    final rawDate = json['created_at']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      dt = DateTime.tryParse(rawDate);
    }
    return AlertItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'generic',
      severity: json['severity']?.toString() ?? 'info',
      title: json['title']?.toString() ?? 'Alert',
      body: json['body']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? 'business',
      entityId: json['entity_id']?.toString(),
      actionType: json['action_type']?.toString(),
      actionPayload:
          json['action_payload'] is Map
              ? Map<String, dynamic>.from(json['action_payload'] as Map)
              : null,
      createdAt: dt,
    );
  }
}
