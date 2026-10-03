import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/data/models/admin_status.dart';
import 'package:cabros_bot_flutter/data/models/alert_model.dart';
import 'package:cabros_bot_flutter/data/models/job_model.dart';
import 'package:cabros_bot_flutter/data/models/openapi_spec.dart';
import 'package:cabros_bot_flutter/data/models/outcome_model.dart';
import 'package:cabros_bot_flutter/data/models/preset_model.dart';

void main() {
  group('AdminStatus Model', () {
    test('parses status JSON correctly', () {
      final json = {
        'service': {
          'name': 'cabros-bot',
          'version': '1.2.3',
          'environment': 'production',
          'commit': 'a1b2c3d4e5',
        },
        'featureFlags': {
          'telegramBot': true,
          'whatsappAlerts': false,
        },
        'deliveryChannels': {
          'telegram': {'status': 'ready', 'provider': 'telegraf'},
        },
        'dependencies': {
          'tradingViewMcp': {'status': 'ready', 'provider': 'remote-mcp'},
          'firestore': {'status': 'disabled'},
        },
      };

      final status = AdminStatus.fromJson(json);
      expect(status.service.name, 'cabros-bot');
      expect(status.service.version, '1.2.3');
      expect(status.service.environment, 'production');
      expect(status.service.commit, 'a1b2c3d4e5');
      expect(status.featureFlags['telegramBot'], isTrue);
      expect(status.featureFlags['whatsappAlerts'], isFalse);
      expect(status.deliveryChannels['telegram']?.status, 'ready');
      expect(status.dependencies['tradingViewMcp']?.provider, 'remote-mcp');
      expect(status.dependencies['firestore']?.status, 'disabled');
    });
  });

  group('AlertModel', () {
    test('parses alert items and pagination', () {
      final json = {
        'alerts': [
          {
            'id': 'alert-123',
            'text': 'BTC broke 70k resistance',
            'source': 'tradingview',
            'enriched': true,
            'enrichmentData': {
              'sentiment': 'bullish',
              'setup_type': 'breakout',
              'target_level': 75000,
              'invalidation_level': 68000,
              'risk_reward_ratio': 2.5,
              'insights': ['Strong volume', 'RSI above 60'],
            },
            'deliveryResults': {
              'telegram': {'success': true, 'messageId': 'msg-1'},
              'discord': {'success': false, 'error': 'Rate limited'},
            },
          },
        ],
        'pagination': {
          'hasMore': true,
          'nextBefore': 'cursor-456',
        },
      };

      final res = AlertListResponse.fromJson(json);
      expect(res.alerts.length, 1);
      final alert = res.alerts.first;
      expect(alert.id, 'alert-123');
      expect(alert.sentiment, 'bullish');
      expect(alert.setupType, 'breakout');
      expect(alert.targetLevel, 75000);
      expect(alert.insights.length, 2);
      expect(alert.deliveryResults['telegram']?.success, isTrue);
      expect(alert.deliveryResults['discord']?.success, isFalse);
      expect(res.pagination.hasMore, isTrue);
      expect(res.pagination.nextBefore, 'cursor-456');
    });

    test('parses alert items when deliveryResults is a List (real backend format)', () {
      final json = {
        'alerts': [
          {
            'id': 'alert-array-1',
            'text': 'ETH test alert',
            'enriched': false,
            'deliveryResults': [
              {'channel': 'telegram', 'success': true, 'messageId': '999'},
              {'channel': 'whatsapp', 'success': false, 'errorCode': 'ERR_CONN'},
            ],
          },
        ],
      };

      final res = AlertListResponse.fromJson(json);
      expect(res.alerts.length, 1);
      final alert = res.alerts.first;
      expect(alert.id, 'alert-array-1');
      expect(alert.deliveryResults['telegram']?.success, isTrue);
      expect(alert.deliveryResults['telegram']?.messageId, '999');
      expect(alert.deliveryResults['whatsapp']?.success, isFalse);
      expect(alert.deliveryResults['whatsapp']?.error, 'ERR_CONN');
    });

    test('parses AlertListResponse when root JSON is a List of alerts', () {
      final jsonList = [
        {
          'id': 'alert-root-1',
          'text': 'SOL pump alert',
          'enriched': false,
          'deliveryResults': [
            {'channel': 'telegram', 'success': true},
          ],
        },
      ];

      final res = AlertListResponse.fromJson(jsonList);
      expect(res.alerts.length, 1);
      expect(res.alerts.first.id, 'alert-root-1');
      expect(res.alerts.first.deliveryResults['telegram']?.success, isTrue);
    });

    test('parses alert summary', () {
      final json = {
        'summary': {
          'totalAlerts': 120,
          'window': {'from': '2026-09-01T00:00:00Z', 'to': '2026-09-11T00:00:00Z'},
          'delivery': {
            'totalSuccess': 118,
            'totalFailure': 2,
            'byChannel': {
              'telegram': {'total': 120, 'success': 118, 'failure': 2},
            },
          },
          'enrichment': {
            'enrichedAlerts': 100,
            'plainAlerts': 20,
            'tokenUsage': {'totalTokens': 45000, 'totalCost': '\$0.09'},
            'riskMetadataCoverage': {'denominator': 100, 'fields': {}},
          },
        },
      };

      final summary = AlertSummaryData.fromJson(json);
      expect(summary.totalAlerts, 120);
      expect(summary.totalSuccess, 118);
      expect(summary.totalFailure, 2);
      expect(summary.enrichedAlerts, 100);
      expect(summary.totalTokens, 45000);
    });
  });

  group('OutcomeModel', () {
    test('parses outcome items and summary', () {
      final json = {
        'outcomes': [
          {
            'id': 'signal-001',
            'symbol': 'BTCUSDT',
            'exchange': 'BINANCE',
            'status': 'evaluated',
            'entryPrice': 68000,
            'targetPrice': 72000,
            'stopLossPrice': 66000,
            'windows': {
              '1h': {
                'status': 'hit_target',
                'targetHit': true,
                'stopHit': false,
                'returnPercent': 5.8,
                'mfePercent': 6.1,
                'maePercent': -0.4,
                'rMultiple': 2.0,
              },
            },
          },
        ],
        'pagination': {'hasMore': false},
      };

      final res = OutcomeListResponse.fromJson(json);
      expect(res.outcomes.length, 1);
      final outcome = res.outcomes.first;
      expect(outcome.id, 'signal-001');
      expect(outcome.symbol, 'BTCUSDT');
      expect(outcome.windows['1h']?.targetHit, isTrue);
      expect(outcome.windows['1h']?.returnPercent, 5.8);
      expect(outcome.windows['1h']?.rMultiple, 2.0);
    });
  });

  group('JobModel', () {
    test('parses job items and progress fractions', () {
      final json = {
        'jobId': 'job-999',
        'type': 'tradingview-analysis',
        'status': 'processing',
        'progress': {'current': 4, 'total': 10, 'status': 'analyzing'},
        'results': [
          {'symbol': 'BTCUSDT', 'status': 'success', 'price': '68500', 'rsi': '54.2'},
        ],
      };

      final job = JobItem.fromJson(json);
      expect(job.jobId, 'job-999');
      expect(job.status, 'processing');
      expect(job.isActive, isTrue);
      expect(job.progress.fraction, 0.4);
      expect(job.results.length, 1);
    });
  });

  group('ScannerPreset', () {
    test('parses preset fields correctly', () {
      final json = {
        'id': 'preset-1',
        'name': 'Gainers 4h',
        'description': 'Top 4h gainers',
        'symbols': ['BINANCE:BTCUSDT', 'BINANCE:ETHUSDT'],
        'scans': ['gainers'],
        'interval': '4h',
      };

      final preset = ScannerPreset.fromJson(json);
      expect(preset.id, 'preset-1');
      expect(preset.name, 'Gainers 4h');
      expect(preset.symbols.length, 2);
      expect(preset.scans.first, 'gainers');
      expect(preset.interval, '4h');
    });
  });

  group('OpenApiSpec', () {
    test('extracts operations and confirms from contract', () {
      final contract = {
        'paths': {
          '/api/status': {
            'get': {
              'summary': 'Get Service Status',
              'x-admin-role': 'admin.viewer',
            },
          },
          '/api/alerts/{alertId}/replay': {
            'post': {
              'summary': 'Replay Alert',
              'parameters': [
                {
                  'name': 'alertId',
                  'in': 'path',
                  'required': true,
                },
              ],
            },
          },
        },
      };

      final ops = ApiOperation.extractOperations(contract);
      expect(ops.length, 2);

      final statusOp = ops.firstWhere((o) => o.path == '/api/status');
      expect(statusOp.method, 'GET');
      expect(statusOp.label, 'Get Service Status');
      expect(statusOp.requiredRole, 'admin.viewer');

      final replayOp = ops.firstWhere((o) => o.path == '/api/alerts/{alertId}/replay');
      expect(replayOp.method, 'POST');
      expect(replayOp.confirm, 'Replay this alert?');
      expect(replayOp.pathVariableNames, ['alertId']);
    });
  });
}
