import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/data/models/openapi_spec.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';

class AdaptiveFormBuilder extends StatefulWidget {
  final Map<String, dynamic> schema;
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;
  final String title;

  const AdaptiveFormBuilder({
    super.key,
    required this.schema,
    this.initialValue,
    required this.onChanged,
    this.title = 'Parameters',
  });

  @override
  State<AdaptiveFormBuilder> createState() => _AdaptiveFormBuilderState();
}

class _AdaptiveFormBuilderState extends State<AdaptiveFormBuilder> {
  late dynamic _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue ?? OpenApiSpec.initialValue(widget.schema);
  }

  @override
  void didUpdateWidget(covariant AdaptiveFormBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != null) {
      _currentValue = widget.initialValue;
    }
  }

  void _update(dynamic next) {
    setState(() {
      _currentValue = next;
    });
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveField(
      title: widget.title,
      schema: widget.schema,
      value: _currentValue,
      required: true,
      onChanged: _update,
      isRoot: true,
    );
  }
}

class AdaptiveField extends StatefulWidget {
  final String title;
  final Map<String, dynamic> schema;
  final dynamic value;
  final bool required;
  final ValueChanged<dynamic> onChanged;
  final bool isRoot;

  const AdaptiveField({
    super.key,
    required this.title,
    required this.schema,
    required this.value,
    this.required = false,
    required this.onChanged,
    this.isRoot = false,
  });

  @override
  State<AdaptiveField> createState() => _AdaptiveFieldState();
}

class _AdaptiveFieldState extends State<AdaptiveField> {
  bool _obscureSecret = true;
  final _customKeyController = TextEditingController();
  String _customType = 'string';

  @override
  void dispose() {
    _customKeyController.dispose();
    super.dispose();
  }

