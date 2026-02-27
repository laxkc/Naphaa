class EnvironmentConfig {
  const EnvironmentConfig({
    required this.env,
    required this.baseUrl,
    required this.connectTimeoutSeconds,
    required this.receiveTimeoutSeconds,
    required this.sourceAssetPath,
  });

  final String env;
  final String baseUrl;
  final int connectTimeoutSeconds;
  final int receiveTimeoutSeconds;
  final String sourceAssetPath;

  static EnvironmentConfig fromMap(
    Map<String, dynamic> json, {
    required String sourceAssetPath,
  }) {
    final env = (json['ENV'] ?? json['env'] ?? '').toString().trim();
    final baseUrl =
        (json['BASE_URL'] ?? json['base_url'] ?? '').toString().trim();
    if (env.isEmpty) {
      throw StateError(
        'Invalid env config ($sourceAssetPath): ENV is required',
      );
    }
    if (baseUrl.isEmpty) {
      throw StateError(
        'Invalid env config ($sourceAssetPath): BASE_URL is required',
      );
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw StateError(
        'Invalid env config ($sourceAssetPath): BASE_URL must be a valid absolute URL',
      );
    }
    final connectTimeoutSeconds =
        (json['CONNECT_TIMEOUT_SECONDS'] as num?)?.toInt() ?? 10;
    final receiveTimeoutSeconds =
        (json['RECEIVE_TIMEOUT_SECONDS'] as num?)?.toInt() ?? 15;

    return EnvironmentConfig(
      env: env,
      baseUrl: baseUrl,
      connectTimeoutSeconds: connectTimeoutSeconds,
      receiveTimeoutSeconds: receiveTimeoutSeconds,
      sourceAssetPath: sourceAssetPath,
    );
  }
}
