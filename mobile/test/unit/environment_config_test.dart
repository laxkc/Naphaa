import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/config/environment_config.dart';

void main() {
  test('parses valid environment map', () {
    final config = EnvironmentConfig.fromMap({
      'ENV': 'dev',
      'BASE_URL': 'http://127.0.0.1:8000/api/v1',
      'CONNECT_TIMEOUT_SECONDS': 9,
      'RECEIVE_TIMEOUT_SECONDS': 12,
    }, sourceAssetPath: 'assets/env/dev.json');

    expect(config.env, 'dev');
    expect(config.baseUrl, 'http://127.0.0.1:8000/api/v1');
    expect(config.connectTimeoutSeconds, 9);
    expect(config.receiveTimeoutSeconds, 12);
  });

  test('throws when base url is invalid', () {
    expect(
      () => EnvironmentConfig.fromMap({
        'ENV': 'dev',
        'BASE_URL': '/relative',
      }, sourceAssetPath: 'assets/env/dev.json'),
      throwsStateError,
    );
  });
}
