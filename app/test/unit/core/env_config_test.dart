import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/env_config.dart';

void main() {
  tearDown(() => EnvConfig.initCustomApiUrl(null));

  group('EnvConfig.healthCheckUri', () {
    test(
      'Given an API url with a prefix and port, When building the health uri, Then it points at /health on the same host',
      () {
        EnvConfig.initCustomApiUrl('http://10.0.2.2:8080/api/v1');

        expect(EnvConfig.healthCheckUri.toString(), 'http://10.0.2.2:8080/health');
      },
    );

    test('Given an https API url, When building the health uri, Then the scheme and host are kept', () {
      EnvConfig.initCustomApiUrl('https://api.example.com/api/v1');

      expect(EnvConfig.healthCheckUri.toString(), 'https://api.example.com/health');
    });

    test('Given an API url with a query string, When building the health uri, Then the query is dropped', () {
      EnvConfig.initCustomApiUrl('https://api.example.com/api/v1?x=1');

      expect(EnvConfig.healthCheckUri.toString(), 'https://api.example.com/health');
    });
  });
}
