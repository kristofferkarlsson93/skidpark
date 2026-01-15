import 'package:flutter/material.dart';

class StyledSwitchListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? secondary;

  const StyledSwitchListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      activeThumbColor: theme.colorScheme.primaryContainer,
      activeTrackColor: theme.colorScheme.primary,
      inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
      inactiveTrackColor: Colors.transparent,
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return null;
        }
        return theme.colorScheme.onSurfaceVariant;
      }),
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Icon(
            Icons.check,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          );
        }
        return Icon(Icons.close, size: 16, color: theme.colorScheme.surface);
      }),
      value: value,
      onChanged: onChanged,
      secondary: secondary,
    );
  }
}