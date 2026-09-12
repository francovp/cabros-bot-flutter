import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/metric_card.dart';

void main() {
  group('MetricCard Widget', () {
    testWidgets('renders label, value, and meta note', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Dependencies',
              value: '12 ready',
              meta: '0 need attention',
            ),
          ),
        ),
      );

      expect(find.text('DEPENDENCIES'), findsOneWidget);
      expect(find.text('12 ready'), findsOneWidget);
      expect(find.text('0 need attention'), findsOneWidget);
    });
  });
}
