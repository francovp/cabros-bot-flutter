import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/metric_card.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/response_block.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/status_badge.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class OverviewView extends StatelessWidget {
  final AdminViewModel viewModel;

  const OverviewView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final status = viewModel.status;
        final isLoading = viewModel.isStatusLoading;
        final error = viewModel.statusError;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xF0163D5F), Color(0xF0111F37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIVE CONTROL PLANE',
                            style: TextStyle(
                              color: AdminColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Operational overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'A quick read on service readiness, enabled capabilities and delivery health.',
                            style: TextStyle(color: Color(0xFFB5C9DF), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            viewModel.lastChecked != null
                                ? 'Last checked ${viewModel.lastChecked!.hour.toString().padLeft(2, '0')}:${viewModel.lastChecked!.minute.toString().padLeft(2, '0')}:${viewModel.lastChecked!.second.toString().padLeft(2, '0')}'
                                : 'Waiting for live status…',
                            style: const TextStyle(color: AdminColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () => viewModel.fetchStatus(),
                      icon: isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh dashboard'),
                    ),
                  ],
                ),
              ),

              if (error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A1622),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.danger),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AdminColors.danger, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Status unavailable: $error',
                          style: const TextStyle(color: Color(0xFFFFC4CD), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Metrics Cards
              if (status != null) ...[
                _buildMetricsGrid(context, status),
                const SizedBox(height: 24),
                _buildSectionHeader('Delivery channels'),
                const SizedBox(height: 10),
                _buildStatusGrid(status.deliveryChannels),
                const SizedBox(height: 24),
                _buildSectionHeader('Dependency health'),
                const SizedBox(height: 10),
                _buildStatusGrid(status.dependencies),
                const SizedBox(height: 24),
                _buildSectionHeader('Enabled capabilities'),
                const SizedBox(height: 10),
                _buildCapabilitiesChips(status.featureFlags),
                const SizedBox(height: 24),
                _buildRawStatusViewer(status),
              ] else if (isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AdminColors.accent),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(BuildContext context, dynamic status) {
    final service = status.service;
    final enabledFlags = status.featureFlags.entries.where((e) => e.value == true).length;
    final totalFlags = status.featureFlags.length;

    final readyDeps = status.dependencies.values.where((d) => d.status == 'ready').length;
    final disabledDeps = status.dependencies.values.where((d) => d.status == 'disabled').length;
    final attentionDeps = status.dependencies.values.where((d) => !['ready', 'disabled'].contains(d.status)).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
        final width = (constraints.maxWidth - ((crossAxisCount - 1) * 12)) / crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Service',
                value: service.name,
                meta: 'Version ${service.version}',
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Environment',
                value: service.environment,
                meta: service.commit != null ? 'Commit ${service.commit!.substring(0, service.commit!.length > 8 ? 8 : service.commit!.length)}' : 'Commit unavailable',
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Features',
                value: '$enabledFlags enabled',
                meta: '$totalFlags configured flags',
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Dependencies',
                value: '$readyDeps ready',
                meta: '$attentionDeps attention · $disabledDeps disabled',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatusGrid(Map<String, dynamic> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminColors.panelSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.border),
        ),
        child: const Text('None reported.', style: TextStyle(color: AdminColors.muted, fontSize: 13)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 800 ? 3 : (constraints.maxWidth >= 480 ? 2 : 1);
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 10)) / crossAxisCount;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.entries.map((entry) {
            final name = entry.key;
            final detail = entry.value;

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.panel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail.provider != null ? 'Provider: ${detail.provider}' : detail.status,
                          style: const TextStyle(color: AdminColors.muted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.fromStatus(detail.status),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCapabilitiesChips(Map<String, bool> flags) {
    final enabled = flags.entries.where((e) => e.value == true).toList();
    if (enabled.isEmpty) {
      return const Text('No feature flags are enabled.', style: TextStyle(color: AdminColors.muted, fontSize: 13));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: enabled.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AdminColors.chipBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF2E5D77)),
          ),
          child: Text(
            e.key,
            style: const TextStyle(color: Color(0xFFBFEAFF), fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRawStatusViewer(dynamic status) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(status.rawJson);
    return ExpansionTile(
      title: const Text(
        'Show raw status response',
        style: TextStyle(color: AdminColors.muted, fontSize: 13),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ResponseBlock(customText: jsonStr),
        ),
      ],
    );
  }
}
