import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/data/models/outcome_model.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/metric_card.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/status_badge.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class OutcomesView extends StatefulWidget {
  final AdminViewModel viewModel;

  const OutcomesView({super.key, required this.viewModel});

  @override
  State<OutcomesView> createState() => _OutcomesViewState();
}

class _OutcomesViewState extends State<OutcomesView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // List State
  final _limitController = TextEditingController(text: '50');
  final _symbolController = TextEditingController();
  final _exchangeController = TextEditingController();
  String _statusFilter = '';
  String _windowFilter = '';
  bool _isLoadingList = false;
  String? _listError;
  OutcomeListResponse? _listResponse;
  final List<String> _backCursors = [];

  // Summary State
  final _summarySymbolController = TextEditingController();
  final _summaryExchangeController = TextEditingController();
  final String _summaryStatus = '';
  final String _summaryWindow = '';
  bool _isLoadingSummary = false;
  String? _summaryError;
  OutcomeSummaryData? _summaryData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOutcomes();
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _limitController.dispose();
    _symbolController.dispose();
    _exchangeController.dispose();
    _summarySymbolController.dispose();
    _summaryExchangeController.dispose();
    super.dispose();
  }

  Future<void> _loadOutcomes([String? cursor]) async {
    setState(() {
      _isLoadingList = true;
      _listError = null;
    });

    try {
      final res = await widget.viewModel.adminService.getOutcomes(
        limit: int.tryParse(_limitController.text) ?? 50,
        before: cursor,
        symbol: _symbolController.text.isNotEmpty ? _symbolController.text : null,
        exchange: _exchangeController.text.isNotEmpty ? _exchangeController.text : null,
        status: _statusFilter.isNotEmpty ? _statusFilter : null,
        window: _windowFilter.isNotEmpty ? _windowFilter : null,
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

  Future<void> _loadSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final res = await widget.viewModel.adminService.getOutcomesSummary(
        symbol: _summarySymbolController.text.isNotEmpty ? _summarySymbolController.text : null,
        exchange: _summaryExchangeController.text.isNotEmpty ? _summaryExchangeController.text : null,
        status: _summaryStatus.isNotEmpty ? _summaryStatus : null,
        window: _summaryWindow.isNotEmpty ? _summaryWindow : null,
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
              Tab(text: 'Recorded Outcomes'),
              Tab(text: 'Performance Summary'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListView(),
              _buildSummaryView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final outcomes = _listResponse?.outcomes ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter card
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
                      width: 140,
                      child: TextField(
                        controller: _symbolController,
                        decoration: const InputDecoration(labelText: 'Symbol (e.g. BTCUSDT)'),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _exchangeController,
                        decoration: const InputDecoration(labelText: 'Exchange'),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Status'),
                        dropdownColor: AdminColors.panelStrong,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All')),
                          DropdownMenuItem(value: 'evaluated', child: Text('Evaluated')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'unavailable', child: Text('Unavailable')),
                        ],
                        onChanged: (val) => setState(() => _statusFilter = val ?? ''),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        initialValue: _windowFilter,
                        decoration: const InputDecoration(labelText: 'Window'),
                        dropdownColor: AdminColors.panelStrong,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All')),
                          DropdownMenuItem(value: '1h', child: Text('1h')),
                          DropdownMenuItem(value: '4h', child: Text('4h')),
                          DropdownMenuItem(value: '1D', child: Text('1D')),
                          DropdownMenuItem(value: '1W', child: Text('1W')),
                        ],
                        onChanged: (val) => setState(() => _windowFilter = val ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoadingList ? null : () => _loadOutcomes(),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Load Outcomes'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _backCursors.isNotEmpty
                          ? () {
                              final prev = _backCursors.removeLast();
                              _loadOutcomes(prev);
                            }
                          : null,
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _listResponse?.hasMore == true
                          ? () {
                              _backCursors.add('');
                              _loadOutcomes(_listResponse?.nextBefore);
                            }
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_listError != null)
            Text('Error: $_listError', style: const TextStyle(color: AdminColors.danger)),

          if (_isLoadingList)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (outcomes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminColors.panelSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No recorded outcomes match these filters.', style: TextStyle(color: AdminColors.muted))),
            )
          else
            ...outcomes.map((item) => _buildOutcomeCard(item)),
        ],
      ),
    );
  }

  Widget _buildOutcomeCard(OutcomeItem outcome) {
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
              Text(
                '${outcome.symbol} · ${outcome.exchange ?? 'Exchange'}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              StatusBadge.fromStatus(outcome.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Entry: ${outcome.entryPrice ?? '—'} · Target: ${outcome.targetPrice ?? '—'} · Stop: ${outcome.stopLossPrice ?? '—'}',
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Windows cards
          if (outcome.windows.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: outcome.windows.entries.map((w) {
                final winKey = w.key;
                final win = w.value;
                final ret = win.returnPercent;
                final isPos = ret != null && (double.tryParse(ret.toString()) ?? 0) >= 0;

                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.panelSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.borderBright),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(winKey, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(
                            ret != null ? '${isPos ? '+' : ''}$ret%' : '—',
                            style: TextStyle(
                              color: isPos ? AdminColors.success : AdminColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('MFE: +${win.mfePercent ?? 0}%', style: const TextStyle(color: AdminColors.muted, fontSize: 11)),
                      Text('MAE: ${win.maePercent ?? 0}%', style: const TextStyle(color: AdminColors.muted, fontSize: 11)),
                      if (win.rMultiple != null)
                        Text('R: ${win.rMultiple}R', style: const TextStyle(color: AdminColors.accent, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
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
          ElevatedButton.icon(
            onPressed: _isLoadingSummary ? null : _loadSummary,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh Outcomes Summary'),
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
                    label: 'Signals',
                    value: '${_summaryData!.totalSignals}',
                    meta: '${_summaryData!.totalEligible} eligible · ${_summaryData!.totalEvaluated} evaluated',
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: MetricCard(
                    label: 'Hit Rate',
                    value: _summaryData!.hitRatePercent != null ? '${_summaryData!.hitRatePercent}%' : '—',
                    meta: 'Meeting targets',
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: MetricCard(
                    label: 'Average Return',
                    value: _summaryData!.averageReturnPercent != null ? '${_summaryData!.averageReturnPercent}%' : '—',
                    meta: _summaryData!.expectancyR != null ? 'Exp: ${_summaryData!.expectancyR}R' : 'Per window',
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: MetricCard(
                    label: 'MFE / MAE',
                    value: '+${_summaryData!.averageMfePercent ?? 0}%',
                    meta: 'MAE: ${_summaryData!.averageMaePercent ?? 0}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_summaryData!.windowPerformance.isNotEmpty) ...[
              const Text('Performance by Window', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildWindowTable(_summaryData!.windowPerformance),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildWindowTable(Map<String, dynamic> windows) {
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
              Padding(padding: EdgeInsets.all(10), child: Text('Window', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(10), child: Text('Evaluated', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(10), child: Text('Hit Rate', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(10), child: Text('Exp R', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(10), child: Text('Avg Return', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          ...windows.entries.map((e) {
            final stats = e.value is Map ? e.value as Map : {};
            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(10), child: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(10), child: Text('${stats['totalSignals'] ?? stats['evaluatedCount'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(10), child: Text('${stats['hitRatePercent'] ?? '—'}%', style: const TextStyle(color: AdminColors.success, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(10), child: Text('${stats['expectancyR'] ?? '—'}R', style: const TextStyle(color: AdminColors.accent, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(10), child: Text('${stats['averageReturnPercent'] ?? '—'}%', style: const TextStyle(color: Colors.white, fontSize: 12))),
              ],
            );
          }),
        ],
      ),
    );
  }
}
