import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';

import 'run_metric.dart';

class CompareList extends StatelessWidget {
  final List<EnrichedTestRun> runs;
  final bool isAverageView;
  final int? highlightedRunId;
  final Function(int) onRunTapped;

  const CompareList({
    super.key,
    required this.runs,
    required this.isAverageView,
    required this.onRunTapped,
    this.highlightedRunId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 80),
      itemCount: runs.length,
      itemBuilder: (context, index) {
        final run = runs[index];

        double runDistance = run.traveledDistance;
        String distanceUnit = "m";
        if (run.traveledDistance >= 1000) {
          runDistance = run.traveledDistance / 1000;
          distanceUnit = "km";
        }

        final title = isAverageView
            ? '${run.skiName} (${run.runNumber} åk)'
            : 'Åk ${run.runNumber} - ${run.skiName}';

        final isHighlighted = highlightedRunId == run.id;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isHighlighted
                  ? run.runColor
                  : theme.colorScheme.outlineVariant.withAlpha(
                      (0.3 * 255).toInt(),
                    ),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => onRunTapped(run.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: run.runColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RunMetrics(
                        label: 'Med.',
                        value: run.averageSpeedKmh.toStringAsFixed(1),
                        size: RunMetricsSize.large,
                        unit: 'km/h',
                      ),
                      RunMetrics(
                        label: 'Max.',
                        size: RunMetricsSize.large,
                        value: run.maxSpeedKmh.toStringAsFixed(1),
                        unit: 'km/h',
                      ),
                      RunMetrics(
                        label: 'Dist.',
                        value: runDistance.toStringAsFixed(0),
                        unit: distanceUnit,
                      ),
                      RunMetrics(
                        label: 'Tid',
                        value: run.elapsedSeconds.toString(),
                        unit: 's',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
