import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/compare/services/run_data_processor.dart';

void main() {
  test('turns a stationary-moving-stationary GPS trace into a graph line', () {
    final startedAt = DateTime.utc(2026, 1, 1, 10);
    final positions = <Position>[
      _position(startedAt, longitude: 18.06860, speed: 0),
      _position(
        startedAt.add(const Duration(seconds: 1)),
        longitude: 18.06860,
        speed: 0,
      ),
      _position(
        startedAt.add(const Duration(seconds: 2)),
        longitude: 18.06865,
        speed: 2,
      ),
      _position(
        startedAt.add(const Duration(seconds: 3)),
        longitude: 18.06875,
        speed: 4,
      ),
      _position(
        startedAt.add(const Duration(seconds: 4)),
        longitude: 18.06885,
        speed: 3,
      ),
      _position(
        startedAt.add(const Duration(seconds: 5)),
        longitude: 18.06890,
        speed: 0,
      ),
      _position(
        startedAt.add(const Duration(seconds: 6)),
        longitude: 18.06890,
        speed: 0,
      ),
    ];

    final result = RunDataProcessor.processRun(rawPositions: positions);

    expect(result, isNotEmpty);
    expect(result.first.distanceTraveled, 0);
    expect(result.last.distanceTraveled, greaterThanOrEqualTo(8));
    expect(
      result.map((point) => point.speed).reduce((a, b) => a > b ? a : b),
      4,
    );
  });
}

Position _position(
  DateTime timestamp, {
  required double longitude,
  required double speed,
}) {
  return Position(
    longitude: longitude,
    latitude: 59.32930,
    timestamp: timestamp,
    accuracy: 3,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: speed,
    speedAccuracy: 0.1,
  );
}
