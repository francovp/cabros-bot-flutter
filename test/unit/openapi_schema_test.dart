import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/data/models/openapi_spec.dart';

void main() {
  group('OpenApiSpec schema normalization', () {
    test('resolves \$ref recursively', () {
      final contract = {
        'components': {
          'schemas': {
            'AlertChannel': {
              'type': 'string',
              'enum': ['telegram', 'whatsapp', 'discord'],
            },
            'AlertPayload': {
              'type': 'object',
              'properties': {
                'message': {'type': 'string'},
                'channel': {r'$ref': '#/components/schemas/AlertChannel'},
              },
              'required': ['message'],
            },
          },
        },
      };

      final resolved = OpenApiSpec.schemaFor(contract, {
        r'$ref': '#/components/schemas/AlertPayload',
      });

      expect(resolved['type'], 'object');
      final props = resolved['properties'] as Map<String, dynamic>;
      expect(props['message']?['type'], 'string');
      expect(props['channel']?['type'], 'string');
      expect(props['channel']?['enum'], ['telegram', 'whatsapp', 'discord']);
      expect(resolved['required'], ['message']);
    });

    test('flattens oneOf variants and extracts discriminator consts', () {
      final contract = <String, dynamic>{};
      final schema = {
        'type': 'object',
        'oneOf': [
          {
            'properties': {
              'type': {'const': 'standard'},
              'symbol': {'type': 'string'},
            },
            'required': ['type', 'symbol'],
          },
          {
            'properties': {
              'type': {'const': 'advanced'},
              'timeframe': {'type': 'string'},
            },
            'required': ['type', 'timeframe'],
          },
        ],
      };

      final normalized = OpenApiSpec.schemaFor(contract, schema);
      expect(normalized['variants'], isNotNull);
      final variants = normalized['variants'] as List;
      expect(variants.length, 2);

      final props = normalized['properties'] as Map<String, dynamic>;
      expect(props['type']?['enum'], containsAll(['standard', 'advanced']));
    });

    test('fieldSchema activates matching variant based on discriminator', () {
      final schema = {
        'type': 'object',
        'variants': [
          {
            'properties': {
              'mode': {'const': 'crypto'},
              'exchange': {'type': 'string', 'default': 'BINANCE'},
            },
          },
          {
            'properties': {
              'mode': {'const': 'equity'},
              'ticker': {'type': 'string', 'default': 'AAPL'},
            },
          },
        ],
      };

      final cryptoActive = OpenApiSpec.fieldSchema(schema, {'mode': 'crypto'});
      expect(cryptoActive['properties']['exchange'], isNotNull);

      final equityActive = OpenApiSpec.fieldSchema(schema, {'mode': 'equity'});
      expect(equityActive['properties']['ticker'], isNotNull);
    });

    test('initialValue returns typed defaults', () {
      expect(OpenApiSpec.initialValue({'type': 'string'}), '');
      expect(OpenApiSpec.initialValue({'type': 'integer'}), 0);
      expect(OpenApiSpec.initialValue({'type': 'number'}), 0.0);
      expect(OpenApiSpec.initialValue({'type': 'boolean'}), false);
      expect(OpenApiSpec.initialValue({'type': 'array'}), []);
      expect(
        OpenApiSpec.initialValue({
          'type': 'object',
          'properties': {
            'req': {'type': 'string'},
          },
          'required': ['req'],
        }),
        {'req': ''},
      );
    });
  });
}
