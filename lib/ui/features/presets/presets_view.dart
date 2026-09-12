import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/data/models/preset_model.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/confirm_dialog.dart';
import 'package:cabros_bot_flutter/view_models/admin_view_model.dart';

class PresetsView extends StatefulWidget {
  final AdminViewModel viewModel;

  const PresetsView({super.key, required this.viewModel});

  @override
  State<PresetsView> createState() => _PresetsViewState();
}

class _PresetsViewState extends State<PresetsView> {
  List<ScannerPreset> _presets = [];
  bool _isLoading = false;
  String? _error;

  // Create Form State
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _symbolsController = TextEditingController(text: 'BINANCE:BTCUSDT, BINANCE:ETHUSDT');
  final _intervalController = TextEditingController(text: '1h');
  final Set<String> _selectedScans = {'gainers', 'breakouts'};

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _symbolsController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await widget.viewModel.adminService.getPresets();
      setState(() {
        _presets = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPreset() async {
    if (_nameController.text.trim().isEmpty) return;

    final symbols = _symbolsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final body = {
      'name': _nameController.text.trim(),
      if (_descController.text.isNotEmpty) 'description': _descController.text.trim(),
      'symbols': symbols,
      'scans': _selectedScans.toList(),
      'interval': _intervalController.text.trim(),
    };

    try {
      final res = await widget.viewModel.adminService.createPreset(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.isOk ? 'Preset created!' : 'Failed: ${res.body}'),
            backgroundColor: res.isOk ? AdminColors.success : AdminColors.danger,
          ),
        );
      }
      if (res.isOk) {
        _nameController.clear();
        _descController.clear();
        _loadPresets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger),
        );
      }
    }
  }

  Future<void> _runPreset(String id, String name) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Run Preset',
      message: 'Are you sure you want to run scanner preset "$name"?',
      confirmLabel: 'Run Preset',
    );
    if (!confirm) return;

    try {
      final res = await widget.viewModel.adminService.runPreset(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.isOk ? 'Preset triggered!' : 'Failed: ${res.body}'),
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

  Future<void> _deletePreset(String id, String name) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Preset',
      message: 'Are you sure you want to delete scanner preset "$name"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirm) return;

    try {
      final res = await widget.viewModel.adminService.deletePreset(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.isOk ? 'Preset deleted!' : 'Failed: ${res.body}'),
            backgroundColor: res.isOk ? AdminColors.success : AdminColors.danger,
          ),
        );
      }
      if (res.isOk) _loadPresets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger),
        );
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
                    'MARKET SCANNER',
                    style: TextStyle(
                      color: AdminColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Scanner Presets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadPresets,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Create Preset Form Card
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
                const Text('CREATE PRESET', style: TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Preset Name', hintText: 'e.g. Major Crypto Breakouts'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _intervalController,
                        decoration: const InputDecoration(labelText: 'Interval', hintText: '1h, 4h, 1D'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _symbolsController,
                  decoration: const InputDecoration(labelText: 'Symbols (comma separated)', hintText: 'BINANCE:BTCUSDT, BINANCE:ETHUSDT'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['gainers', 'losers', 'breakouts'].map((scan) {
                    final selected = _selectedScans.contains(scan);
                    return FilterChip(
                      selected: selected,
                      label: Text(scan),
                      selectedColor: AdminColors.chipBg,
                      checkmarkColor: AdminColors.accent,
                      labelStyle: TextStyle(color: selected ? Colors.white : AdminColors.muted),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedScans.add(scan);
                          } else {
                            _selectedScans.remove(scan);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createPreset,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Preset'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: AdminColors.danger)),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_presets.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AdminColors.panelSoft, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('No scanner presets found.', style: TextStyle(color: AdminColors.muted))),
            )
          else ...[
            const Text('Configured Presets', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._presets.map((p) => _buildPresetCard(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetCard(ScannerPreset preset) {
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
              Text(preset.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              if (preset.interval != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminColors.chipBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(preset.interval!, style: const TextStyle(color: AdminColors.accent, fontSize: 11)),
                ),
            ],
          ),
          if (preset.description != null) ...[
            const SizedBox(height: 4),
            Text(preset.description!, style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          Text('Symbols: ${preset.symbols.join(", ")}', style: const TextStyle(color: Color(0xFFC9DBEE), fontSize: 12)),
          const SizedBox(height: 6),
          Text('Scans: ${preset.scans.join(", ")}', style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _runPreset(preset.id, preset.name),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Run Preset'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _deletePreset(preset.id, preset.name),
                style: OutlinedButton.styleFrom(foregroundColor: AdminColors.danger),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
