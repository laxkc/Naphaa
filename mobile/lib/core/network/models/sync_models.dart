class SyncPushFailure {
  const SyncPushFailure({
    required this.opId,
    required this.entity,
    required this.operation,
    required this.code,
    required this.message,
  });

  final String? opId;
  final String? entity;
  final String? operation;
  final String code;
  final String message;

  factory SyncPushFailure.fromJson(Map<String, dynamic> json) {
    return SyncPushFailure(
      opId: json['op_id']?.toString(),
      entity: json['entity']?.toString(),
      operation: json['operation']?.toString(),
      code: json['code']?.toString() ?? 'SYNC_FAILED',
      message: json['message']?.toString() ?? 'Failed to apply sync event',
    );
  }
}

class SyncPushResponseModel {
  const SyncPushResponseModel({
    required this.ackedOpIds,
    required this.failedEvents,
  });

  final List<String> ackedOpIds;
  final List<SyncPushFailure> failedEvents;

  factory SyncPushResponseModel.fromJson(Map<String, dynamic> json) {
    final acked =
        (json['acked_op_ids'] as List? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
    final failed =
        (json['failed_events'] as List? ?? const [])
            .whereType<Map>()
            .map((raw) => SyncPushFailure.fromJson(Map<String, dynamic>.from(raw)))
            .toList();
    return SyncPushResponseModel(ackedOpIds: acked, failedEvents: failed);
  }
}

class SyncPullEventModel {
  const SyncPullEventModel({
    required this.id,
    required this.entity,
    required this.operation,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String entity;
  final String operation;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  factory SyncPullEventModel.fromJson(Map<String, dynamic> json) {
    return SyncPullEventModel(
      id: json['id']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      operation: json['operation']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class SyncPullResponseModel {
  const SyncPullResponseModel({
    required this.events,
    required this.nextCursor,
  });

  final List<SyncPullEventModel> events;
  final String? nextCursor;

  factory SyncPullResponseModel.fromJson(Map<String, dynamic> json) {
    final events =
        (json['events'] as List? ?? const [])
            .whereType<Map>()
            .map((raw) => SyncPullEventModel.fromJson(Map<String, dynamic>.from(raw)))
            .toList();
    final rawCursor = json['next_cursor']?.toString();
    return SyncPullResponseModel(
      events: events,
      nextCursor: (rawCursor == null || rawCursor.isEmpty) ? null : rawCursor,
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}

