class AppConfig {
  // Base API URL is loaded at runtime from assets/env/*.json
  // selected by --dart-define=APP_ENV=dev|prod.
  static const String defaultCurrency = 'NPR';
  static const String defaultLocale = 'ne';
  static const int syncPushChunkSize = int.fromEnvironment(
    'SYNC_PUSH_CHUNK_SIZE',
    defaultValue: 50,
  );
  static const int syncPullChunkSize = int.fromEnvironment(
    'SYNC_PULL_CHUNK_SIZE',
    defaultValue: 100,
  );

  // No login UI: app silently uses this device account for backend auth.
  static const String demoPhone = '9800000999';
  static const String demoPassword = 'demoPass123';
}
