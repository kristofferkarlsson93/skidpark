import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/device_sensor_source.dart';

void main() {
  testWidgets('reduced iOS accuracy warns and allows the recording flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final originalPlatform = GeolocatorPlatform.instance;
    final originalTargetPlatform = debugDefaultTargetPlatformOverride;
    final fakePlatform = _FakeGeolocatorPlatform()
      ..locationAccuracy = LocationAccuracyStatus.reduced
      ..requestedAccuracy = LocationAccuracyStatus.reduced;
    GeolocatorPlatform.instance = fakePlatform;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    try {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      final context = tester.element(find.byType(Scaffold));

      final allowed = await DataRecorder.handleLocationPermissions(context);
      await tester.pumpAndSettle();

      expect(allowed, isTrue);
      expect(fakePlatform.temporaryAccuracyPurposeKey, 'GlideRecording');
      expect(
        find.textContaining('Exakt plats kunde inte bekräftas'),
        findsOneWidget,
      );
      expect(find.text('Inställningar'), findsOneWidget);

      await tester.tap(find.text('Inställningar'));
      await tester.pumpAndSettle();
      expect(fakePlatform.openAppSettingsCount, 1);
    } finally {
      GeolocatorPlatform.instance = originalPlatform;
      debugDefaultTargetPlatformOverride = originalTargetPlatform;
      await fakePlatform.dispose();
    }
  });

  test(
    'uses foreground Apple settings and marks invalid or failed GPS unknown',
    () async {
      final originalPlatform = GeolocatorPlatform.instance;
      final fakePlatform = _FakeGeolocatorPlatform();
      final sensorSource = _FakeDeviceSensorSource();
      GeolocatorPlatform.instance = fakePlatform;
      final originalTargetPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final recorder = DataRecorder(sensorSource: sensorSource);
      addTearDown(() async {
        GeolocatorPlatform.instance = originalPlatform;
        debugDefaultTargetPlatformOverride = originalTargetPlatform;
        await recorder.close();
        await fakePlatform.dispose();
        await sensorSource.close();
      });

      var notificationCount = 0;
      recorder.addListener(() => notificationCount++);
      recorder.startGPSSubscription(GpsMode.record);

      final settings = fakePlatform.requestedLocationSettings;
      expect(settings, isA<AppleSettings>());
      final appleSettings = settings! as AppleSettings;
      expect(appleSettings.accuracy, LocationAccuracy.bestForNavigation);
      expect(appleSettings.distanceFilter, 0);
      expect(appleSettings.activityType, ActivityType.fitness);
      expect(appleSettings.pauseLocationUpdatesAutomatically, isFalse);
      expect(appleSettings.allowBackgroundLocationUpdates, isFalse);

      fakePlatform.positions.add(_position(accuracy: 5));
      expect(recorder.accuracyGrade, GpsAccuracy.excellent);
      expect(notificationCount, 1);

      for (final invalidAccuracy in [0.0, -1.0, double.nan, double.infinity]) {
        fakePlatform.positions.add(_position(accuracy: invalidAccuracy));
        expect(recorder.accuracyGrade, GpsAccuracy.unknown);
      }
      expect(notificationCount, 5);
      expect(recorder.recordedGpsEvents, hasLength(5));

      fakePlatform.positions.add(_position(accuracy: 5));
      expect(recorder.accuracyGrade, GpsAccuracy.excellent);
      fakePlatform.positions.addError(StateError('GPS stream failed'));

      expect(recorder.accuracyGrade, GpsAccuracy.unknown);
      expect(notificationCount, 7);
      expect(
        recorder.recordedSensorMetadata.streams['gps']?.error,
        contains('GPS stream failed'),
      );
      expect(recorder.recordedGpsEvents, hasLength(6));
    },
  );

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

Position _position({required double accuracy}) => Position(
  longitude: 18,
  latitude: 59,
  timestamp: DateTime.utc(2026, 10, 22),
  accuracy: accuracy,
  altitude: 10,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 3,
  speedAccuracy: 0.5,
);

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  final positions = StreamController<Position>.broadcast(sync: true);
  bool locationServicesEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationAccuracyStatus locationAccuracy = LocationAccuracyStatus.precise;
  LocationAccuracyStatus requestedAccuracy = LocationAccuracyStatus.precise;
  String? temporaryAccuracyPurposeKey;
  int openAppSettingsCount = 0;
  LocationSettings? requestedLocationSettings;

  @override
  Future<bool> isLocationServiceEnabled() async => locationServicesEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async =>
      locationAccuracy;

  @override
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async {
    temporaryAccuracyPurposeKey = purposeKey;
    return requestedAccuracy;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCount++;
    return true;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    requestedLocationSettings = locationSettings;
    return positions.stream;
  }

  Future<void> dispose() => positions.close();
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
