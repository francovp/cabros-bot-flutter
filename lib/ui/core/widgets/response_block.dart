import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabros_bot_flutter/data/services/api_client.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';

class ResponseBlock extends StatefulWidget {
  final ApiResponse? response;
  final String? customText;
  final bool isLoading;

  const ResponseBlock({
    super.key,
    this.response,
    this.customText,
    this.isLoading = false,
  });

  @override
  State<ResponseBlock> createState() => _ResponseBlockState();
}

class _ResponseBlockState extends State<ResponseBlock> {
  bool _copied = false;

  void _copy() {
    final text = widget.response?.body ?? widget.customText ?? '';
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
    final text = widget.customText ?? widget.response?.body ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? AdminColors.danger : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.response != null)
                Text(
                  'HTTP ${widget.response!.statusCode} · ${widget.response!.elapsedMs} ms',
                  style: TextStyle(
                    color: isError ? AdminColors.danger : AdminColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'Output',
                  style: TextStyle(color: AdminColors.muted, fontSize: 12),
                ),
              TextButton.icon(
                onPressed: _copy,
                icon: Icon(
                  _copied ? Icons.check : Icons.copy,
                  size: 14,
                  color: _copied ? AdminColors.success : AdminColors.muted,
                ),
                label: Text(
                  _copied ? 'Copied!' : 'Copy',
                  style: TextStyle(
                    color: _copied ? AdminColors.success : AdminColors.muted,
                    fontSize: 11,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: isError ? const Color(0xFFFFC4CD) : AdminColors.text,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
