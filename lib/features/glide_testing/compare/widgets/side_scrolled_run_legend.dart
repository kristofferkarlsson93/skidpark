import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/graph_line.dart';

class SideScrolledRunLegend extends StatelessWidget {
  final List<GraphLine> lines;

  const SideScrolledRunLegend({
    super.key,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: lines.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final line = lines[index];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Färg-plupp
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: line.runColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: line.runColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Etikett
              Text(
                line.label, // Använder .label enligt din kod
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}