import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';

class DecodedTestRun {
  final int id;
  final DateTime startedAt;
  final int skiId;
  final int glideTestId;
  final int elapsedSeconds;
  final String skiName;
  final List<Position> gpsData;
  final List<RawAccelerometerEvent> accelerometerEvents;

  DecodedTestRun(
    this.id,
    this.startedAt,
    this.skiId,
    this.glideTestId,
    this.elapsedSeconds,
    this.skiName,
    this.gpsData,
    this.accelerometerEvents,
  );
}
