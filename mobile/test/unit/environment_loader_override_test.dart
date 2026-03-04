import 'package:flutter_test/flutter_test.dart';
import 'package:sme_digital/core/config/environment_config.dart';

void main() {
  test('copyWith can override base url for runtime env selection', () {
    const original = EnvironmentConfig(
      env: 'dev',
      baseUrl: 'https://example.com/api/v1',
      connectTimeoutSeconds: 10,
      receiveTimeoutSeconds: 15,
      sourceAssetPath: 'assets/env/dev.json',
    );

    final updated = original.copyWith(
      baseUrl: 'http://127.0.0.1:8000/api/v1',
    );

    expect(updated.baseUrl, 'http://127.0.0.1:8000/api/v1');
    expect(updated.env, 'dev');
    expect(updated.sourceAssetPath, 'assets/env/dev.json');
  });
}
