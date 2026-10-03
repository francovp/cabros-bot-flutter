import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/adaptive_form_builder.dart';

void main() {
  Widget buildTestableWidget(Widget child, {TargetPlatform platform = TargetPlatform.macOS}) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        platform: platform,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('AdaptiveFormBuilder Widget', () {
    testWidgets('renders primitive string, number, and boolean fields', (tester) async {
      dynamic emittedValue;
      final schema = {
        'type': 'object',
        'properties': {
          'symbol': {'type': 'string', 'default': 'BTCUSDT'},
          'quantity': {'type': 'number', 'default': 1.5},
          'dryRun': {'type': 'boolean', 'default': false},
        },
        'required': ['symbol', 'quantity'],
      };

      await tester.pumpWidget(
        buildTestableWidget(
          AdaptiveFormBuilder(
            schema: schema,
            onChanged: (val) => emittedValue = val,
          ),
        ),
      );

      expect(find.text('Symbol *'), findsOneWidget);
      expect(find.text('Quantity *'), findsOneWidget);
      expect(find.text('Dry Run'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Toggle boolean switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(emittedValue, isNotNull);
      expect(emittedValue['dryRun'], isTrue);
    });

    testWidgets('renders Cupertino controls when platform is iOS', (tester) async {
      final schema = {
        'type': 'object',
        'properties': {
          'enabled': {'type': 'boolean', 'default': true},
          'channel': {
            'type': 'string',
            'enum': ['telegram', 'whatsapp'],
          },
        },
      };

      await tester.pumpWidget(
        buildTestableWidget(
          AdaptiveFormBuilder(
            schema: schema,
            onChanged: (_) {},
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(find.byType(CupertinoButton), findsOneWidget);
    });

    testWidgets('supports dynamic list item addition and deletion', (tester) async {
      dynamic emittedValue;
      final schema = {
        'type': 'object',
        'properties': {
          'symbols': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
      };

      await tester.pumpWidget(
        buildTestableWidget(
          AdaptiveFormBuilder(
            schema: schema,
            initialValue: {
              'symbols': ['BTCUSDT'],
            },
            onChanged: (val) => emittedValue = val,
          ),
        ),
      );

      expect(find.text('Symbols (1 items)'), findsOneWidget);
      expect(find.text('Add item'), findsOneWidget);

      // Tap add item
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      expect(emittedValue, isNotNull);
      expect(emittedValue['symbols'].length, 2);

      // Tap delete on item 2
      final removeButtons = find.byIcon(Icons.close);
      expect(removeButtons, findsNWidgets(2));
      await tester.tap(removeButtons.last);
      await tester.pumpAndSettle();

      expect(emittedValue['symbols'].length, 1);
    });

    testWidgets('masks sensitive fields like tokens and passwords with eye toggle', (tester) async {
      final schema = {
        'type': 'object',
        'properties': {
          'apiKey': {'type': 'string', 'default': 'super-secret-key'},
        },
      };

      await tester.pumpWidget(
        buildTestableWidget(
          AdaptiveFormBuilder(
            schema: schema,
            onChanged: (_) {},
          ),
        ),
      );

      final eyeIcon = find.byIcon(Icons.visibility_off);
      expect(eyeIcon, findsOneWidget);

      // Tap to reveal
      await tester.tap(eyeIcon);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
