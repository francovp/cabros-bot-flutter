import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class AuthModal extends StatefulWidget {
  final AdminViewModel viewModel;

  const AuthModal({super.key, required this.viewModel});

  static Future<void> show(BuildContext context, AdminViewModel viewModel) {
    return showDialog(
      context: context,
      builder: (ctx) => AuthModal(viewModel: viewModel),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  late final TextEditingController _tokenController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.viewModel.apiClient.baseUrl);
    _keyController = TextEditingController(text: widget.viewModel.apiClient.apiKey ?? '');
    _tokenController = TextEditingController(text: widget.viewModel.apiClient.authToken ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _save() {
    widget.viewModel.updateCredentials(
      newBaseUrl: _urlController.text,
      newApiKey: _keyController.text,
      newAuthToken: _tokenController.text.isNotEmpty ? _tokenController.text : null,
    );
    Navigator.of(context).pop();
  }

  void _clearKey() {
    widget.viewModel.clearApiKey();
    _keyController.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.panelStrong,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AdminColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUTHENTICATION',
                        style: TextStyle(
                          color: AdminColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Connection Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AdminColors.muted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Backend API Origin',
                  hintText: 'https://openclaw.tail5e4271.ts.net',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                decoration: InputDecoration(
                  labelText: 'Session API Key (x-api-key)',
                  hintText: 'Enter operator API key',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility : Icons.visibility_off,
                      color: AdminColors.muted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Firebase Auth Bearer Token (Optional)',
                  hintText: 'ID token for role-gated admin access',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearKey,
                    child: const Text('Clear Key', style: TextStyle(color: AdminColors.danger)),
                  ),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save & Reconnect'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
