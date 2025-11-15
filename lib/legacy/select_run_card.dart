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
    return Card(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
          : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.circle : Icons.circle_outlined,
          color: isSelected
              ? testRun.runColor
              : testRun.runColor.withValues(alpha: 0.2),
        ),
        title: Text("Åk $runNumber - ${testRun.skiName}"),
        subtitle: Text("Varaktighet: ${testRun.elapsedSeconds} sekunder"),
        trailing: Text("${testRun.positionData.length} datapunkter"),
        onTap: onTap,
      ),
    );
  }
}
