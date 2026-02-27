import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ui source stays key-based localized', () {
    final root = Directory.current;
    final targets = <Directory>[
      Directory('${root.path}/lib/features'),
      Directory('${root.path}/lib/shared'),
    ];

    final offenders = <String>[];
    final devanagari = RegExp(r'[\u0900-\u097F]');

    for (final dir in targets) {
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relPath = entity.path.replaceFirst('${root.path}/', '');
        final content = entity.readAsStringSync();

        if (content.contains('context.tr(')) {
          offenders.add('$relPath: uses context.tr(...)');
        }
        if (devanagari.hasMatch(content)) {
          offenders.add('$relPath: contains inline Devanagari literal');
        }
        if (content.contains("'NPR ") || content.contains('"NPR ')) {
          offenders.add('$relPath: contains hardcoded NPR literal');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Localization guard failed:\n${offenders.join('\n')}',
    );
  });
}

