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
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _hostOverride = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );
  static const String _portOverride = String.fromEnvironment(
    'API_PORT',
    defaultValue: '8000',
  );
  static const String _schemeOverride = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: 'http',
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
    final config = EnvironmentConfig.fromMap(
      decoded,
      sourceAssetPath: assetPath,
    );
    final overrideBaseUrl = _resolveBaseUrlOverride();
    if (overrideBaseUrl == null) return config;
    return config.copyWith(baseUrl: overrideBaseUrl);
  }

  static String? _resolveBaseUrlOverride() {
    final baseUrl = _baseUrlOverride.trim();
    if (baseUrl.isNotEmpty) {
      return baseUrl;
    }

    final host = _hostOverride.trim();
    if (host.isEmpty) {
      return null;
    }

    final scheme = _schemeOverride.trim().isEmpty ? 'http' : _schemeOverride.trim();
    final port = _portOverride.trim().isEmpty ? '8000' : _portOverride.trim();
    return '$scheme://$host:$port/api/v1';
  }
}
