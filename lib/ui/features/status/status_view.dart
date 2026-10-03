import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/response_block.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/status_badge.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class StatusView extends StatelessWidget {
  final AdminViewModel viewModel;

  const StatusView({super.key, required this.viewModel});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SYSTEM HEALTH',
                        style: TextStyle(
                          color: AdminColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Status & Capabilities',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A1622),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.danger),
                  ),
                  child: Text('Error: $error', style: const TextStyle(color: Color(0xFFFFC4CD))),
                ),
                const SizedBox(height: 20),
              ],

              if (status != null) ...[
                // Service Details Card
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
                      const Text(
                        'SERVICE INFORMATION',
                        style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Service Name', status.service.name),
                      _infoRow('Version', status.service.version),
                      _infoRow('Environment', status.service.environment),
                      if (status.service.commit != null) _infoRow('Git Commit', status.service.commit!),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Delivery Channels
                const Text('Delivery Channels', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...status.deliveryChannels.entries.map((e) => _itemTile(e.key, e.value)),

                const SizedBox(height: 20),
                // Dependencies
                const Text('Dependencies', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...status.dependencies.entries.map((e) => _itemTile(e.key, e.value)),

                const SizedBox(height: 20),
                // Feature Flags
                const Text('Feature Flags', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: status.featureFlags.entries.map((e) {
                    final isEnabled = e.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isEnabled ? AdminColors.chipBg : AdminColors.panelSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isEnabled ? const Color(0xFF2E5D77) : AdminColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEnabled ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: isEnabled ? AdminColors.success : AdminColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.key,
                            style: TextStyle(
                              color: isEnabled ? Colors.white : AdminColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Show full JSON response', style: TextStyle(color: AdminColors.muted, fontSize: 13)),
                  children: [
                    ResponseBlock(customText: const JsonEncoder.withIndent('  ').convert(status.rawJson)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AdminColors.muted, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _itemTile(String name, dynamic detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              if (detail.provider != null)
                Text('Provider: ${detail.provider}', style: const TextStyle(color: AdminColors.muted, fontSize: 11)),
            ],
          ),
          StatusBadge.fromStatus(detail.status),
        ],
      ),
    );
  }
}
