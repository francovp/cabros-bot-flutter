import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';

enum StatusTone { ready, disabled, misconfigured, danger, active, unknown }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;

  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
  });

  factory StatusBadge.fromStatus(String? status) {
    final s = (status ?? 'unknown').toLowerCase();
    switch (s) {
      case 'ready':
      case 'completed':
      case 'analyzed':
      case 'success':
      case 'bullish':
      case 'evaluated':
      case 'buy':
        return StatusBadge(label: status ?? 'ready', tone: StatusTone.ready);
      case 'disabled':
      case 'cached':
      case 'neutral':
      case 'hold':
      case 'no_trade':
      case 'plain':
        return StatusBadge(label: status ?? 'disabled', tone: StatusTone.disabled);
      case 'danger':
      case 'failed':
      case 'cancelled':
      case 'timed_out':
      case 'timeout':
      case 'error':
      case 'bearish':
      case 'sell':
        return StatusBadge(label: status ?? 'failed', tone: StatusTone.danger);
      case 'processing':
      case 'pending':
      case 'active':
        return StatusBadge(label: status ?? 'active', tone: StatusTone.active);
      case 'misconfigured':
      case 'needs attention':
      case 'unavailable':
        return StatusBadge(label: status ?? 'misconfigured', tone: StatusTone.misconfigured);
      default:
        return StatusBadge(label: status ?? 'unknown', tone: StatusTone.unknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (tone) {
      case StatusTone.ready:
        bg = const Color(0xFF123B35);
        fg = AdminColors.success;
        break;
      case StatusTone.disabled:
        bg = const Color(0xFF253144);
        fg = const Color(0xFFA3B3C8);
        break;
      case StatusTone.danger:
        bg = const Color(0xFF3A1622);
        fg = AdminColors.danger;
        break;
      case StatusTone.active:
      case StatusTone.misconfigured:
      case StatusTone.unknown:
        bg = const Color(0xFF49371D);
        fg = AdminColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
