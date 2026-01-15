import 'dart:math' as math;
import 'package:skidpark/common/utils/color_utils.dart';

import '../models/calculated_position.dart';
import '../models/enriched_test_run.dart';

class AveragePerSkiCalculator {
  static const double _snapToZeroThresholdMs = 0.8; // ~ 2.8 km/h

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

          // 1. Calculate Average Distance
          final double sumDist = runs.fold(
            0.0,
            (sum, r) => sum + r.traveledDistance,
          );
          final double avgTotalDistance = sumDist / runs.length;

          // Infer interval
          final double interval = template.positionData.length > 1
              ? template.positionData[1].distanceTraveled -
                    template.positionData[0].distanceTraveled
              : 2.0;

          final int steps = (avgTotalDistance / interval).floor();

          final avgPositions = List.generate(steps + 1, (index) {
            final currentDist = index * interval;

            // Safety break if we drifted past avg distance
            if (currentDist > avgTotalDistance) return null;

            double sumSpeed = 0.0;

            for (var run in runs) {
              if (currentDist <= run.traveledDistance &&
                  index < run.positionData.length) {
                final point = run.positionData[index];
                if ((point.distanceTraveled - currentDist).abs() < 0.1) {
                  sumSpeed += point.speed;
                } else {
                  sumSpeed += 0.0;
                }
              } else {
                // Run ended -> 0.0
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

          // Check the speed of the very last calculated point.
          final lastPoint = avgPositions.last;

          // Only force to 0.0 if we are moving slowly (natural stop).
          // If we are moving fast, let the graph end "in mid air" to show manual cutoff.
          if (lastPoint.speed < _snapToZeroThresholdMs) {
            if (lastPoint.distanceTraveled < avgTotalDistance) {
              // If there is a small gap to the exact average distance, add a 0-point there.
              avgPositions.add(
                CalculatedPosition(0.0, DateTime.now(), avgTotalDistance),
              );
            } else {
              // If we landed exactly on the limit, force the last point to 0.0
              // (This cleans up micro-speeds like 0.05 km/h)
              avgPositions[avgPositions.length - 1] = CalculatedPosition(
                0.0,
                lastPoint.timestamp,
                lastPoint.distanceTraveled,
              );
            }
          }

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
            -template.skiId,
            template.startedAt,
            template.skiId,
            template.glideTestId,
            avgSeconds.round(),
            newTotalDist,
            newAvgSpeedMs * 3.6,
            newMaxSpeedMs * 3.6,
            template.skiName,
            avgPositions,
            runs.length, // OMG this is so hacky. Run number to indicate how many runs thee is in this ski.
          );

          averagedRun.setColor(
            getSafeColor(template.skiId),
          );
          return averagedRun;
        })
        .whereType<EnrichedTestRun>()
        .toList();
  }
}
