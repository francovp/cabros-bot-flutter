import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/features/shell/shell_view.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

void main() {
  group('ShellView Widget', () {
    testWidgets('renders sidebar with CB brand mark and workspace buttons on wide screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final viewModel = AdminViewModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: AdminTheme.darkTheme,
          home: ShellView(viewModel: viewModel),
        ),
      );

      expect(find.text('CB'), findsOneWidget);
      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(find.text('Cabros Bot'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Playground'), findsOneWidget);
    });

    testWidgets('switches views when sidebar item is clicked', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final viewModel = AdminViewModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: AdminTheme.darkTheme,
          home: ShellView(viewModel: viewModel),
        ),
      );

      expect(viewModel.currentTab, AdminTab.overview);

      // Tap on 'Status' button
      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();

      expect(viewModel.currentTab, AdminTab.status);
    });

    testWidgets('renders drawer menu button on compact screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final viewModel = AdminViewModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: AdminTheme.darkTheme,
          home: ShellView(viewModel: viewModel),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });
  });
}
