import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cabros_bot_flutter/ui/features/shell/shell_view.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

void main() {
  testWidgets('app tree contains SelectionArea enabling mouse/touch text selection', (tester) async {
    final viewModel = AdminViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: ShellView(viewModel: viewModel),
      ),
    );

    expect(find.byType(SelectionArea), findsAtLeastNWidgets(1));
  });
}
