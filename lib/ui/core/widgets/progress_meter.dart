import 'package:flutter/material.dart';
import 'package:cabros_bot_flutter/ui/core/theme.dart';

class ProgressMeter extends StatelessWidget {
  final double fraction; // 0.0 to 1.0
  final String? label;

  const ProgressMeter({
    super.key,
    required this.fraction,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AdminColors.panelSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AdminColors.borderBright),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clamped,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [AdminColors.accentStrong, AdminColors.accent],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
