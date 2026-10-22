import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_barometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gps_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gyroscope_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_rotation_vector_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/sensor_recording_metadata.dart';

class DecodedTestRun {
  final int id;
  final DateTime startedAt;
  final int skiId;
  final int glideTestId;
  final int runNumber;
  final int elapsedSeconds;
  final String skiName;
  final List<RawGpsEvent> gpsEvents;
  final List<RawAccelerometerEvent> accelerometerEvents;
  final List<RawGyroscopeEvent> gyroscopeEvents;
  final List<RawBarometerEvent> barometerEvents;
  final List<RawRotationVectorEvent> rotationVectorEvents;
  final SensorRecordingMetadata? sensorMetadata;

  DecodedTestRun({
    required this.id,
    required this.startedAt,
    required this.skiId,
    required this.glideTestId,
    required this.runNumber,
    required this.elapsedSeconds,
    required this.skiName,
    required this.gpsEvents,
    required this.accelerometerEvents,
    required this.gyroscopeEvents,
    required this.barometerEvents,
    required this.rotationVectorEvents,
    required this.sensorMetadata,
  });

  List<Position> get gpsData =>
      gpsEvents.map((event) => event.position).toList(growable: false);
}
