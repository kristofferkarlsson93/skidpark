import 'package:flutter/material.dart';

class InstructionItem {
  final IconData icon;
  final String primaryText;
  final String secondaryText;

  const InstructionItem({
    required this.icon,
    required this.primaryText,
    required this.secondaryText,
  });
}

class InstructionGuide extends StatelessWidget {
  final InstructionItem firstInstruction;
  final InstructionItem? secondInstruction;

  const InstructionGuide({
    super.key,
    required this.firstInstruction,
    this.secondInstruction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (secondInstruction == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildItem(theme, firstInstruction),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: _buildItem(theme, firstInstruction),
          ),
        ),
        Container(
          width: 1,
          height: 30,
          color: theme.colorScheme.outlineVariant,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: _buildItem(theme, secondInstruction!),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(ThemeData theme, InstructionItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Icon(item.icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.primaryText.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            Text(
              item.secondaryText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}