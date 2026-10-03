import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';
import 'package:cabros_bot_flutter/ui/core/widgets/status_badge.dart';

enum ResponseViewMode { structured, rawJson }

class StructuredResponseViewer extends StatefulWidget {
  final ApiResponse? response;
  final String? customText;
  final bool isLoading;

  const StructuredResponseViewer({
    super.key,
    this.response,
    this.customText,
    this.isLoading = false,
  });

  @override
  State<StructuredResponseViewer> createState() => _StructuredResponseViewerState();
}

class _StructuredResponseViewerState extends State<StructuredResponseViewer> {
  ResponseViewMode _mode = ResponseViewMode.structured;
  bool _copied = false;

  static final RegExp _secretKeyRegex = RegExp(
    r'secret|password|authorization|cookie|^(?:api.?key|access.?token|refresh.?token|id.?token|token)$',
    caseSensitive: false,
  );

  dynamic _parsePayload() {
    final raw = widget.customText ?? widget.response?.body;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  static dynamic _sanitizeSecrets(dynamic value) {
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      final sanitized = <String, dynamic>{};
      for (final entry in map.entries) {
        if (_secretKeyRegex.hasMatch(entry.key)) {
          sanitized[entry.key] = '[REDACTED]';
        } else {
          sanitized[entry.key] = _sanitizeSecrets(entry.value);
        }
      }
      return sanitized;
    }
    if (value is List) {
      return value.map(_sanitizeSecrets).toList();
    }
    return value;
  }

  static String _formatPlainText(dynamic value, [int depth = 0]) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      final indent = '  ' * depth;
      return map.entries
          .map((e) => '$indent${_formatLabel(e.key)}: ${_formatPlainText(e.value, depth + 1)}')
          .join('\n');
    }
    if (value is List) {
      return value.map((item) => _formatPlainText(item, depth + 1)).join(', ');
    }
    return value.toString();
  }

  static String _formatLabel(String key) {
    if (key.isEmpty) return '';
    final spaced = key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll(RegExp(r'[-_]'), ' ')
        .trim();
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AdminColors.accent,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Request in progress…',
              style: TextStyle(color: AdminColors.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (widget.response == null && widget.customText == null) {
      return const SizedBox.shrink();
    }

    final isError = widget.response != null && !widget.response!.isOk;
    final parsed = _parsePayload();
    final sanitized = _sanitizeSecrets(parsed);
    final rawText = widget.customText ?? widget.response?.body ?? '';
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdminColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? AdminColors.danger : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Wrap to prevent overflow on mobile viewports (< 400px)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.response != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isError
                              ? AdminColors.danger.withValues(alpha: 0.2)
                              : AdminColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HTTP ${widget.response!.statusCode}',
                          style: TextStyle(
                            color: isError ? AdminColors.danger : AdminColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.response!.elapsedMs} ms',
                        style: const TextStyle(color: AdminColors.muted, fontSize: 11),
                      ),
                    ],
                  )
                else
                  const Text('Output', style: TextStyle(color: AdminColors.muted, fontSize: 12)),

                // Mode Selector
                if (isIOS)
                  CupertinoSlidingSegmentedControl<ResponseViewMode>(
                    groupValue: _mode,
                    children: const {
                      ResponseViewMode.structured: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Visual', style: TextStyle(fontSize: 11)),
                      ),
                      ResponseViewMode.rawJson: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Raw JSON', style: TextStyle(fontSize: 11)),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _mode = val);
                    },
                  )
                else
                  SegmentedButton<ResponseViewMode>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ResponseViewMode.structured,
                        label: Text('Visual'),
                        icon: Icon(Icons.table_chart_outlined, size: 14),
                      ),
                      ButtonSegment(
                        value: ResponseViewMode.rawJson,
                        label: Text('Raw JSON'),
                        icon: Icon(Icons.code, size: 14),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (set) {
                      setState(() => _mode = set.first);
                    },
                  ),

                // Copy Button
                TextButton.icon(
                  onPressed: () {
                    final textToCopy = _mode == ResponseViewMode.structured
                        ? _formatPlainText(sanitized)
                        : rawText;
                    _copy(textToCopy);
                  },
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy,
                    size: 13,
                    color: _copied ? AdminColors.success : AdminColors.muted,
                  ),
                  label: Text(
                    _copied ? 'Copied' : 'Copy',
                    style: TextStyle(
                      color: _copied ? AdminColors.success : AdminColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: _mode == ResponseViewMode.rawJson || (sanitized is! Map && sanitized is! List)
                ? SelectableText(
                    rawText,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isError ? const Color(0xFFFFC4CD) : AdminColors.text,
                      height: 1.4,
                    ),
                  )
                : _buildStructuredContent(sanitized),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredContent(dynamic data) {
    if (data is List) {
      if (data.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No results (empty list).', style: TextStyle(color: AdminColors.muted, fontSize: 13)),
        );
      }

      // Check if list of maps
      final isListOfMaps = data.every((e) => e is Map);
      if (isListOfMaps) {
        final listMaps = data.map((e) => (e as Map).cast<String, dynamic>()).toList();
        final allColumns = <String>{};
        for (final m in listMaps) {
          allColumns.addAll(m.keys);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Wide viewport: show data table
            if (constraints.maxWidth >= 550) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 48,
                  horizontalMargin: 12,
                  columnSpacing: 18,
                  headingRowColor: WidgetStateProperty.all(AdminColors.panelStrong),
                  columns: allColumns.map((col) {
                    return DataColumn(
                      label: Text(
                        _formatLabel(col),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AdminColors.muted,
                        ),
                      ),
                    );
                  }).toList(),
                  rows: listMaps.map((rowMap) {
                    return DataRow(
                      cells: allColumns.map((col) {
                        final val = rowMap[col];
                        return DataCell(_renderCellValue(val));
                      }).toList(),
                    );
                  }).toList(),
                ),
              );
            }

            // Narrow mobile viewport: list of cards
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: listMaps.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item #${idx + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.accent,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...row.entries.map((prop) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text(
                                  _formatLabel(prop.key),
                                  style: const TextStyle(
                                    color: AdminColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _renderCellValue(prop.value),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      }

      // List of primitives
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Text('#${e.key + 1}: ', style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
                _renderCellValue(e.value),
              ],
            ),
          );
        }).toList(),
      );
    }

    if (data is Map) {
      final map = data.cast<String, dynamic>();
      if (map.isEmpty) {
        return const Text('Empty object {}.', style: TextStyle(color: AdminColors.muted, fontSize: 13));
      }

      return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: map.entries.map((entry) {
            final key = entry.key;
            final val = entry.value;

            if (val is Map) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminColors.panel,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatLabel(key),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AdminColors.accent,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStructuredContent(val),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      _formatLabel(key),
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _renderCellValue(val),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return Text(data.toString());
  }

  Widget _renderCellValue(dynamic value) {
    if (value == null) {
      return const Text('—', style: TextStyle(color: AdminColors.muted, fontSize: 12));
    }
    if (value is bool) {
      return StatusBadge.fromStatus(value ? 'ready' : 'disabled');
    }
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'ready' || lower == 'completed' || lower == 'active' || lower == 'success') {
        return StatusBadge.fromStatus(lower);
      }
      if (lower == 'failed' || lower == 'error' || lower == 'disabled') {
        return StatusBadge.fromStatus(lower);
      }
      return SelectableText(
        value,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      );
    }
    if (value is num) {
      return SelectableText(
        value.toString(),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return SelectableText(
      _formatPlainText(value),
      style: const TextStyle(fontSize: 12, color: Colors.white),
    );
  }
}
