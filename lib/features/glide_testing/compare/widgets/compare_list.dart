import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';

import 'run_metric.dart';

class CompareList extends StatelessWidget {
  final List<EnrichedTestRun> runs;

  const CompareList({super.key, required this.runs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: runs.length,
      itemBuilder: (context, index) {
        final run = runs[index];
        double runDistance = run.traveledDistance;
        String distanceUnit = "m";
        if (run.traveledDistance >= 1000) {
          runDistance = run.traveledDistance / 1000;
          distanceUnit = "km";
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: run.runColor, size: 28),
                    SizedBox(width: 16),
                    Text(
                      'Åk ${run.runNumber} - ${run.skiName}',
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: RunMetrics(
                        label: 'Med.',
                        value: run.averageSpeed.toStringAsFixed(2),
                        unit: 'km/h',
                        size: RunMetricsSize.large,
                        color: theme.colorScheme.primary
                      ),
                    ),
                    Expanded(
                      child: RunMetrics(
                        label: 'Max.',
                        value: run.maxSpeed.toStringAsFixed(2),
                        unit: 'km/h',
                        size: RunMetricsSize.large,
                      ),
                    ),
                    Expanded(
                      child: RunMetrics(
                        label: 'Dist.',
                        value: runDistance.toStringAsFixed(2),
                        unit: distanceUnit,
                      ),
                    ),
                    Expanded(
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
