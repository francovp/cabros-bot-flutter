import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/response_block.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class AnalysisRunner {
  final String title;
  final String path;
  final String method;
  final Map<String, dynamic> defaultPayload;

  AnalysisRunner({
    required this.title,
    required this.path,
    required this.method,
    required this.defaultPayload,
  });
}

class AnalysisView extends StatefulWidget {
  final AdminViewModel viewModel;

  const AnalysisView({super.key, required this.viewModel});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final List<AnalysisRunner> _runners = [
    AnalysisRunner(
      title: 'Symbol Analysis',
      path: '/api/webhook/symbol-analysis',
      method: 'POST',
      defaultPayload: {
        'symbol': 'BINANCE:BTCUSDT',
        'timeframe': '1h',
      },
    ),
    AnalysisRunner(
      title: 'Expanded Analysis Alert',
      path: '/api/webhook/expanded-analysis-alert',
      method: 'POST',
      defaultPayload: {
        'symbol': 'BINANCE:BTCUSDT',
        'channels': ['telegram'],
      },
    ),
    AnalysisRunner(
      title: 'Market Scanner',
      path: '/api/webhook/market-scanner-alert',
      method: 'POST',
      defaultPayload: {
        'symbols': ['BINANCE:BTCUSDT', 'BINANCE:ETHUSDT'],
        'scans': ['gainers', 'breakouts'],
      },
    ),
    AnalysisRunner(
      title: 'Volume Confirmation',
      path: '/api/webhook/volume-confirmation',
      method: 'POST',
      defaultPayload: {
        'symbol': 'BINANCE:BTCUSDT',
        'timeframe': '1h',
      },
    ),
    AnalysisRunner(
      title: 'News Monitor',
      path: '/api/news-monitor',
      method: 'POST',
      defaultPayload: {
        'force': true,
      },
    ),
  ];

  late int _selectedRunnerIndex;
  late final TextEditingController _payloadController;
  ApiResponse? _response;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRunnerIndex = 0;
    _payloadController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(_runners[0].defaultPayload),
    );
  }

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  void _selectRunner(int index) {
    setState(() {
      _selectedRunnerIndex = index;
      _payloadController.text =
          const JsonEncoder.withIndent('  ').convert(_runners[index].defaultPayload);
      _response = null;
    });
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });

    dynamic parsedBody;
    try {
      if (_payloadController.text.trim().isNotEmpty) {
        parsedBody = jsonDecode(_payloadController.text);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = ApiResponse(
          statusCode: 400,
          body: 'Invalid JSON payload: $e',
          elapsedMs: 0,
          isOk: false,
          error: 'Invalid JSON payload: $e',
        );
      });
      return;
    }

    final runner = _runners[_selectedRunnerIndex];
    try {
      final res = await widget.viewModel.adminService.executeAnalysis(
        runner.path,
        parsedBody,
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRunner = _runners[_selectedRunnerIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANALYSIS RUNNERS',
                style: TextStyle(
                  color: AdminColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Market Analysis & Webhooks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_runners.length, (index) {
                final isSelected = index == _selectedRunnerIndex;
                final runner = _runners[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(runner.title),
                    selectedColor: AdminColors.accentStrong,
                    backgroundColor: AdminColors.panel,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AdminColors.muted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _selectRunner(index),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Request card
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
                    Text(currentRunner.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AdminColors.inputBg, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '${currentRunner.method} ${currentRunner.path}',
                        style: const TextStyle(fontFamily: 'monospace', color: AdminColors.accent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('REQUEST BODY (JSON)', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _payloadController,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(hintText: '{\n  ...\n}'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runAnalysis,
                  icon: _isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow, size: 16),
                  label: Text(_isLoading ? 'Executing…' : 'Execute ${currentRunner.title}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Response output
          if (_isLoading || _response != null) ...[
            const Text('Response', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ResponseBlock(response: _response, isLoading: _isLoading),
          ],
        ],
      ),
    );
  }
}
