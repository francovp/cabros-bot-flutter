import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('redactSecret removes raw and escaped secrets', () {
      const secret = 'my-super-secret-key-123';
      const text = 'curl -H "x-api-key: my-super-secret-key-123" https://api.com';
      expect(
        ApiClient.redactSecret(text, secret),
        'curl -H "x-api-key: [REDACTED]" https://api.com',
      );
    });

    test('redactSecret handles null or empty secret gracefully', () {
      expect(ApiClient.redactSecret('hello world', null), 'hello world');
      expect(ApiClient.redactSecret('hello world', ''), 'hello world');
    });

    test('getTimeoutForPath returns correct timeout budgets', () {
      expect(
        ApiClient.getTimeoutForPath('/api/webhook/volume-confirmation'),
        ApiClient.volumeConfirmationTimeoutMs,
      );
      expect(
        ApiClient.getTimeoutForPath('/api/webhook/symbol-analysis'),
        ApiClient.volumeConfirmationTimeoutMs,
      );
      expect(
        ApiClient.getTimeoutForPath('/api/webhook/expanded-analysis-alert'),
        ApiClient.longRunningTimeoutMs,
      );
      expect(
        ApiClient.getTimeoutForPath('/api/status'),
        ApiClient.apiRequestTimeoutMs,
      );
    });

    test('buildUri formats base URL and attaches query parameters correctly', () {
      final client = ApiClient(baseUrl: 'https://example.com/api///');
      final uri = client.buildUri('/alerts', {
        'limit': 50,
        'source': 'tradingview',
        'empty': '',
        'nullValue': null,
      });

      expect(uri.scheme, 'https');
      expect(uri.host, 'example.com');
      expect(uri.path, '/api/alerts');
      expect(uri.queryParameters['limit'], '50');
      expect(uri.queryParameters['source'], 'tradingview');
      expect(uri.queryParameters.containsKey('empty'), isFalse);
      expect(uri.queryParameters.containsKey('nullValue'), isFalse);
    });
  });
}
