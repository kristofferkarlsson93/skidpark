import 'dart:math' as math;

import '../models/calculated_position.dart';

class RunAligner {
  /// Aligns a list of runs horizontally (by distance) so they overlap perfectly
  /// during the acceleration phase.
  ///
  /// [runs]: A list of runs, where each run is a list of CalculatedPosition.
  /// Returns a new list of runs with adjusted 'distanceTraveled'.
  /// -------------- TEMPORARY DISABLED ------------------
  static List<List<CalculatedPosition>> alignMultipleRuns({
    required List<List<CalculatedPosition>> runs,
  }) {
    if (runs.length < 2) return runs;
    final inputs = runs
        .map((inner) => inner.map((i) => i.distanceTraveled).toList())
        .toList();
    print(inputs);

    // 1. DETERMINE TARGET SPEED (DYNAMICALLY)
    // We want to align at a speed that ALL runs actually reached.
    // Strategy: Find the max speed of the SLOWEST run (the bottleneck).

    double minMaxSpeed = double.infinity;

    for (final run in runs) {
      if (run.isEmpty) continue;
      // Find max speed for this specific run
      final maxS = run.map((p) => p.speed).reduce(math.max);
      if (maxS < minMaxSpeed) {
        minMaxSpeed = maxS;
      }
    }

    // Safety check: If data is bad (max speed < 1 m/s), don't align.
    if (minMaxSpeed == double.infinity || minMaxSpeed < 1.0) return runs;

    // Target = 60% of the bottleneck speed.
    // This is usually right in the middle of the acceleration phase (steep curve),
    // which gives the highest precision for alignment.
    final double targetSpeedMs = minMaxSpeed * 0.60;
    print("target speed $targetSpeedMs");

    // 2. FIND MASTER REFERENCE
    // We use the first run in the list as the "Master" (Anchor).
    // We will shift all other runs to match this one.
    final masterRun = runs[0];
    final double? masterDistAtSpeed = _findDistanceAtRisingEdge(
      masterRun,
      targetSpeedMs,
    );

    // If master somehow missed the target, we can't align. Return original.
    if (masterDistAtSpeed == null) return runs;

    List<List<CalculatedPosition>> alignedRuns = [];
    alignedRuns.add(masterRun); // Add master untouched

    // 3. ALIGN THE REST (CHALLENGERS)
    for (int i = 1; i < runs.length; i++) {
      final challengerRun = runs[i];

      final double? challengerDistAtSpeed = _findDistanceAtRisingEdge(
        challengerRun,
        targetSpeedMs,
      );

      if (challengerDistAtSpeed == null) {
        // This run failed to reach target speed (data error?). Keep as is.
        alignedRuns.add(challengerRun);
        continue;
      }

      // Calculate Offset
      // Example: Master hit 12km/h at 10m. Challenger at 12m.
      // Offset = 10 - 12 = -2m. (Shift Challenger back by 2m).
      final double offset = masterDistAtSpeed - challengerDistAtSpeed;

      // Apply offset to every point in the run
      final shiftedRun = challengerRun.map((p) {
        return CalculatedPosition(
          p.speed,
          p.timestamp,
          p.distanceTraveled + offset, // Apply shift here
        );
      }).toList();

      alignedRuns.add(shiftedRun);
    }

    print("-------------------------------------------");
    print(
      alignedRuns
          .map((w) => w.map((s) => s.distanceTraveled).toList())
          .toList(),
    );

    return alignedRuns;
  }

  /// Helper: Finds the exact interpolated distance where the curve crosses
  /// [targetMs] during the ACCELERATION phase (Rising Edge).
  static double? _findDistanceAtRisingEdge(
    List<CalculatedPosition> points,
    double targetMs,
  ) {
    if (points.isEmpty) return null;

    // Find index of max speed to ensure we only search during acceleration,
    // avoiding false positives during deceleration (braking).
    double maxS = 0;
    int maxIndex = 0;
    for (int i = 0; i < points.length; i++) {
      if (points[i].speed > maxS) {
        maxS = points[i].speed;
        maxIndex = i;
      }
    }

    // Scan forward to find the crossing point
    for (int i = 0; i < maxIndex; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Check if target lies between p1 and p2
      if (p1.speed <= targetMs && p2.speed >= targetMs) {
        // Prevent division by zero if speeds are identical
        if ((p2.speed - p1.speed).abs() < 0.0001) return p1.distanceTraveled;

        // Linear Interpolation (Lerp) to find exact sub-meter distance.
        // If p1 is at 10m (10km/h) and p2 is at 12m (14km/h), and target is 12km/h:
        // Fraction is 0.5. Result is 11m.
        final fraction = (targetMs - p1.speed) / (p2.speed - p1.speed);
        final distDiff = p2.distanceTraveled - p1.distanceTraveled;

        return p1.distanceTraveled + (distDiff * fraction);
      }
    }
    return null;
  }
}
