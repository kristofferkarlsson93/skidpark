import '../models/calculated_position.dart';
import '../../test_runs/models/raw_barometer_event.dart';

class AltitudePoint {
  final double distanceTraveled;
  final double relativeAltitude;

  AltitudePoint(this.distanceTraveled, this.relativeAltitude);
}

/// Generates an altitude profile for a run by mapping each processed position
/// to a relative altitude, calculated from barometric pressure data.
/// The altitude is estimated using the difference in pressure from the start,
/// applying the standard approximation of 8.3 meters per hPa.
/// Returns a list of AltitudePoint objects, each containing the distance traveled
/// and the corresponding relative altitude.

class AltitudeProfileCalculator {
  static List<AltitudePoint> generateProfile({
    required List<CalculatedPosition> processedPositions,
    required List<RawBarometerEvent>? barometerEvents,
  }) {
    if (barometerEvents == null ||
        barometerEvents.isEmpty ||
        processedPositions.isEmpty) {
      return [];
    }

    final double startPressure = barometerEvents.first.pressure;
    List<AltitudePoint> profile = [];
    int barometerIndex = 0;

    for (var pos in processedPositions) {
      // Forward to starting point. Positions has been resampled when we run this code
      while (barometerIndex < barometerEvents.length - 1 &&
          barometerEvents[barometerIndex + 1].timestamp.isBefore(
            pos.timestamp,
          )) {
        barometerIndex++;
      }

      final currentPressure = barometerEvents[barometerIndex].pressure;

      // 8.3 is how many meters of fall 1 hPa represents at sea level. For the current purpose it does not mean so much since we only want an altitude profile.
      final altitude = (startPressure - currentPressure) * 8.3;

      profile.add(AltitudePoint(pos.distanceTraveled, altitude));
    }

    return profile;
  }
}
