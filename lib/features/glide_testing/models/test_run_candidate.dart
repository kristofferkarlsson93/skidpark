import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_barometer_event.dart';

class TestRunCandidate {
  final DateTime startedAt;
  final int skiId;
  final int glideTestId;
  final int elapsedSeconds;
  final List<Position> gpsData;
  final List<RawAccelerometerEvent> accelerometerEvents;
  final List<RawBarometerEvent> barometerEvents;

  TestRunCandidate({
    required this.startedAt,
    required this.skiId,
    required this.glideTestId,
    required this.elapsedSeconds,
    required this.gpsData,
    required this.accelerometerEvents,
    required this.barometerEvents,
  });
}
