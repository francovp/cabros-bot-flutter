import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/status_badge.dart';

void main() {
  group('StatusBadge Widget', () {
    testWidgets('renders status label in uppercase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(label: 'ready', tone: StatusTone.ready),
          ),
        ),
      );

      expect(find.text('READY'), findsOneWidget);
    });

    testWidgets('maps string status to tone correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge.fromStatus('ready'),
                StatusBadge.fromStatus('failed'),
                StatusBadge.fromStatus('disabled'),
                StatusBadge.fromStatus('processing'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('DISABLED'), findsOneWidget);
      expect(find.text('PROCESSING'), findsOneWidget);
    });
  });
}