  static String formatLabel(String key) {
    if (key.isEmpty) return '';
    final spaced = key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll(RegExp(r'[-_]'), ' ')
        .trim();
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  bool _isSecret(String name, String? format) {
    if (format == 'password') return true;
    final clean = name.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    return clean.contains('secret') ||
        clean.contains('password') ||
        clean.contains('token') ||
        clean.contains('apikey') ||
        clean.contains('auth');
  }

  bool _isMultiline(String name, String type) {
    if (type != 'string') return false;
    final lower = name.toLowerCase();
    return lower.contains('message') ||
        lower.contains('prompt') ||
        lower.contains('description') ||
        lower.contains('text') ||
        lower.contains('content');
  }

  @override
  Widget build(BuildContext context) {
    final activeSchema = OpenApiSpec.fieldSchema(widget.schema, widget.value);
    final type = OpenApiSpec.typeOf(activeSchema, widget.value);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    final titleWithRequired = widget.title + (widget.required ? ' *' : '');
    final description = activeSchema['description']?.toString();

    // 1. OBJECT TYPE
    if (type == 'object') {
      final objValue = widget.value is Map<String, dynamic>
          ? Map<String, dynamic>.from(widget.value as Map<String, dynamic>)
          : (widget.value is Map ? Map<String, dynamic>.from(widget.value as Map) : <String, dynamic>{});

      final props = (activeSchema['properties'] as Map<String, dynamic>?) ?? {};
      final allKeys = <String>{...props.keys, ...objValue.keys};
      final requiredList = (activeSchema['required'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};

      final allowAdditional = activeSchema['additionalProperties'] != false;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: widget.isRoot
              ? Colors.transparent
              : (isIOS ? CupertinoColors.secondarySystemBackground.resolveFrom(context).withValues(alpha: 0.1) : AdminColors.panel),
          borderRadius: BorderRadius.circular(10),
          border: widget.isRoot ? null : Border.all(color: AdminColors.border),
        ),
        padding: widget.isRoot ? EdgeInsets.zero : const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isRoot) ...[
              Row(
                children: [
                  Text(
                    titleWithRequired,
                    style: TextStyle(
                      color: isIOS ? CupertinoColors.label.resolveFrom(context) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (activeSchema['variants'] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'POLYMorphic',
                        style: TextStyle(fontSize: 10, color: AdminColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AdminColors.muted, fontSize: 12),
                ),
              ],
              const Divider(color: AdminColors.border, height: 16),
            ],

            // Render children fields
            ...allKeys.map((key) {
              final childSchema = props[key] is Map<String, dynamic>
                  ? props[key] as Map<String, dynamic>
                  : <String, dynamic>{'type': 'string'};
              final childRequired = requiredList.contains(key);
              final childVal = objValue[key];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdaptiveField(
                        title: formatLabel(key),
                        schema: childSchema,
                        value: childVal,
                        required: childRequired,
                        onChanged: (newVal) {
                          final updated = Map<String, dynamic>.from(objValue);
                          if (newVal == null) {
                            updated.remove(key);
                          } else {
                            updated[key] = newVal;
                          }
                          widget.onChanged(updated);
                        },
                      ),
                    ),
                    if (allowAdditional && !props.containsKey(key))
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.danger),
                        tooltip: 'Remove $key',
                        onPressed: () {
                          final updated = Map<String, dynamic>.from(objValue);
                          updated.remove(key);
                          widget.onChanged(updated);
                        },
                      ),
                  ],
                ),
              );
            }),

            // Additional field adder
            if (allowAdditional) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _customKeyController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Add custom field',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _customType,
                    isDense: true,
                    dropdownColor: AdminColors.panelStrong,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'string', child: Text('String')),
                      DropdownMenuItem(value: 'number', child: Text('Number')),
                      DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
                      DropdownMenuItem(value: 'object', child: Text('Object')),
                      DropdownMenuItem(value: 'array', child: Text('List')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _customType = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      final key = _customKeyController.text.trim();
                      if (key.isNotEmpty && !objValue.containsKey(key)) {
                        final updated = Map<String, dynamic>.from(objValue);
                        final initVal = OpenApiSpec.initialValue({'type': _customType});
                        updated[key] = initVal;
                        _customKeyController.clear();
                        widget.onChanged(updated);
                      }
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // 2. ARRAY / LIST TYPE
    if (type == 'array') {
      final listValue = widget.value is List ? List<dynamic>.from(widget.value as List) : <dynamic>[];
      final itemSchema = activeSchema['items'] is Map<String, dynamic>
          ? activeSchema['items'] as Map<String, dynamic>
          : <String, dynamic>{'type': 'string'};

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isIOS ? CupertinoColors.secondarySystemBackground.resolveFrom(context).withValues(alpha: 0.1) : AdminColors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$titleWithRequired (${listValue.length} items)',
                  style: TextStyle(
                    color: isIOS ? CupertinoColors.label.resolveFrom(context) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final nextList = List<dynamic>.from(listValue);
                    nextList.add(OpenApiSpec.initialValue(itemSchema));
                    widget.onChanged(nextList);
                  },
                  icon: const Icon(Icons.add, size: 14, color: AdminColors.accent),
                  label: const Text('Add item', style: TextStyle(fontSize: 12, color: AdminColors.accent)),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            if (listValue.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Empty list. Click "Add item" to add.', style: TextStyle(color: AdminColors.muted, fontSize: 12)),
              )
            else
              ...listValue.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 10, right: 6),
                        child: Text('#${idx + 1}', style: const TextStyle(color: AdminColors.muted, fontSize: 11)),
                      ),
                      Expanded(
                        child: AdaptiveField(
                          title: 'Item ${idx + 1}',
                          schema: itemSchema,
                          value: item,
                          required: true,
                          onChanged: (newVal) {
                            final nextList = List<dynamic>.from(listValue);
                            nextList[idx] = newVal;
                            widget.onChanged(nextList);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AdminColors.muted),
                        tooltip: 'Remove item',
                        onPressed: () {
                          final nextList = List<dynamic>.from(listValue);
                          nextList.removeAt(idx);
                          widget.onChanged(nextList);
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );
    }

    // 3. BOOLEAN TYPE
    if (type == 'boolean') {
      final boolVal = widget.value is bool ? widget.value as bool : false;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AdminColors.inputBg,
          borderRadius: BorderRadius.circular(8),
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
                    titleWithRequired,
                    style: TextStyle(
                      color: isIOS ? CupertinoColors.label.resolveFrom(context) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null)
                    Text(description, style: const TextStyle(color: AdminColors.muted, fontSize: 11)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  boolVal ? 'True' : 'False',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: boolVal ? AdminColors.success : AdminColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                if (isIOS)
                  CupertinoSwitch(
                    value: boolVal,
                    activeTrackColor: AdminColors.accent,
                    onChanged: (val) => widget.onChanged(val),
                  )
                else
                  Switch.adaptive(
                    value: boolVal,
                    activeTrackColor: AdminColors.accent,
                    onChanged: (val) => widget.onChanged(val),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    // 4. ENUM TYPE
    final enumList = activeSchema['enum'] as List<dynamic>?;
    if (enumList != null && enumList.isNotEmpty) {
      final currentStr = widget.value?.toString();
      final hasMatch = enumList.any((e) => e.toString() == currentStr);
      final selectedVal = hasMatch ? currentStr : (widget.required ? enumList.first.toString() : null);

      if (isIOS) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titleWithRequired, style: const TextStyle(color: AdminColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: AdminColors.inputBg,
                borderRadius: BorderRadius.circular(8),
                onPressed: () {
                  showCupertinoModalPopup<void>(
                    context: context,
                    builder: (ctx) => CupertinoActionSheet(
                      title: Text(widget.title),
                      message: description != null ? Text(description) : null,
                      actions: enumList.map((item) {
                        final s = item.toString();
                        return CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onChanged(s);
                          },
                          child: Text(s),
                        );
                      }).toList(),
                      cancelButton: CupertinoActionSheetAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedVal ?? 'Select option',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Icon(CupertinoIcons.chevron_down, size: 14, color: AdminColors.muted),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: DropdownButtonFormField<String>(
          initialValue: selectedVal,
          isExpanded: true,
          dropdownColor: AdminColors.panelStrong,
          decoration: InputDecoration(
            labelText: titleWithRequired,
            helperText: description,
            helperMaxLines: 2,
            isDense: true,
          ),
          items: [
            if (!widget.required)
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Default / None', style: TextStyle(color: AdminColors.muted, fontSize: 13)),
              ),
            ...enumList.map((e) {
              final str = e.toString();
              return DropdownMenuItem<String>(
                value: str,
                child: Text(str, style: const TextStyle(fontSize: 13)),
              );
            }),
          ],
          onChanged: (val) => widget.onChanged(val),
        ),
      );
    }

    // 5. NUMERIC TYPE (number / integer)
    if (type == 'number' || type == 'integer') {
      final isInt = type == 'integer';
      final currentNum = widget.value is num ? widget.value as num : null;
      final textVal = currentNum != null ? (isInt ? currentNum.toInt().toString() : currentNum.toString()) : '';

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: TextFormField(
          initialValue: textVal,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInt, signed: true),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: titleWithRequired,
            helperText: description ?? (isInt ? 'Integer number' : 'Decimal number'),
            isDense: true,
            suffixIcon: isMacOS
                ? const Icon(Icons.numbers, size: 16, color: AdminColors.muted)
                : null,
          ),
          onChanged: (str) {
            final trimmed = str.trim();
            if (trimmed.isEmpty) {
              widget.onChanged(widget.required ? (isInt ? 0 : 0.0) : null);
              return;
            }
            if (isInt) {
              final val = int.tryParse(trimmed);
              if (val != null) widget.onChanged(val);
            } else {
              final val = double.tryParse(trimmed);
              if (val != null) widget.onChanged(val);
            }
          },
        ),
      );
    }

    // 6. STRING & TEXT TYPE
    final secret = _isSecret(widget.title, activeSchema['format']?.toString());
    final multiline = _isMultiline(widget.title, type);
    final strVal = widget.value?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: strVal,
        obscureText: secret && _obscureSecret,
        keyboardType: multiline
            ? TextInputType.multiline
            : (activeSchema['format'] == 'uri' ? TextInputType.url : TextInputType.text),
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 6 : 1,
        style: TextStyle(
          fontSize: 13,
          fontFamily: multiline ? 'monospace' : null,
        ),
        decoration: InputDecoration(
          labelText: titleWithRequired,
          helperText: description,
          helperMaxLines: 2,
          isDense: true,
          suffixIcon: secret
              ? IconButton(
                  icon: Icon(
                    _obscureSecret ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: AdminColors.muted,
                  ),
                  tooltip: _obscureSecret ? 'Show secret' : 'Hide secret',
                  onPressed: () {
                    setState(() => _obscureSecret = !_obscureSecret);
                  },
                )
              : null,
        ),
        onChanged: (str) {
          final trimmed = str.trim();
          widget.onChanged(trimmed.isEmpty && !widget.required ? null : str);
        },
      ),
    );
  }
}
