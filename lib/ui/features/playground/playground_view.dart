import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/data/models/openapi_spec.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/confirm_dialog.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/response_block.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class PlaygroundView extends StatefulWidget {
  final AdminViewModel viewModel;

  const PlaygroundView({super.key, required this.viewModel});

  @override
  State<PlaygroundView> createState() => _PlaygroundViewState();
}

class _PlaygroundViewState extends State<PlaygroundView> {
  List<ApiOperation> _operations = [];
  bool _isLoadingContract = false;
  String? _contractError;

  ApiOperation? _selectedOperation;
  final Map<String, TextEditingController> _pathControllers = {};
  final _queryController = TextEditingController();
  final _bodyController = TextEditingController();

  ApiResponse? _response;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  @override
  void dispose() {
    for (final c in _pathControllers.values) {
      c.dispose();
    }
    _queryController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadContract() async {
    setState(() {
      _isLoadingContract = true;
      _contractError = null;
    });

    try {
      final ops = await widget.viewModel.adminService.getOperations();
      setState(() {
        _operations = ops;
        if (ops.isNotEmpty) {
          _selectOperation(ops.first);
        }
      });
    } catch (e) {
      setState(() {
        _contractError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingContract = false;
      });
    }
  }

  void _selectOperation(ApiOperation op) {
    setState(() {
      _selectedOperation = op;
      _response = null;

      // Clear & init path controllers
      for (final c in _pathControllers.values) {
        c.dispose();
      }
      _pathControllers.clear();
      for (final p in op.pathVariableNames) {
        _pathControllers[p] = TextEditingController();
      }

      // Query example
      final queryExample = <String, dynamic>{};
      for (final q in op.queryParameters) {
        if (q.example != null) {
          queryExample[q.name] = q.example;
        }
      }
      _queryController.text = queryExample.isNotEmpty
          ? const JsonEncoder.withIndent('  ').convert(queryExample)
          : '';

      // Body example
      if (op.requestBodyExample != null) {
        _bodyController.text =
            const JsonEncoder.withIndent('  ').convert(op.requestBodyExample);
      } else {
        _bodyController.text = '';
      }
    });
  }

  Future<void> _executeRequest() async {
    final op = _selectedOperation;
    if (op == null) return;

    if (op.confirm != null) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Confirm Operation',
        message: op.confirm!,
        isDestructive: op.method == 'DELETE' || op.confirm!.contains('Delete'),
      );
      if (!confirmed) return;
      if (!mounted) return;
    }

    // Resolve path variables
    var resolvedPath = op.path;
    for (final entry in _pathControllers.entries) {
      final val = entry.value.text.trim();
      if (val.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Path variable {${entry.key}} is required'),
            backgroundColor: AdminColors.danger,
          ),
        );
        return;
      }
      resolvedPath = resolvedPath.replaceAll('{${entry.key}}', Uri.encodeComponent(val));
    }

    // Resolve query JSON
    Map<String, dynamic>? query;
    if (_queryController.text.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(_queryController.text);
        if (parsed is Map<String, dynamic>) {
          query = parsed;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Query must be valid JSON: $e'),
            backgroundColor: AdminColors.danger,
          ),
        );
        return;
      }
    }

    // Resolve body JSON
    dynamic body;
    if (_bodyController.text.trim().isNotEmpty) {
      try {
        body = jsonDecode(_bodyController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Body must be valid JSON: $e'),
            backgroundColor: AdminColors.danger,
          ),
        );
        return;
      }
    }

    setState(() {
      _isExecuting = true;
      _response = null;
    });

    try {
      final res = await widget.viewModel.adminService.executeRaw(
        method: op.method,
        path: resolvedPath,
        query: query,
        body: body,
      );
      setState(() {
        _response = res;
      });
    } catch (e) {
      setState(() {
        _response = ApiResponse(
          statusCode: 500,
          body: e.toString(),
          elapsedMs: 0,
          isOk: false,
          error: e.toString(),
        );
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContract) {
      return const Center(child: CircularProgressIndicator(color: AdminColors.accent));
    }

    if (_contractError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load contract: $_contractError', style: const TextStyle(color: AdminColors.danger)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadContract, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final op = _selectedOperation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPENAPI 3.1 EXPLORER',
                style: TextStyle(
                  color: AdminColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Interactive API Playground',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operation Selector Dropdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SELECT API ENDPOINT', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<ApiOperation>(
                  initialValue: _selectedOperation,
                  isExpanded: true,
                  dropdownColor: AdminColors.panelStrong,
                  decoration: const InputDecoration(labelText: 'Operation'),
                  items: _operations.map((item) {
                    return DropdownMenuItem<ApiOperation>(
                      value: item,
                      child: Text(
                        '${item.method} ${item.path} — ${item.label}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _selectOperation(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (op != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(op.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AdminColors.inputBg, borderRadius: BorderRadius.circular(4)),
                        child: Text('${op.method} ${op.path}', style: const TextStyle(fontFamily: 'monospace', color: AdminColors.accent, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Path Variables
                  if (op.pathVariableNames.isNotEmpty) ...[
                    const Text('PATH PARAMETERS', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...op.pathVariableNames.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _pathControllers[name],
                          decoration: InputDecoration(
                            labelText: name,
                            hintText: 'Required value for {$name}',
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Query JSON
                  const Text('QUERY PARAMETERS (JSON)', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _queryController,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(hintText: '{\n  "key": "value"\n}'),
                  ),
                  const SizedBox(height: 16),

                  // Request Body JSON
                  if (op.method != 'GET') ...[
                    const Text('REQUEST BODY (JSON)', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyController,
                      maxLines: 7,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      decoration: const InputDecoration(hintText: '{\n  ...\n}'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    onPressed: _isExecuting ? null : _executeRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: op.confirm != null ? AdminColors.danger : AdminColors.accentStrong,
                    ),
                    icon: _isExecuting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 16),
                    label: Text(_isExecuting ? 'Sending…' : 'Send ${op.method} Request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isExecuting || _response != null) ...[
              const Text('Response', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ResponseBlock(response: _response, isLoading: _isExecuting),
            ],
          ],
        ],
      ),
    );
  }
}
