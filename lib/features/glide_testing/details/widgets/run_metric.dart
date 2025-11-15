import 'package:flutter/material.dart';

enum RunMetricsSize { large, small }

class RunMetrics extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  final RunMetricsSize? size;

  const RunMetrics({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = this.size == RunMetricsSize.large;
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(8),
      // color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isLarge ? 24 : null,
                  color: color
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          Text(unit, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
