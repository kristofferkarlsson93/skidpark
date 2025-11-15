import 'package:flutter/material.dart';

enum FlatStatsCardSize { large, small }

class FlatStatsCard extends StatelessWidget {
  const FlatStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.borderColor,
    this.size = FlatStatsCardSize.large,
  });

  final String label;
  final String value;
  final String unit;
  final Color borderColor;
  final FlatStatsCardSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final bool isSmall = size == FlatStatsCardSize.small;

    final EdgeInsets padding = isSmall
        ? const EdgeInsets.all(8.0)
        : const EdgeInsets.all(16.0);

    final TextStyle? labelStyle =
        (isSmall ? textTheme.labelMedium : textTheme.labelLarge)?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

    final TextStyle? valueStyle =
        (isSmall ? textTheme.titleLarge : textTheme.displaySmall)?.copyWith(
          fontWeight: FontWeight.bold,
        );

    final TextStyle? unitStyle =
        (isSmall ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: borderColor.withValues(alpha: 0.15),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            SizedBox(height: isSmall ? 2 : 4),
            Text(value, style: valueStyle),
            Text(unit, style: unitStyle),
          ],
        ),
      ),
    );
  }
}
