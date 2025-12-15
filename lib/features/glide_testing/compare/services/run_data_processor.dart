import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/compare/services/speed_kalman_filter.dart';
import '../../test_runs/models/raw_accelerometer_event.dart';
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
    List<RawAccelerometerEvent>? accelerometerReadings,
    double resampleIntervalMeters = 2.0,
    bool useSensorFusion = false
  }) {
    if (rawPositions.length < 2) return [];

    List<Position> processedPositions = rawPositions;

    if (useSensorFusion && accelerometerReadings != null && accelerometerReadings.isNotEmpty) {
      processedPositions = _fuseGpsAndAccel(rawPositions, accelerometerReadings);
    }

    final rawCalculated = _calculateRawCumulativeDistance(processedPositions);
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

  /// This method "replays" the run chronologically to combine GPS and Accelerometer data.
  /// It uses a Kalman Filter to smooth out the speed curve, but ignores accelerometer
  /// data when the speed is below the trigger threshold (to avoid handling noise).
  static List<Position> _fuseGpsAndAccel(
      List<Position> gpsPositions,
      List<RawAccelerometerEvent> accelReadings,
      ) {
    // 1. Sort lists by time to ensure chronological playback
    gpsPositions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    accelReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    List<Position> fusedGpsPoints = [];
    int accelIndex = 0;

    // We keep the filter nullable so we can initialize it only when the run actually starts
    SpeedKalmanFilter? filter;

    // 2. Iterate through every GPS point (The "Main" timeline)
    for (int i = 0; i < gpsPositions.length; i++) {
      final currentGpsPoint = gpsPositions[i];

      // --- GATEKEEPER LOGIC ---
      // If we haven't reached the trigger speed yet, we assume the user is still
      // handling the phone or standing still. We trust ONLY the GPS here to avoid
      // massive acceleration spikes from moving the phone into position.
      if (currentGpsPoint.speed < _triggerSpeedMs) {
        // Add the raw GPS point without filtering
        fusedGpsPoints.add(currentGpsPoint);

        // Discard all accelerometer events that happened up to this point
        // since they are likely just noise/handling artifacts.
        while (accelIndex < accelReadings.length &&
            accelReadings[accelIndex].timestamp.isBefore(currentGpsPoint.timestamp)) {
          accelIndex++;
        }
        // Move to the next GPS point
        continue;
      }

      // --- ACTIVE RUN LOGIC ---

      // If this is the first point above the threshold, initialize the filter now.
      filter ??= SpeedKalmanFilter(initialSpeed: currentGpsPoint.speed);

      // 3. "Catch up" with all accelerometer events that happened BEFORE this GPS point
      while (accelIndex < accelReadings.length &&
          accelReadings[accelIndex].timestamp.isBefore(currentGpsPoint.timestamp)) {

        final currentAccelEvent = accelReadings[accelIndex];

        // Calculate time passed since the previous accelerometer event (dt)
        // Default to a small value (e.g., 0.02s for 50Hz) if it's the first point
        double timeDeltaSeconds = 0.02;

        if (accelIndex > 0) {
          final previousAccelTime = accelReadings[accelIndex - 1].timestamp;
          // Convert microseconds to seconds
          timeDeltaSeconds = currentAccelEvent.timestamp.difference(previousAccelTime).inMicroseconds / 1000000.0;
        }

        // PREDICT: Tell the filter how the speed changed based on force (Y-axis)
        // Assumption: Y-axis is pointing forward.
        filter.predict(
          accelerationY: currentAccelEvent.y,
          secondsSinceLastUpdate: timeDeltaSeconds,
        );

        accelIndex++;
      }

      // 4. UPDATE: Now that we have caught up to the current time,
      // correct the prediction using the actual GPS speed.
      filter.update(currentGpsPoint.speed);

      // 5. Store the result
      // We create a new Position object that is identical to the GPS point,
      // BUT we replace the 'speed' with our new filtered speed.
      fusedGpsPoints.add(Position(
        longitude: currentGpsPoint.longitude,
        latitude: currentGpsPoint.latitude,
        timestamp: currentGpsPoint.timestamp,
        accuracy: currentGpsPoint.accuracy,
        altitude: currentGpsPoint.altitude,
        altitudeAccuracy: currentGpsPoint.altitudeAccuracy,
        heading: currentGpsPoint.heading,
        headingAccuracy: currentGpsPoint.headingAccuracy,
        speed: filter.speed, // <--- This is the smoothed value
        speedAccuracy: currentGpsPoint.speedAccuracy,
      ));
    }

    return fusedGpsPoints;
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
