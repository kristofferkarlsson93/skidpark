import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  final Color backgroundColor;
  final VoidCallback? onPress;
  final String title;

  const BigButton({
    super.key,
    required this.backgroundColor,
    required this.title,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPress != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPress,
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant.withAlpha(
                    (0.5 * 255).toInt(),
                  ),
          ),
        ),
      ),
    );
  }
}
