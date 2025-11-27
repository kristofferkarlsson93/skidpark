import 'package:geolocator/geolocator.dart';
import '../models/calculated_position.dart';

class RunDataProcessor {
  // Constants for trimming
  static const double _triggerSpeedMs = 0.8; // ~3 km/h
  static const double _staticSpeedThresholdMs = 0.1; // Almost standing still

  /// Main entry point. Takes raw GPS positions and performs all processing steps:
  /// 1. Calculate raw cumulative distance.
  /// 2. Auto-trim the start and reset distance to 0.
  /// 3. Resample to fixed distance intervals.
  static List<CalculatedPosition> processRun({
    required List<Position> rawPositions,
    double resampleIntervalMeters = 2.0,
  }) {
    if (rawPositions.length < 2) return [];

    final rawCalculated = _calculateRawCumulativeDistance(rawPositions);
    final trimmedPositions = _trimStartOfRun(rawCalculated);

    if (trimmedPositions.isEmpty) return [];

    return _resampleByDistance(trimmedPositions, resampleIntervalMeters);
  }

  static double calculateAverageSpeed(List<CalculatedPosition> positions) {
    if (positions.isEmpty) return 0.0;
    final totalSpeed = positions.fold(0.0, (sum, pos) => sum + pos.speed);
    return totalSpeed / positions.length;
  }

  static double calculateMaxSpeed(List<Position> positions) {
    if (positions.isEmpty) return 0.0;
    return (positions.map((pos) => pos.speed).reduce((a, b) => a > b ? a : b));
  }

  /// Converts raw Position objects into CalculatedPosition objects,
  /// calculating the initial cumulative distance.
  static List<CalculatedPosition> _calculateRawCumulativeDistance(
    List<Position> rawPositions,
  ) {
    if (rawPositions.isEmpty) return [];

    List<CalculatedPosition> result = [];
    var totalDistance = 0.0;

    // Add the first point manually (distance 0)
    result.add(
      CalculatedPosition(rawPositions[0].speed, rawPositions[0].timestamp, 0.0),
    );

    for (int i = 1; i < rawPositions.length; i++) {
      final prev = rawPositions[i - 1];
      final curr = rawPositions[i];

      final distanceDelta = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      totalDistance += distanceDelta;

      result.add(CalculatedPosition(curr.speed, curr.timestamp, totalDistance));
    }
    return result;
  }

  /// Finds the actual run start, slices the list, and functionally resets
  /// the distance counter so the first point is 0.0 meters.
  static List<CalculatedPosition> _trimStartOfRun(
    List<CalculatedPosition> calculatedPositions,
  ) {
    final triggerIndex = calculatedPositions.indexWhere(
      (p) => p.speed > _triggerSpeedMs,
    );

    if (triggerIndex == -1) {
      return []; // No movement detected
    }

    final startIndex = _backTrackToActualStart(
      calculatedPositions,
      triggerIndex,
    );

    // Calculate the distance offset BEFORE slicing
    final double startOffset = calculatedPositions[startIndex].distanceTraveled;

    // Slice the list to remove pre-run messing around time
    final rawSliced = calculatedPositions.sublist(startIndex);

    // removing the distance collected before the run started, on each data point
    return rawSliced.map((p) {
      return CalculatedPosition(
        p.speed,
        p.timestamp,
        p.distanceTraveled - startOffset, // Reset distance to start at 0
      );
    }).toList();
  }

  static int _backTrackToActualStart(
    List<CalculatedPosition> positions,
    int triggerIndex,
  ) {
    for (int i = triggerIndex; i >= 0; i--) {
      if (positions[i].speed < _staticSpeedThresholdMs) {
        return i;
      }
    }
    return 0;
  }

  // Create points at specific distances, so that all runs will have the same points.
  static List<CalculatedPosition> _resampleByDistance(
    List<CalculatedPosition> input,
    double interval,
  ) {
    if (input.isEmpty) return [];

    List<CalculatedPosition> output = [];
    final maxDistance = input.last.distanceTraveled;

    for (
      double targetDist = 0;
      targetDist <= maxDistance;
      targetDist += interval
    ) {
      final interpolatedPoint = _createPointAtDistance(input, targetDist);
      if (interpolatedPoint != null) {
        output.add(interpolatedPoint);
      }
    }

    return output;
  }

  static CalculatedPosition? _createPointAtDistance(
    List<CalculatedPosition> input,
    double targetDist,
  ) {
    final afterIndex = input.indexWhere(
      (p) => p.distanceTraveled >= targetDist,
    );

    if (afterIndex == -1) return null;
    if (afterIndex == 0) return input.first;

    final pBefore = input[afterIndex - 1];
    final pAfter = input[afterIndex];

    return _interpolateBetween(pBefore, pAfter, targetDist);
  }

  static CalculatedPosition _interpolateBetween(
    CalculatedPosition pBefore,
    CalculatedPosition pAfter,
    double targetDist,
  ) {
    final segmentLength = pAfter.distanceTraveled - pBefore.distanceTraveled;

    if (segmentLength <= 0.0001) {
      return pAfter;
    }

    // Where between the 2 points should the new be added. Example: at 30% of the distance
    final fraction = (targetDist - pBefore.distanceTraveled) / segmentLength;

    final interpolatedSpeed =
        pBefore.speed + (pAfter.speed - pBefore.speed) * fraction;

    final timeDiffMs = pAfter.timestamp
        .difference(pBefore.timestamp)
        .inMilliseconds;
    final interpolatedTime = pBefore.timestamp.add(
      Duration(milliseconds: (timeDiffMs * fraction).round()),
    );

    return CalculatedPosition(interpolatedSpeed, interpolatedTime, targetDist);
  }
}
