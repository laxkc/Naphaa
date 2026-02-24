class AppConfig {
  // Default: 10.0.2.2 works for Android emulator (host machine alias).
  // For a physical device, pass your LAN IP at build/run time:
  //   flutter run --dart-define=API_HOST=192.168.x.x
  // No code changes needed — just change the run command.
  static const String _apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );
  static const String apiBaseUrl = 'http://$_apiHost:8000/api/v1';
  static const String defaultCurrency = 'NPR';
  static const String defaultLocale = 'ne';

  // No login UI: app silently uses this device account for backend auth.
  static const String demoPhone = '9800000999';
  static const String demoPassword = 'demoPass123';
}
