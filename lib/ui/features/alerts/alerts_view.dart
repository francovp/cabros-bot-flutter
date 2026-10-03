import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabros_bot_flutter/data/models/alert_model.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/confirm_dialog.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/metric_card.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/response_block.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/status_badge.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class AlertsView extends StatefulWidget {
  final AdminViewModel viewModel;

  const AlertsView({super.key, required this.viewModel});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Alerts List State
  final _limitController = TextEditingController(text: '50');
  final _beforeController = TextEditingController();
  final _sourceController = TextEditingController();
  String _enrichedFilter = '';
  bool _isLoadingList = false;
  String? _listError;
  AlertListResponse? _listResponse;
  final List<String> _backCursors = [];

  // Summary State
  final _summaryLimitController = TextEditingController(text: '500');
  final _summarySourceController = TextEditingController();
  String _summaryEnriched = '';
  bool _isLoadingSummary = false;
  String? _summaryError;
  AlertSummaryData? _summaryData;

  // Export State
  String _exportFormat = 'json';
  bool _isExporting = false;
  String? _exportResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _limitController.dispose();
    _beforeController.dispose();
    _sourceController.dispose();
    _summaryLimitController.dispose();
    _summarySourceController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts([String? cursor]) async {
    setState(() {
      _isLoadingList = true;
      _listError = null;
      if (cursor != null) _beforeController.text = cursor;
    });

    try {
      final res = await widget.viewModel.adminService.getAlerts(
        limit: int.tryParse(_limitController.text) ?? 50,
        before: _beforeController.text.isNotEmpty ? _beforeController.text : null,
        source: _sourceController.text.isNotEmpty ? _sourceController.text : null,
        enriched: _enrichedFilter.isNotEmpty ? _enrichedFilter : null,
      );
      setState(() {
        _listResponse = res;
      });
    } catch (e) {
      setState(() {
        _listError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingList = false;
      });
    }
  }

  Future<void> _nextPage() async {
    final nextCursor = _listResponse?.pagination.nextBefore;
    if (nextCursor != null && nextCursor.isNotEmpty) {
      _backCursors.add(_beforeController.text);
      await _loadAlerts(nextCursor);
    }
  }

  Future<void> _prevPage() async {
    if (_backCursors.isNotEmpty) {
      final prevCursor = _backCursors.removeLast();
      await _loadAlerts(prevCursor);
    }
  }

  Future<void> _replayAlert(String alertId) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Replay Alert',
      message: 'Are you sure you want to replay alert $alertId? Delivery will be retried to enabled channels.',
      confirmLabel: 'Replay Alert',
    );
    if (!confirm) return;

    try {
      final res = await widget.viewModel.adminService.replayAlert(alertId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.isOk ? 'Alert replayed successfully' : 'Replay failed: ${res.body}'),
            backgroundColor: res.isOk ? AdminColors.success : AdminColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger),
        );
      }
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final res = await widget.viewModel.adminService.getAlertSummary(
        limit: int.tryParse(_summaryLimitController.text) ?? 500,
        source: _summarySourceController.text.isNotEmpty ? _summarySourceController.text : null,
        enriched: _summaryEnriched.isNotEmpty ? _summaryEnriched : null,
      );
      setState(() {
        _summaryData = res;
      });
    } catch (e) {
      setState(() {
        _summaryError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _runExport() async {
    setState(() {
      _isExporting = true;
      _exportResult = null;
    });

    try {
      final res = await widget.viewModel.adminService.exportAlerts(
        format: _exportFormat,
        limit: int.tryParse(_summaryLimitController.text) ?? 500,
      );
      setState(() {
        _exportResult = res.isOk ? res.body : 'Export failed: ${res.body}';
      });
    } catch (e) {
      setState(() {
        _exportResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AdminColors.panelStrong,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AdminColors.accent,
            labelColor: AdminColors.accent,
            unselectedLabelColor: AdminColors.muted,
            tabs: const [
              Tab(text: 'Alerts List'),
              Tab(text: 'Analytics Summary'),
              Tab(text: 'Export'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListView(),
              _buildSummaryView(),
              _buildExportView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final alerts = _listResponse?.alerts ?? [];
    final pagination = _listResponse?.pagination;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Form
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
                const Text('FILTERS & PAGINATION', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _limitController,
                        decoration: const InputDecoration(labelText: 'Limit'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _beforeController,
                        decoration: const InputDecoration(labelText: 'Before Cursor'),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _sourceController,
                        decoration: const InputDecoration(labelText: 'Source'),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _enrichedFilter,
                        decoration: const InputDecoration(labelText: 'Enriched'),
                        dropdownColor: AdminColors.panelStrong,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All')),
                          DropdownMenuItem(value: 'true', child: Text('Enriched only')),
                          DropdownMenuItem(value: 'false', child: Text('Plain only')),
                        ],
                        onChanged: (val) => setState(() => _enrichedFilter = val ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoadingList ? null : () => _loadAlerts(),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Load Alerts'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _backCursors.isNotEmpty ? _prevPage : null,
                      child: const Text('Previous Page'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: pagination?.hasMore == true ? _nextPage : null,
                      child: const Text('Next Page'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_listError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1622),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.danger),
              ),
              child: Text('Error: $_listError', style: const TextStyle(color: Color(0xFFFFC4CD))),
            ),
            const SizedBox(height: 16),
          ],

          if (_isLoadingList)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (alerts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminColors.panelSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.border),
              ),
              child: const Center(
                child: Text('No stored alerts match these filters.', style: TextStyle(color: AdminColors.muted)),
              ),
            )
          else
            ...alerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
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
              Expanded(
                child: Row(
                  children: [
                    Text(
                      alert.source != null ? 'Source: ${alert.source}' : 'Stored alert',
                      style: const TextStyle(color: AdminColors.muted, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: alert.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied Alert ID'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminColors.panelSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              alert.id.length > 12 ? '${alert.id.substring(0, 12)}…' : alert.id,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AdminColors.accent),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 10, color: AdminColors.muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  if (alert.sentiment != null)
                    StatusBadge.fromStatus(alert.sentiment),
                  StatusBadge(
                    label: alert.enriched ? 'Enriched' : 'Plain',
                    tone: alert.enriched ? StatusTone.ready : StatusTone.disabled,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFC9DBEE), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Delivery chips
          if (alert.deliveryResults.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: alert.deliveryResults.entries.map((e) {
                final ok = e.value.success;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ok ? const Color(0xFF103B3A) : const Color(0xFF33141D),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ok ? AdminColors.success : AdminColors.danger),
                  ),
                  child: Text(
                    '${e.key}: ${ok ? 'ok' : 'fail'}',
                    style: TextStyle(
                      color: ok ? AdminColors.success : AdminColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Expandable detail
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Show detail', style: TextStyle(color: AdminColors.accent, fontSize: 12)),
            children: [
              _buildAlertDetailPanel(alert),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertDetailPanel(AlertItem alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alert.setupType != null) ...[
            Text('Setup: ${alert.setupType}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
          ],
          if (alert.invalidationLevel != null || alert.targetLevel != null) ...[
            Text('Target: ${alert.targetLevel} · Invalidation: ${alert.invalidationLevel} · R:R: ${alert.riskRewardRatio}',
                style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
            const SizedBox(height: 8),
          ],
          if (alert.insights.isNotEmpty) ...[
            const Text('Key Insights:', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...alert.insights.map((insight) => Text('• $insight', style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(height: 8),
          ],
          if (alert.tokenUsage != null) ...[
            Text('Tokens: ${alert.tokenUsage!['totalTokens']} total (${alert.tokenUsage!['inputTokens']} in · ${alert.tokenUsage!['outputTokens']} out)',
                style: const TextStyle(color: AdminColors.muted, fontSize: 11)),
            const SizedBox(height: 8),
          ],
          ElevatedButton.icon(
            onPressed: () => _replayAlert(alert.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.accentStrong,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.replay, size: 14),
            label: const Text('Replay Alert', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const Text('ANALYTICS WINDOW & FILTERS', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _summaryLimitController,
                        decoration: const InputDecoration(labelText: 'Limit'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _summarySourceController,
                        decoration: const InputDecoration(labelText: 'Source'),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _summaryEnriched,
                        decoration: const InputDecoration(labelText: 'Enriched'),
                        dropdownColor: AdminColors.panelStrong,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All')),
                          DropdownMenuItem(value: 'true', child: Text('Enriched only')),
                          DropdownMenuItem(value: 'false', child: Text('Plain only')),
                        ],
                        onChanged: (val) => setState(() => _summaryEnriched = val ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoadingSummary ? null : _loadSummary,
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Load Alert Analytics'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_summaryError != null)
            Text('Error: $_summaryError', style: const TextStyle(color: AdminColors.danger)),

          if (_isLoadingSummary)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_summaryData != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 200,
                  child: MetricCard(
                    label: 'Total Alerts',
                    value: '${_summaryData!.totalAlerts ?? 0}',
                    meta: _summaryData!.from != null ? '${_summaryData!.from} → ${_summaryData!.to}' : 'In window',
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: MetricCard(
                    label: 'Delivery',
                    value: '${_summaryData!.totalSuccess ?? 0} ok',
                    meta: '${_summaryData!.totalFailure ?? 0} failed',
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: MetricCard(
                    label: 'Tokens',
                    value: '${_summaryData!.totalTokens ?? 0}',
                    meta: _summaryData!.totalCost != null ? 'Cost ${_summaryData!.totalCost}' : 'LLM usage',
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: MetricCard(
                    label: 'Enriched Alerts',
                    value: '${_summaryData!.enrichedAlerts ?? 0}',
                    meta: '${_summaryData!.plainAlerts ?? 0} plain',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_summaryData!.deliveryByChannel.isNotEmpty) ...[
              const Text('Delivery by Channel', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSimpleTable(
                ['Channel', 'Total', 'Success', 'Failure'],
                _summaryData!.deliveryByChannel.entries.map((e) {
                  final m = e.value is Map ? e.value as Map : {};
                  return [e.key, '${m['total'] ?? 0}', '${m['success'] ?? 0}', '${m['failure'] ?? 0}'];
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            if (_summaryData!.riskCoverageFields.isNotEmpty) ...[
              const Text('Risk Metadata Coverage', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSimpleTable(
                ['Field', 'Populated', 'Percentage'],
                _summaryData!.riskCoverageFields.entries.map((e) {
                  final m = e.value is Map ? e.value as Map : {};
                  return [e.key, '${m['populated'] ?? 0} / ${_summaryData!.coverageDenominator ?? 0}', '${m['percentage'] ?? 0}%'];
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildExportView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const Text('EXPORT ALERTS', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        initialValue: _exportFormat,
                        decoration: const InputDecoration(labelText: 'Format'),
                        dropdownColor: AdminColors.panelStrong,
                        items: const [
                          DropdownMenuItem(value: 'json', child: Text('JSON')),
                          DropdownMenuItem(value: 'csv', child: Text('CSV')),
                        ],
                        onChanged: (val) => setState(() => _exportFormat = val ?? 'json'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _runExport,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export Data'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_isExporting)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_exportResult != null) ...[
            const Text('Export Output Preview:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ResponseBlock(customText: _exportResult),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleTable(List<String> headers, List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: AdminColors.border.withValues(alpha: 0.5))),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AdminColors.panelSoft),
            children: headers.map((h) => Padding(
              padding: const EdgeInsets.all(10),
              child: Text(h, style: const TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
          ...rows.map((row) => TableRow(
            children: row.map((cell) => Padding(
              padding: const EdgeInsets.all(10),
              child: Text(cell, style: const TextStyle(color: Colors.white, fontSize: 12)),
            )).toList(),
          )),
        ],
      ),
    );
  }
}
