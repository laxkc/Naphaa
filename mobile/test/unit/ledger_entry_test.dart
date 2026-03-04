import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/features/reports/domain/ledger_entry.dart';

void main() {
  test('parses metadata_json when backend returns JSON string', () {
    final entry = LedgerEntryItem.fromJson({
      'id': 'l1',
      'entity_type': 'sale_refund',
      'entity_id': 'refund-1',
      'entry_type': 'refund',
      'direction': 'OUT',
      'amount': 120,
      'created_at': '2026-03-04T10:00:00Z',
      'sale_id': 'sale-1',
      'metadata_json':
          '{"original_sale_id":"sale-1","reason":"Damaged item","refund_id":"refund-1"}',
    });

    expect(entry.metadata, isNotNull);
    expect(entry.metadata!['original_sale_id'], 'sale-1');
    expect(entry.metadata!['reason'], 'Damaged item');
    expect(entry.metadata!['refund_id'], 'refund-1');
  });
}
