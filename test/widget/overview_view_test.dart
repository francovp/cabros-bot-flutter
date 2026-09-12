import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/data/models/admin_status.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/features/overview/overview_view.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

void main() {
  group('OverviewView Widget', () {
    testWidgets('renders hero section, refresh button, and empty state when no status', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final viewModel = AdminViewModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: AdminTheme.darkTheme,
          home: Scaffold(
            body: OverviewView(viewModel: viewModel),
          ),
        ),
      );

      expect(find.text('LIVE CONTROL PLANE'), findsOneWidget);
      expect(find.text('Operational overview'), findsOneWidget);
      expect(find.text('Refresh dashboard'), findsOneWidget);
    });

    testWidgets('renders metric cards and status grids when status is available', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final viewModel = AdminViewModel();
      final statusJson = {
        'service': {
          'name': 'cabros-bot',
          'version': '2.0.0',
          'environment': 'production',
          'commit': 'c0ffee99',
        },
        'featureFlags': {
          'telegramBot': true,
          'marketScanner': true,
        },
        'deliveryChannels': {
          'telegram': {'status': 'ready', 'provider': 'telegraf'},
        },
        'dependencies': {
          'firestore': {'status': 'ready'},
        },
      };

      // Set status directly on ViewModel through reflection or by updating status property
      // Since ViewModel._status is private, we can subclass or test with a fixture
      final adminStatus = AdminStatus.fromJson(statusJson);
      viewModel.setStatusForTesting(adminStatus);

      await tester.pumpWidget(
        MaterialApp(
          theme: AdminTheme.darkTheme,
          home: Scaffold(
            body: OverviewView(viewModel: viewModel),
          ),
        ),
      );

      // Verify hero rendered
      expect(find.text('Operational overview'), findsOneWidget);
      // Verify metrics
      expect(find.text('cabros-bot'), findsOneWidget);
      expect(find.text('Version 2.0.0'), findsOneWidget);
      expect(find.text('production'), findsOneWidget);
      // Verify sections
      expect(find.text('Delivery channels'), findsOneWidget);
      expect(find.text('Dependency health'), findsOneWidget);
      expect(find.text('Enabled capabilities'), findsOneWidget);
      expect(find.text('telegram'), findsOneWidget);
      expect(find.text('firestore'), findsOneWidget);
    });
  });
}
