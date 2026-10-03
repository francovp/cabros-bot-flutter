import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/structured_response_viewer.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Size size = const Size(800, 600)}) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          child: child,
        ),
      ),
    );
  }

  group('StructuredResponseViewer Widget', () {
    testWidgets('renders tabular data table for array of objects on wide screens', (tester) async {
      final response = ApiResponse(
        statusCode: 200,
        elapsedMs: 35,
        isOk: true,
        body: '''
        [
          {"symbol": "BTCUSDT", "price": 65000, "active": true},
          {"symbol": "ETHUSDT", "price": 3500, "active": false}
        ]
        ''',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          StructuredResponseViewer(response: response),
          size: const Size(900, 600),
        ),
      );

      expect(find.text('HTTP 200'), findsOneWidget);
      expect(find.text('35 ms'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('BTCUSDT'), findsOneWidget);
      expect(find.text('ETHUSDT'), findsOneWidget);
    });

    testWidgets('renders list of cards for array of objects on narrow mobile screens', (tester) async {
      final response = ApiResponse(
        statusCode: 200,
        elapsedMs: 20,
        isOk: true,
        body: '''
        [
          {"symbol": "BTCUSDT", "active": true}
        ]
        ''',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          StructuredResponseViewer(response: response),
          size: const Size(380, 700),
        ),
      );

      expect(find.text('Item #1'), findsOneWidget);
      expect(find.text('BTCUSDT'), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('redacts sensitive keys from response display', (tester) async {
      final response = ApiResponse(
        statusCode: 200,
        elapsedMs: 12,
        isOk: true,
        body: '''
        {
          "status": "ready",
          "apiKey": "very-secret-token-12345"
        }
        ''',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          StructuredResponseViewer(response: response),
        ),
      );

      expect(find.text('[REDACTED]'), findsOneWidget);
      expect(find.text('very-secret-token-12345'), findsNothing);
    });

    testWidgets('switches between visual and raw JSON modes', (tester) async {
      final response = ApiResponse(
        statusCode: 200,
        elapsedMs: 15,
        isOk: true,
        body: '{"message": "Hello World"}',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          StructuredResponseViewer(response: response),
        ),
      );

      expect(find.text('Visual'), findsOneWidget);
      expect(find.text('Raw JSON'), findsOneWidget);

      // Tap Raw JSON
      await tester.tap(find.text('Raw JSON'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('{"message": "Hello World"}'), findsOneWidget);
    });
  });
}
