import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabros_bot_flutter/data/models/job_model.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/confirm_dialog.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/progress_meter.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/response_block.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/status_badge.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class JobsView extends StatefulWidget {
  final AdminViewModel viewModel;

  const JobsView({super.key, required this.viewModel});

  @override
  State<JobsView> createState() => _JobsViewState();
}

class _JobsViewState extends State<JobsView> {
  List<JobItem> _jobs = [];
  bool _isLoadingJobs = false;
  String? _jobsError;

  // Selected Job / Status Inspection
  final _selectedJobIdController = TextEditingController();
  JobItem? _selectedJob;
  bool _isLoadingSelected = false;
  String? _selectedError;

  // Create Job Form
  final _createSymbolsController = TextEditingController(text: 'BINANCE:BTCUSDT, BINANCE:ETHUSDT');
  final _createTimeframeController = TextEditingController(text: '1h');

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    widget.viewModel.stopJobPolling();
    _selectedJobIdController.dispose();
    _createSymbolsController.dispose();
    _createTimeframeController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoadingJobs = true;
      _jobsError = null;
    });

    try {
      final list = await widget.viewModel.adminService.getJobs();
      setState(() {
        _jobs = list;
      });
    } catch (e) {
      setState(() {
        _jobsError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingJobs = false;
      });
    }
  }

  Future<void> _fetchJobStatus(String jobId, {bool auto = false}) async {
    if (jobId.trim().isEmpty) return;

    if (!auto) {
      setState(() {
        _isLoadingSelected = true;
        _selectedError = null;
      });
    }

    try {
      final item = await widget.viewModel.adminService.getJobStatus(jobId.trim());
      setState(() {
        _selectedJob = item;
      });

      if (item.isActive) {
        widget.viewModel.startJobPolling(item.jobId, () {
          _fetchJobStatus(item.jobId, auto: true);
        });
      } else {
        widget.viewModel.stopJobPolling();
      }
    } catch (e) {
      if (!auto) {
        setState(() {
          _selectedError = e.toString();
        });
      }
    } finally {
      if (!auto) {
        setState(() {
          _isLoadingSelected = false;
        });
      }
    }
  }

  Future<void> _createJob() async {
    final symbols = _createSymbolsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (symbols.isEmpty) return;

    final body = {
      'symbols': symbols,
      'timeframe': _createTimeframeController.text.trim(),
    };

    try {
      final res = await widget.viewModel.adminService.createJob(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.isOk ? 'Analysis job created!' : 'Failed: ${res.body}'),
            backgroundColor: res.isOk ? AdminColors.success : AdminColors.danger,
          ),
        );
      }
      if (res.isOk && res.data is Map && res.data['jobId'] != null) {
        final newId = res.data['jobId'].toString();
        _selectedJobIdController.text = newId;
        _fetchJobStatus(newId);
        _loadJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger),
        );
      }
    }
  }

  Future<void> _cancelJob(String jobId) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Cancel Job',
      message: 'Are you sure you want to cancel job $jobId?',
      confirmLabel: 'Cancel Job',
      isDestructive: true,
    );
    if (!confirm) return;

    try {
      final res = await widget.viewModel.adminService.cancelJob(jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.isOk ? 'Job cancelled' : 'Failed: ${res.body}')),
        );
      }
      _fetchJobStatus(jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _retryJob(String jobId) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Retry Job',
      message: 'Retry job $jobId?',
      confirmLabel: 'Retry',
    );
    if (!confirm) return;

    try {
      final res = await widget.viewModel.adminService.retryJob(jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.isOk ? 'Job retry triggered' : 'Failed: ${res.body}')),
        );
      }
      _fetchJobStatus(jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _retryFailed(String jobId) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Retry Failed Items',
      message: 'Retry only failed symbols/scans for job $jobId?',
      confirmLabel: 'Retry Failed',
    );
    if (!confirm) return;

    try {
      final res = await widget.viewModel.adminService.retryFailedJob(jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.isOk ? 'Retrying failed items' : 'Failed: ${res.body}')),
        );
      }
      _fetchJobStatus(jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'BACKGROUND JOBS',
                    style: TextStyle(
                      color: AdminColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'TradingView Analysis Jobs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isLoadingJobs ? null : _loadJobs,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Jobs'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Create Job Form
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
                const Text('CREATE ANALYSIS JOB', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _createSymbolsController,
                        decoration: const InputDecoration(labelText: 'Symbols (comma separated)', hintText: 'BINANCE:BTCUSDT, BINANCE:ETHUSDT'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _createTimeframeController,
                        decoration: const InputDecoration(labelText: 'Timeframe', hintText: '1h, 4h'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createJob,
                  icon: const Icon(Icons.play_circle_fill, size: 16),
                  label: const Text('Create & Run Job'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Inspect Job Status Form
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
                const Text('INSPECT JOB STATUS', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _selectedJobIdController,
                        decoration: const InputDecoration(labelText: 'Job ID', hintText: 'e.g. job-1721234567'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _fetchJobStatus(_selectedJobIdController.text),
                      child: const Text('Get Status'),
                    ),
                  ],
                ),
                if (_selectedJob != null && _selectedJob!.isActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => widget.viewModel.toggleJobPolling(),
                        icon: Icon(
                          widget.viewModel.jobPollPaused ? Icons.play_arrow : Icons.pause,
                          size: 14,
                        ),
                        label: Text(
                          widget.viewModel.jobPollPaused ? 'Resume auto-refresh' : 'Pause auto-refresh (5s)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Selected Job Inspector Panel
          if (_isLoadingSelected)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_selectedError != null)
            Text('Error: $_selectedError', style: const TextStyle(color: AdminColors.danger))
          else if (_selectedJob != null) ...[
            _buildJobDetailPanel(_selectedJob!),
            const SizedBox(height: 24),
          ],

          // Recent Jobs List
          const Text('Recent Jobs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          if (_jobsError != null)
            Text('Error: $_jobsError', style: const TextStyle(color: AdminColors.danger)),

          if (_isLoadingJobs)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_jobs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AdminColors.panelSoft, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('No recent jobs found.', style: TextStyle(color: AdminColors.muted))),
            )
          else ...[
            ..._jobs.map((job) => _buildJobCard(job)),
          ],
        ],
      ),
    );
  }

  Widget _buildJobCard(JobItem job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Row(
                children: [
                  Text(
                    job.jobId.length > 20 ? '${job.jobId.substring(0, 20)}…' : job.jobId,
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14, color: AdminColors.muted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: job.jobId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied Job ID'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
              StatusBadge.fromStatus(job.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${job.type ?? 'analysis'} · Progress: ${job.progress.current ?? 0}/${job.progress.total ?? 0}',
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
          if (job.totalDurationMs != null)
            Text('Duration: ${job.totalDurationMs} ms', style: const TextStyle(color: AdminColors.muted, fontSize: 11)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              _selectedJobIdController.text = job.jobId;
              _fetchJobStatus(job.jobId);
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('Open Status', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailPanel(JobItem job) {
    final hasFailedItems = [...job.results, ...job.scanResults].any(
      (r) => r is Map && ['error', 'timeout'].contains(r['status']),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.panelStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.accentStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JOB DETAILS', style: TextStyle(color: AdminColors.muted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(
                    job.jobId,
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              StatusBadge.fromStatus(job.status),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          if (job.progress.total != null && job.progress.total! > 0) ...[
            ProgressMeter(
              fraction: job.progress.fraction,
              label: 'Progress: ${job.progress.current ?? 0} / ${job.progress.total ?? 0} ${job.progress.status != null ? "· ${job.progress.status}" : ""}',
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Wrap(
            spacing: 8,
            children: [
              if (job.isActive)
                ElevatedButton.icon(
                  onPressed: () => _cancelJob(job.jobId),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger),
                  icon: const Icon(Icons.stop, size: 14),
                  label: const Text('Cancel Job', style: TextStyle(fontSize: 12)),
                ),
              if (['failed', 'timed_out', 'cancelled'].contains(job.status))
                ElevatedButton.icon(
                  onPressed: () => _retryJob(job.jobId),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Retry Job', style: TextStyle(fontSize: 12)),
                ),
              if (job.status != 'processing' && hasFailedItems)
                OutlinedButton.icon(
                  onPressed: () => _retryFailed(job.jobId),
                  icon: const Icon(Icons.replay, size: 14),
                  label: const Text('Retry Failed Items', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Generated Report text
          if (job.alertText != null && job.alertText!.isNotEmpty) ...[
            const Text('Generated Report:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.border),
              ),
              child: SelectableText(
                job.alertText!,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Symbol results table
          if (job.results.isNotEmpty) ...[
            const Text('Symbol Results:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildSymbolTable(job.results),
            const SizedBox(height: 16),
          ],

          // Scan Results
          if (job.scanResults.isNotEmpty) ...[
            const Text('Scan Results:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...job.scanResults.map((s) => _buildScanResult(s)),
            const SizedBox(height: 16),
          ],

          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Show raw job JSON', style: TextStyle(color: AdminColors.muted, fontSize: 12)),
            children: [
              ResponseBlock(customText: const JsonEncoder.withIndent('  ').convert(job.rawJson)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolTable(List<dynamic> results) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: AdminColors.border.withValues(alpha: 0.5))),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AdminColors.panelSoft),
            children: [
              Padding(padding: EdgeInsets.all(8), child: Text('Symbol', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('Price', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('RSI', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          ...results.map((r) {
            final m = r is Map ? r : {};
            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text('${m['symbol'] ?? '—'}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(8), child: Text('${m['status'] ?? '—'}', style: const TextStyle(color: AdminColors.accent, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(8), child: Text('${m['price'] ?? '—'}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(8), child: Text('${m['rsi'] ?? '—'}', style: const TextStyle(color: Colors.white, fontSize: 12))),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScanResult(dynamic scan) {
    final m = scan is Map ? scan : {};
    final scores = m['scores'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${m['scan'] ?? 'Scan'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              StatusBadge.fromStatus(m['status']?.toString()),
            ],
          ),
          if (scores.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...scores.map((sc) {
              final scoreMap = sc is Map ? sc : {};
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${scoreMap['symbol']}: ${scoreMap['score']} (${scoreMap['reason'] ?? ''})',
                  style: const TextStyle(color: Color(0xFFC9DBEE), fontSize: 12),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
