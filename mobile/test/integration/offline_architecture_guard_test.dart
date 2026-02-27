import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature data layer does not call backend gateway directly', () async {
    final root = Directory('lib/features');
    expect(await root.exists(), isTrue);

    final blockedMatches = <String>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!path.endsWith('_repository.dart')) continue;
      if (!path.contains('/data/')) continue;

      final content = await entity.readAsString();
      if (content.contains('BackendGateway') ||
          content.contains('ApiClient(') ||
          content.contains('Dio(') ||
          content.contains("'/sync/") ||
          content.contains('"\\/sync/')) {
        blockedMatches.add(path);
      }
    }

    expect(
      blockedMatches,
      isEmpty,
      reason:
          'Feature repositories must stay local-first and enqueue to sync_queue; '
          'network writes belong only to core sync/session gateway.',
    );
  });
}
