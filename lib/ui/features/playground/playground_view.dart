import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/data/models/openapi_spec.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/adaptive_form_builder.dart';
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

  Map<String, dynamic> _queryMap = {};
  dynamic _bodyValue;

  bool _isVisualMode = true;
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

  Map<String, dynamic> _buildQuerySchema(List<ApiParameter> queryParams) {
    final properties = <String, dynamic>{};
    final requiredList = <String>[];
    for (final p in queryParams) {
      properties[p.name] = p.schema ?? {
        'type': p.type ?? 'string',
        if (p.enumValues != null) 'enum': p.enumValues,
        if (p.description != null) 'description': p.description,
        if (p.example != null) 'default': p.example,
      };
      if (p.required) requiredList.add(p.name);
    }
    return {
      'type': 'object',
      'properties': properties,
      'required': requiredList,
      'additionalProperties': false,
    };
  }

  Map<String, dynamic> _buildBodySchema(ApiOperation op) {
    if (op.requestBodySchema != null && op.requestBodySchema!.isNotEmpty) {
      return op.requestBodySchema!;
    }
    if (op.requestBodyExample is Map) {
      final map = (op.requestBodyExample as Map).cast<String, dynamic>();
      final props = <String, dynamic>{};
      for (final entry in map.entries) {
        final val = entry.value;
        props[entry.key] = {
          'type': val is bool
              ? 'boolean'
              : (val is num
                  ? 'number'
                  : (val is List ? 'array' : (val is Map ? 'object' : 'string'))),
          'default': val,
        };
      }
      return {
        'type': 'object',
        'properties': props,
        'additionalProperties': true,
      };
    }
    return {
      'type': 'object',
      'properties': <String, dynamic>{},
      'additionalProperties': true,
    };
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

      // Query initial state
      final queryExample = <String, dynamic>{};
      for (final q in op.queryParameters) {
        if (q.example != null) {
          queryExample[q.name] = q.example;
        }
      }
      _queryMap = queryExample;
      _queryController.text = queryExample.isNotEmpty
          ? const JsonEncoder.withIndent('  ').convert(queryExample)
          : '';

      // Body initial state
      if (op.requestBodyExample != null) {
        _bodyValue = op.requestBodyExample;
        _bodyController.text =
            const JsonEncoder.withIndent('  ').convert(op.requestBodyExample);
      } else if (op.requestBodySchema != null) {
        _bodyValue = OpenApiSpec.initialValue(op.requestBodySchema!);
        _bodyController.text = _bodyValue != null
            ? const JsonEncoder.withIndent('  ').convert(_bodyValue)
            : '';
      } else {
        _bodyValue = null;
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
      resolvedPath =
          resolvedPath.replaceAll('{${entry.key}}', Uri.encodeComponent(val));
    }

    // Resolve query parameters
    Map<String, dynamic>? query;
    if (_isVisualMode) {
      query = _queryMap.isNotEmpty ? _queryMap : null;
    } else if (_queryController.text.trim().isNotEmpty) {
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

    // Resolve body parameters
    dynamic body;
    if (_isVisualMode) {
      body = _bodyValue;
    } else if (_bodyController.text.trim().isNotEmpty) {
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
              Text('Failed to load contract: $_contractError',
                  style: const TextStyle(color: AdminColors.danger)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadContract, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final op = _selectedOperation;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

              // Visual Form vs Raw JSON Mode Toggle
              if (isIOS)
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _isVisualMode,
                  children: const {
                    true: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Visual Form', style: TextStyle(fontSize: 12)),
                    ),
                    false: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Raw JSON', style: TextStyle(fontSize: 12)),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _isVisualMode = val;
                      });
                    }
                  },
                )
              else
                SegmentedButton<bool>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Visual Form'),
                      icon: Icon(Icons.tune, size: 14),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Raw JSON'),
                      icon: Icon(Icons.code, size: 14),
                    ),
                  ],
                  selected: {_isVisualMode},
                  onSelectionChanged: (set) {
                    setState(() {
                      _isVisualMode = set.first;
                    });
                  },
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
                const Text('SELECT API ENDPOINT',
                    style: TextStyle(
                        color: AdminColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
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
                      Expanded(
                        child: Text(
                          op.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AdminColors.inputBg,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('${op.method} ${op.path}',
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                color: AdminColors.accent,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  if (op.description != null) ...[
                    const SizedBox(height: 6),
                    Text(op.description!,
                        style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),

                  // Path Variables
                  if (op.pathVariableNames.isNotEmpty) ...[
                    const Text('PATH PARAMETERS',
                        style: TextStyle(
                            color: AdminColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
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

                  // Query Parameters (Visual vs JSON)
                  if (op.queryParameters.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isVisualMode ? 'QUERY PARAMETERS' : 'QUERY PARAMETERS (JSON)',
                          style: const TextStyle(
                              color: AdminColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        if (_isVisualMode)
                          const Text(
                            'Schema-driven',
                            style: TextStyle(color: AdminColors.accent, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isVisualMode)
                      AdaptiveFormBuilder(
                        key: ValueKey('query-${op.method}-${op.path}'),
                        title: 'Query Options',
                        schema: _buildQuerySchema(op.queryParameters),
                        initialValue: _queryMap,
                        onChanged: (val) {
                          if (val is Map) {
                            _queryMap = val.cast<String, dynamic>();
                            _queryController.text =
                                const JsonEncoder.withIndent('  ').convert(_queryMap);
                          }
                        },
                      )
                    else
                      TextField(
                        controller: _queryController,
                        maxLines: 4,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        decoration:
                            const InputDecoration(hintText: '{\n  "key": "value"\n}'),
                        onChanged: (str) {
                          try {
                            final parsed = jsonDecode(str);
                            if (parsed is Map) {
                              _queryMap = parsed.cast<String, dynamic>();
                            }
                          } catch (_) {}
                        },
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Request Body (Visual vs JSON)
                  if (op.method != 'GET') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isVisualMode ? 'REQUEST BODY' : 'REQUEST BODY (JSON)',
                          style: const TextStyle(
                              color: AdminColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        if (_isVisualMode)
                          const Text(
                            'Adaptive controls',
                            style: TextStyle(color: AdminColors.accent, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isVisualMode)
                      AdaptiveFormBuilder(
                        key: ValueKey('body-${op.method}-${op.path}'),
                        title: 'Payload Configuration',
                        schema: _buildBodySchema(op),
                        initialValue: _bodyValue,
                        onChanged: (val) {
                          _bodyValue = val;
                          if (val != null) {
                            _bodyController.text =
                                const JsonEncoder.withIndent('  ').convert(val);
                          }
                        },
                      )
                    else
                      TextField(
                        controller: _bodyController,
                        maxLines: 7,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        decoration: const InputDecoration(hintText: '{\n  ...\n}'),
                        onChanged: (str) {
                          try {
                            _bodyValue = jsonDecode(str);
                          } catch (_) {}
                        },
                      ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    onPressed: _isExecuting ? null : _executeRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: op.confirm != null
                          ? AdminColors.danger
                          : AdminColors.accentStrong,
                    ),
                    icon: _isExecuting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 16),
                    label: Text(
                        _isExecuting ? 'Sending…' : 'Send ${op.method} Request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isExecuting || _response != null) ...[
              const Text('Response Inspector',
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ResponseBlock(response: _response, isLoading: _isExecuting),
            ],
          ],
        ],
      ),
    );
  }
}
