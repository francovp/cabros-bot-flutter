import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/features/alerts/alerts_view.dart';
import 'package:cabros_bot_flutter/ui/features/analysis/analysis_view.dart';
import 'package:cabros_bot_flutter/ui/features/auth/auth_modal.dart';
import 'package:cabros_bot_flutter/ui/features/jobs/jobs_view.dart';
import 'package:cabros_bot_flutter/ui/features/outcomes/outcomes_view.dart';
import 'package:cabros_bot_flutter/ui/features/overview/overview_view.dart';
import 'package:cabros_bot_flutter/ui/features/playground/playground_view.dart';
import 'package:cabros_bot_flutter/ui/features/presets/presets_view.dart';
import 'package:cabros_bot_flutter/ui/features/status/status_view.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

const double kLargeScreenBreakpoint = 768.0;

class ShellView extends StatelessWidget {
  final AdminViewModel viewModel;

  const ShellView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth >= kLargeScreenBreakpoint;

            if (isLargeScreen) {
              return Scaffold(
                body: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: _buildSidebar(context),
                    ),
                    const VerticalDivider(width: 1, color: AdminColors.border),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopbar(context, showMenuButton: false),
                          const Divider(height: 1, color: AdminColors.border),
                          Expanded(child: _buildContent()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: _buildTopbar(context, showMenuButton: true),
                ),
                drawer: Drawer(
                  backgroundColor: AdminColors.panelStrong,
                  child: _buildSidebar(context, isDrawer: true),
                ),
                body: _buildContent(),
              );
            }
          },
        );
      },
    ),
  );
}

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    return Container(
      color: AdminColors.panel,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Lockup
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AdminColors.accent, Color(0xFFA688FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'CB',
                    style: TextStyle(
                      color: Color(0xFF071422),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPERATIONS',
                      style: TextStyle(
                        color: AdminColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Cabros Bot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'WORKSPACE',
              style: TextStyle(
                color: AdminColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Nav Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _navButton(context, AdminTab.overview, 'Overview', Icons.dashboard_outlined, isDrawer),
                _navButton(context, AdminTab.status, 'Status', Icons.monitor_heart_outlined, isDrawer),
                _navButton(context, AdminTab.alerts, 'Alerts', Icons.notifications_active_outlined, isDrawer),
                _navButton(context, AdminTab.outcomes, 'Outcomes', Icons.insights_outlined, isDrawer),
                _navButton(context, AdminTab.presets, 'Presets', Icons.layers_outlined, isDrawer),
                _navButton(context, AdminTab.jobs, 'Jobs', Icons.work_history_outlined, isDrawer),
                _navButton(context, AdminTab.analysis, 'Analysis', Icons.auto_graph_outlined, isDrawer),
                _navButton(context, AdminTab.playground, 'Playground', Icons.play_circle_outline, isDrawer),
              ],
            ),
          ),

          const Divider(color: AdminColors.border, height: 24),
          const Text(
            'Protected operator console',
            style: TextStyle(color: AdminColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _navButton(BuildContext context, AdminTab tab, String label, IconData icon, bool isDrawer) {
    final isSelected = viewModel.currentTab == tab;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFF173552) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            viewModel.setTab(tab);
            if (isDrawer) Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AdminColors.borderBright : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AdminColors.accent : AdminColors.muted,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AdminColors.muted,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar(BuildContext context, {required bool showMenuButton}) {
    final hasApiKey = viewModel.apiClient.apiKey != null && viewModel.apiClient.apiKey!.isNotEmpty;

    return Container(
      color: AdminColors.panelStrong,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (showMenuButton) ...[
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu, color: AdminColors.accent),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'OPERATOR WORKSPACE',
                        style: TextStyle(
                          color: AdminColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (!showMenuButton)
                        const Text(
                          'Monitor, diagnose and trigger safely',
                          style: TextStyle(
                            color: Color(0xFFD7E5F6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!showMenuButton) ...[
                // Server indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.panel,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AdminColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _shortUrl(viewModel.apiClient.baseUrl),
                        style: const TextStyle(color: AdminColors.muted, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                icon: Icon(
                  hasApiKey ? Icons.vpn_key : Icons.vpn_key_outlined,
                  size: 18,
                  color: hasApiKey ? AdminColors.success : AdminColors.warning,
                ),
                tooltip: hasApiKey ? 'API Key Active' : 'Configure Credentials',
                onPressed: () => AuthModal.show(context, viewModel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }

  Widget _buildContent() {
    switch (viewModel.currentTab) {
      case AdminTab.overview:
        return OverviewView(viewModel: viewModel);
      case AdminTab.status:
        return StatusView(viewModel: viewModel);
      case AdminTab.alerts:
        return AlertsView(viewModel: viewModel);
      case AdminTab.outcomes:
        return OutcomesView(viewModel: viewModel);
      case AdminTab.presets:
        return PresetsView(viewModel: viewModel);
      case AdminTab.jobs:
        return JobsView(viewModel: viewModel);
      case AdminTab.analysis:
        return AnalysisView(viewModel: viewModel);
      case AdminTab.playground:
        return PlaygroundView(viewModel: viewModel);
    }
  }
}
