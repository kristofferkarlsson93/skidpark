import 'dart:math' as math;
import '../models/calculated_position.dart';
import '../models/enriched_test_run.dart';

class ReleasePointAnalysis {

  // Öka fönstret något eftersom du har interpolering varannan meter.
  // +/- 4 meter ger oss ca 4-5 punkter att snitta på. Det blir stabilare.
  static const double _samplingWindowRadius = 4.0;

  static List<EnrichedTestRun> performAnalysis({
    required List<EnrichedTestRun> testRuns,
    required double releasePoint,
  }) {
    if (testRuns.isEmpty) return [];

    // 1. Calculate smoothed start speeds (Stable "Truth").
    final Map<int, double> smoothedStartSpeeds = {};

    for (var run in testRuns) {
      final double? avgSpeed = _getAverageSpeedAround(
          run.positionData,
          releasePoint,
          _samplingWindowRadius
      );
      if (avgSpeed != null) {
        smoothedStartSpeeds[run.id] = avgSpeed;
      }
    }

    if (smoothedStartSpeeds.isEmpty) return [];

    // 2. Determine target speed (max of the smoothed averages).
    final double targetSpeed = smoothedStartSpeeds.values.reduce(math.max);

    List<EnrichedTestRun> analyzedRuns = [];

    for (var run in testRuns) {
      if (!smoothedStartSpeeds.containsKey(run.id)) continue;

      final CalculatedPosition? firstPoint = run.positionData
          .cast<CalculatedPosition?>()
          .firstWhere(
            (p) => p != null && p.distanceTraveled >= releasePoint,
        orElse: () => null,
      );

      if (firstPoint == null) continue;

      final double smoothedSpeed = smoothedStartSpeeds[run.id]!;

      // Safety check
      if (smoothedSpeed < 0.1) continue;

      final double scalingFactor = targetSpeed / smoothedSpeed;

      final List<CalculatedPosition> newPositions = [];

      final double projectedStartSpeed = firstPoint.speed * scalingFactor;

      final double cosmeticCorrection = targetSpeed - projectedStartSpeed;

      for (var p in run.positionData) {
        if (p.distanceTraveled < releasePoint) continue;

        double newSpeed = (p.speed * scalingFactor) + cosmeticCorrection;

        if(newSpeed < 0) newSpeed = 0;

        newPositions.add(
          CalculatedPosition(
            newSpeed,
            p.timestamp,
            p.distanceTraveled - releasePoint,
          ),
        );
      }

      if (newPositions.isEmpty) continue;

      // Stats calculation...
      final double newDistance = newPositions.last.distanceTraveled;
      final double newMaxSpeed = newPositions.map((p) => p.speed).reduce(math.max);
      final double newAvgSpeed = newPositions.map((p) => p.speed).fold(0.0, (a, b) => a + b) / newPositions.length;

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

  static double? _getAverageSpeedAround(
      List<CalculatedPosition> positions,
      double center,
      double radius
      ) {
    final double startDist = center - radius;
    final double endDist = center + radius;

    final pointsInWindow = positions.where(
            (p) => p.distanceTraveled >= startDist && p.distanceTraveled <= endDist
    ).toList();

    if (pointsInWindow.isEmpty) return null;

    final double totalSpeed = pointsInWindow.fold(0.0, (sum, p) => sum + p.speed);
    return totalSpeed / pointsInWindow.length;
  }

  static double _msToKmh(double ms) {
    return ms * 3.6;
  }
}