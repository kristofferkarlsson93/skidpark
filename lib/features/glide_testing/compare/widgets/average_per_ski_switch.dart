import 'package:flutter/material.dart';

import '../../../../common/shared_widgets/styled_switch_list_tile.dart';

class AveragePerSkiSwitch extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const AveragePerSkiSwitch({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StyledSwitchListTile(
      title: 'Medelåk per skida',
      value: isActive,
      onChanged: onChanged,
      secondary: IconButton(
        icon: const Icon(Icons.info_outlined),
        color: theme.colorScheme.primary,
        tooltip: "Mer information",
        onPressed: () => _showInfoDialog(context, theme),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        title: const Text('Medelvärde per skida'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "När denna switch är påslagen slås alla valda åk från samma skida ihop till ett medelåk.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Jag förstår'),
          ),
        ],
      ),
    );
  }
}
