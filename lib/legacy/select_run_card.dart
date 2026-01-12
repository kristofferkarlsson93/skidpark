import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';

class SelectRunCard extends StatelessWidget {
  final bool isSelected;

  final EnrichedTestRun testRun;

  final int runNumber;

  final VoidCallback onTap;

  const SelectRunCard({
    super.key,
    required this.isSelected,
    required this.testRun,
    required this.runNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      leading: Icon(
        Icons.circle,
        color: isSelected
            ? testRun.runColor
            : testRun.runColor.withValues(alpha: 0.2),
      ),
      title: Text("Åk ${testRun.runNumber} - ${testRun.skiName}", style: theme.textTheme.titleSmall,),
      onTap: onTap,
    );
  }
}
