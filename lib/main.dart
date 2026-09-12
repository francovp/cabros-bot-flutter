import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/features/shell/shell_view.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = AdminViewModel();
  await viewModel.initPreferences();
  runApp(CabrosBotAdminApp(viewModel: viewModel));
}

class CabrosBotAdminApp extends StatelessWidget {
  final AdminViewModel viewModel;

  const CabrosBotAdminApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabros Bot Console',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.darkTheme,
      home: SelectionArea(
        child: ShellView(viewModel: viewModel),
      ),
    );
  }
}
