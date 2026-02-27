import 'dart:convert';

import 'package:flutter/services.dart';

import 'environment_config.dart';

class EnvironmentLoader {
  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
  static const String _assetOverride = String.fromEnvironment(
    'APP_ENV_ASSET',
    defaultValue: '',
  );

  static Future<EnvironmentConfig> load() async {
    final assetPath =
        _assetOverride.trim().isNotEmpty
            ? _assetOverride.trim()
            : 'assets/env/${_envName.trim().toLowerCase()}.json';
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw StateError(
        'Invalid env config ($assetPath): root must be an object',
      );
    }
    return EnvironmentConfig.fromMap(decoded, sourceAssetPath: assetPath);
  }
}
