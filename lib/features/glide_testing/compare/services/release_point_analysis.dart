import 'dart:math' as math;
import '../models/calculated_position.dart';
import '../models/enriched_test_run.dart';

class ReleasePointAnalysis {
  /// Aligns all runs to start at [releasePoint] with the same velocity
  /// using MULTIPLICATION (Scaling).
  ///
  /// This scales the entire speed curve relative to the target speed.
  /// If a skier starts 10% slower, this method assumes they would act
  /// 10% "larger" throughout the run, effectively scaling up their curve.
  static List<EnrichedTestRun> performAnalysis({
    required List<EnrichedTestRun> testRuns,
    required double releasePoint,
  }) {
    if (testRuns.isEmpty) return [];

    // 1. Identify speed for each run at the release point.
    final Map<int, double> startSpeeds = {};

    for (var run in testRuns) {
      final CalculatedPosition? match = run.positionData
          .cast<CalculatedPosition?>()
          .firstWhere(
            (p) => p != null && p.distanceTraveled >= releasePoint,
        orElse: () => null,
      );

      if (match != null) {
        startSpeeds[run.id] = match.speed;
      }
    }

    if (startSpeeds.isEmpty) return [];

    // 2. Determine target speed (max speed among runs at this point).
    final double targetSpeed = startSpeeds.values.reduce(math.max);

    List<EnrichedTestRun> analyzedRuns = [];

    for (var run in testRuns) {
      if (!startSpeeds.containsKey(run.id)) continue;

      final double originalSpeedAtStart = startSpeeds[run.id]!;

      // Calculate the SCALING FACTOR instead of offset.
      // Example: Target 25, Start 20. Factor = 1.25.
      // We multiply every point in the curve by 1.25.
      // Safety check: Avoid division by zero.
      final double speedFactor = originalSpeedAtStart > 0.01
          ? targetSpeed / originalSpeedAtStart
          : 1.0;

      // 3. Create new positions with SCALED speed and reset distance.
      final List<CalculatedPosition> newPositions = [];

      for (var p in run.positionData) {
        if (p.distanceTraveled < releasePoint) continue;

        newPositions.add(
          CalculatedPosition(
            p.speed * speedFactor, // <--- MULTIPLICATION HERE
            p.timestamp,
            p.distanceTraveled - releasePoint,
          ),
        );
      }

      if (newPositions.isEmpty) continue;

      // 4. Calculate stats for this specific segment.
      final double newDistance = newPositions.last.distanceTraveled;
      final double newMaxSpeed = newPositions
          .map((p) => p.speed)
          .reduce(math.max);
      final double newAvgSpeed =
          newPositions.map((p) => p.speed).fold(0.0, (a, b) => a + b) /
              newPositions.length;

      analyzedRuns.add(
        EnrichedTestRun(
          run.id,
          run.startedAt,
          run.skiId,
          run.glideTestId,
          run.elapsedSeconds,
          newDistance,
          _msToKmh(newAvgSpeed),
          _msToKmh(newMaxSpeed),
          run.skiName,
          newPositions,
          run.runNumber,
        ),
      );
    }

    return analyzedRuns;
  }

  static double _msToKmh(double ms) {
    return ms * 3.6;
  }
}