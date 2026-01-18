import 'package:flutter/material.dart';

class FlatStatsCard extends StatelessWidget {
  const FlatStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.accentColor,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final color = accentColor ?? theme.colorScheme.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
