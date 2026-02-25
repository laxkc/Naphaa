import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/storage/local_db.dart';

class AlertsRepository {
  AlertsRepository(this._db);

  final LocalDatabase _db;

  Future<void> replaceOpenAlerts(List<Map<String, dynamic>> alerts) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('alerts');
      for (final raw in alerts) {
        final id = raw['id']?.toString();
        if (id == null || id.isEmpty) continue;
        await txn.insert('alerts', {
          'id': id,
          'type': (raw['type'] ?? 'generic').toString(),
          'entity_type': (raw['entity_type'] ?? 'business').toString(),
          'entity_id': raw['entity_id']?.toString(),
          'severity': (raw['severity'] ?? 'info').toString(),
          'title': (raw['title'] ?? 'Alert').toString(),
          'body': (raw['body'] ?? '').toString(),
          'action_type': raw['action_type']?.toString(),
          'action_payload_json':
              raw['action_payload'] == null
                  ? null
                  : jsonEncode(raw['action_payload']),
          'created_at':
              (raw['created_at'] ?? DateTime.now().toIso8601String())
                  .toString(),
          'resolved_at': raw['resolved_at']?.toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
