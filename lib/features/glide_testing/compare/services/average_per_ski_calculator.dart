import 'dart:math' as math;
import 'package:skidpark/common/utils/color_utils.dart';

import '../models/calculated_position.dart';
import '../models/enriched_test_run.dart';

class AveragePerSkiCalculator {
  // Threshold to determine if the source runs came to a natural stop (approx 1.8 km/h).
  static const double _naturalStopThresholdMs = 0.5;

  static List<EnrichedTestRun> calculateAveragedRuns(
    List<EnrichedTestRun> sourceRuns,
  ) {
    if (sourceRuns.isEmpty) return [];

    final runsBySki = sourceRuns.fold<Map<int, List<EnrichedTestRun>>>({}, (
      map,
      run,
    ) {
      map.putIfAbsent(run.skiId, () => []).add(run);
      return map;
    });

    return runsBySki.values
        .map((List<EnrichedTestRun> runs) {
          final template = runs.first;

          // 1. Calculate Average Distance (The target finish line)
          final double sumDist = runs.fold(
            0.0,
            (sum, r) => sum + r.traveledDistance,
          );
          final double avgTotalDistance = sumDist / runs.length;

          // 2. Analyze Source Data
          // Check if the runs effectively stopped. If the average end speed
          // is low, we assume a natural stop and will force the curve to 0.0.
          final double avgSourceEndSpeed =
              runs.fold(
                0.0,
                (sum, r) =>
                    sum +
                    (r.positionData.isNotEmpty
                        ? r.positionData.last.speed
                        : 0.0),
              ) /
              runs.length;

          final bool shouldForceStop =
              avgSourceEndSpeed < _naturalStopThresholdMs;

          // Infer sampling interval from the first run
          final double interval = template.positionData.length > 1
              ? template.positionData[1].distanceTraveled -
                    template.positionData[0].distanceTraveled
              : 2.0;

          final int steps = (avgTotalDistance / interval).floor();

          // Generate averaged data points
          final avgPositions = List.generate(steps + 1, (index) {
            final currentDist = index * interval;

            // Guard against float precision errors drifting past limit
            if (currentDist > avgTotalDistance) return null;

            double sumSpeed = 0.0;

            for (var run in runs) {
              if (currentDist <= run.traveledDistance &&
                  index < run.positionData.length) {
                final point = run.positionData[index];
                // Check for grid alignment
                if ((point.distanceTraveled - currentDist).abs() < 0.1) {
                  sumSpeed += point.speed;
                } else {
                  // Grid misalignment fallback (treat as 0.0)
                  sumSpeed += 0.0;
                }
              } else {
                // Run ended early -> contributes 0.0 speed (Drag effect)
                sumSpeed += 0.0;
              }
            }

            return CalculatedPosition(
              sumSpeed / runs.length,
              DateTime.now(),
              currentDist,
            );
          }).whereType<CalculatedPosition>().toList();

          if (avgPositions.isEmpty) return null;

          // 3. Apply Forced Stop Logic
          if (shouldForceStop) {
            final lastCalculated = avgPositions.last;

            if (lastCalculated.distanceTraveled < avgTotalDistance) {
              // Append a final point at exact average distance
              avgPositions.add(
                CalculatedPosition(0.0, DateTime.now(), avgTotalDistance),
              );
            } else {
              // Snap the last point to 0.0 if it landed exactly on the limit
              avgPositions[avgPositions.length - 1] = CalculatedPosition(
                0.0,
                lastCalculated.timestamp,
                avgTotalDistance,
              );
            }
          }

          // Recalculate stats for the averaged run
          final newTotalDist = avgPositions.last.distanceTraveled;
          final newMaxSpeedMs = avgPositions
              .map((p) => p.speed)
              .reduce(math.max);
          final newAvgSpeedMs =
              avgPositions.map((p) => p.speed).reduce((a, b) => a + b) /
              avgPositions.length;

          final double avgSeconds =
              runs.fold(0, (sum, run) => sum + run.elapsedSeconds) /
              runs.length;

          final averagedRun = EnrichedTestRun(
            -template.skiId, // Negative ID to indicate virtual run
            template.startedAt,
            template.skiId,
            template.glideTestId,
            avgSeconds.round(),
            newTotalDist,
            newAvgSpeedMs * 3.6,
            newMaxSpeedMs * 3.6,
            template.skiName,
            avgPositions,
            runs.length,
          );

          averagedRun.setColor(getSafeAverageColor(template.skiId));
          return averagedRun;
        })
        .whereType<EnrichedTestRun>()
        .toList();
  }
}
