import 'dart:async';

import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/device_sensor_source.dart';

void main() {
  test('records all motion streams on one run-relative timeline', () async {
    final source = _FakeDeviceSensorSource();
    final recorder = DataRecorder(sensorSource: source);
    addTearDown(() async {
      await recorder.close();
      await source.close();
    });
    final timestamp = DateTime.utc(2026, 9, 17, 12);

    recorder.startRecording();
    source.userAccelerometer.add(UserAccelerometerEvent(1, 2, 3, timestamp));
    recorder.startRecording();
    source.gyroscope.add(GyroscopeEvent(4, 5, 6, timestamp));
    source.barometer.add(BarometerEvent(1000, timestamp));
    source.rotationVector.add(
      OrientationEvent(
        quaternion: Quaternion(0, 0, 0, 1),
        accuracy: 0.2,
        timestamp: 1000000,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    recorder.stopRecording();

    expect(recorder.recordedAccelerometerEvents.single.x, 1);
    expect(recorder.recordedGyroscopeEvents.single.y, 5);
    expect(recorder.recordedBarometerEvents.single.pressureHpa, 1000);
    expect(recorder.recordedRotationVectorEvents.single.w, 1);
    expect(
      recorder.recordedRotationVectorEvents.single.sensorTimestampNanoseconds,
      1000000,
    );
    expect(
      recorder.recordedSensorMetadata.streams['gyroscope']?.status,
      'recorded',
    );
    expect(
      recorder.recordedSensorMetadata.streams['barometer']?.sampleCount,
      1,
    );
    expect(
      recorder.recordedSensorMetadata.streams['rotationVector']?.sampleCount,
      1,
    );
  });

  test('keeps the run recordable when an optional sensor fails', () async {
    final source = _FakeDeviceSensorSource();
    final recorder = DataRecorder(sensorSource: source);
    addTearDown(() async {
      await recorder.close();
      await source.close();
    });

    recorder.startRecording();
    source.barometer.addError(StateError('No pressure sensor'));
    source.gyroscope.add(
      GyroscopeEvent(1, 2, 3, DateTime.utc(2026, 9, 17, 12)),
    );
    await Future<void>.delayed(Duration.zero);
    recorder.stopRecording();

    final metadata = recorder.recordedSensorMetadata;
    expect(metadata.streams['barometer']?.status, 'unavailable_or_failed');
    expect(
      metadata.streams['barometer']?.error,
      contains('No pressure sensor'),
    );
    expect(recorder.recordedGyroscopeEvents, hasLength(1));
  });
}

class _FakeDeviceSensorSource implements DeviceSensorSource {
  final userAccelerometer = StreamController<UserAccelerometerEvent>.broadcast(
    sync: true,
  );
  final gyroscope = StreamController<GyroscopeEvent>.broadcast(sync: true);
  final barometer = StreamController<BarometerEvent>.broadcast(sync: true);
  final rotationVector = StreamController<OrientationEvent>.broadcast(
    sync: true,
  );

  @override
  Stream<UserAccelerometerEvent> get userAccelerometerEvents =>
      userAccelerometer.stream;

  @override
  Stream<GyroscopeEvent> get gyroscopeEvents => gyroscope.stream;

  @override
  Stream<BarometerEvent> get barometerEvents => barometer.stream;

  @override
  Stream<OrientationEvent> get rotationVectorEvents => rotationVector.stream;

  @override
  bool get supportsRotationVector => true;

  Future<void> close() async {
    await Future.wait([
      userAccelerometer.close(),
      gyroscope.close(),
      barometer.close(),
      rotationVector.close(),
    ]);
  }
}
