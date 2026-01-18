
import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';

import 'run_metric.dart';

class CompareList extends StatelessWidget {
  final List<EnrichedTestRun> runs;
  final bool isAverageView;

  const CompareList({
    super.key,
    required this.runs,
    required this.isAverageView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 24, 0, 64),
      itemCount: runs.length,
      itemBuilder: (context, index) {
        final run = runs[index];
        double runDistance = run.traveledDistance;
        String distanceUnit = "m";
        if (run.traveledDistance >= 1000) {
          runDistance = run.traveledDistance / 1000;
          distanceUnit = "km";
        }
        var title = isAverageView
            ? '${run.skiName} (${run.runNumber} åk)'
            : 'Åk ${run.runNumber} - ${run.skiName}';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: run.runColor, size: 28),
                    SizedBox(width: 16),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 3,
                      child: RunMetrics(
                        label: 'Med.',
                        value: run.averageSpeedKmh.toStringAsFixed(2),
                        unit: 'km/h',
                        size: RunMetricsSize.large,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: RunMetrics(
                        label: 'Max.',
                        value: run.maxSpeedKmh.toStringAsFixed(2),
                        unit: 'km/h',
                        size: RunMetricsSize.large,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: RunMetrics(
                        label: 'Dist.',
                        value: runDistance.toStringAsFixed(1),
                        unit: distanceUnit,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: RunMetrics(
                        label: 'Tid',
                        value: run.elapsedSeconds.toString(),
                        unit: 's',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
