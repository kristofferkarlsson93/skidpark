import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'device_sensor_source.dart';
import 'models/raw_accelerometer_event.dart';
import 'models/raw_barometer_event.dart';
import 'models/raw_gps_event.dart';
import 'models/raw_gyroscope_event.dart';
import 'models/raw_rotation_vector_event.dart';
import 'models/sensor_recording_metadata.dart';

enum GpsMode { record, passive }

enum GpsAccuracy { unknown, bad, decent, good, excellent }

class DataRecorder extends ChangeNotifier {
  DataRecorder({DeviceSensorSource? sensorSource})
    : _sensorSource = sensorSource ?? PluginDeviceSensorSource();

  final DeviceSensorSource _sensorSource;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerStreamSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeStreamSubscription;
  StreamSubscription<BarometerEvent>? _barometerStreamSubscription;
  StreamSubscription<OrientationEvent>? _rotationVectorStreamSubscription;

  Timer? _stopwatchTimer;
  final Stopwatch _recordingClock = Stopwatch();
  final List<RawGpsEvent> _gpsEvents = [];
  final List<RawAccelerometerEvent> _accelEvents = [];
  final List<RawGyroscopeEvent> _gyroscopeEvents = [];
  final List<RawBarometerEvent> _barometerEvents = [];
  final List<RawRotationVectorEvent> _rotationVectorEvents = [];
  final Map<String, String> _sensorErrors = {};

  GpsAccuracy _accuracyGrade = GpsAccuracy.unknown;
  double _currentSpeedKmh = 0.0;
  int _elapsedSeconds = 0;
  GpsMode _gpsMode = GpsMode.passive;
  bool _isClosed = false;
  bool _isRecording = false;

  double get currentSpeedKmh => _currentSpeedKmh;

  int get elapsedSeconds => _elapsedSeconds;

  GpsAccuracy get accuracyGrade => _accuracyGrade;

  List<RawGpsEvent> get recordedGpsEvents => _gpsEvents;

  List<Position> get recordedPositions =>
      _gpsEvents.map((event) => event.position).toList(growable: false);

  List<RawAccelerometerEvent> get recordedAccelerometerEvents => _accelEvents;

  List<RawGyroscopeEvent> get recordedGyroscopeEvents => _gyroscopeEvents;

  List<RawBarometerEvent> get recordedBarometerEvents => _barometerEvents;

  List<RawRotationVectorEvent> get recordedRotationVectorEvents =>
      _rotationVectorEvents;

  SensorRecordingMetadata get recordedSensorMetadata {
    return SensorRecordingMetadata(
      streams: {
        'gps': SensorStreamMetadata(
          source: 'geolocator@14.0.3',
          unit: 'geolocator Position fields',
          coordinateFrame: 'WGS84',
          requestedSamplingPeriodMicroseconds: Platform.isAndroid
              ? 200000
              : null,
          sampleCount: _gpsEvents.length,
          error: _sensorErrors['gps'],
        ),
        'userAccelerometer': SensorStreamMetadata(
          source: 'sensors_plus@7.1.0',
          unit: 'm/s^2',
          coordinateFrame: 'device: +x right, +y top, +z out of screen',
          requestedSamplingPeriodMicroseconds:
              PluginDeviceSensorSource.motionSamplingPeriod.inMicroseconds,
          sampleCount: _accelEvents.length,
          error: _sensorErrors['userAccelerometer'],
        ),
        'gyroscope': SensorStreamMetadata(
          source: 'sensors_plus@7.1.0',
          unit: 'rad/s',
          coordinateFrame: 'device: right-handed x/y/z axes',
          requestedSamplingPeriodMicroseconds:
              PluginDeviceSensorSource.motionSamplingPeriod.inMicroseconds,
          sampleCount: _gyroscopeEvents.length,
          error: _sensorErrors['gyroscope'],
        ),
        'barometer': SensorStreamMetadata(
          source: 'sensors_plus@7.1.0',
          unit: 'hPa',
          coordinateFrame: 'scalar pressure',
          requestedSamplingPeriodMicroseconds:
              PluginDeviceSensorSource.barometerSamplingPeriod.inMicroseconds,
          sampleCount: _barometerEvents.length,
          error: _sensorErrors['barometer'],
        ),
        'rotationVector': SensorStreamMetadata(
          source: 'flutter_rotation_sensor@0.4.0',
          unit: 'unit quaternion; accuracy in rad',
          coordinateFrame:
              'device-to-local-world quaternion, arbitrary start reference',
          requestedSamplingPeriodMicroseconds:
              PluginDeviceSensorSource.motionSamplingPeriod.inMicroseconds,
          sampleCount: _rotationVectorEvents.length,
          error: _sensorErrors['rotationVector'],
        ),
      },
    );
  }

  void startGPSSubscription(GpsMode startInMode) {
    if (_isClosed || _positionStreamSubscription != null) return;
    log("starting GPS in $startInMode mode");
    _gpsMode = startInMode;
    final LocationSettings locationSettings = _getLocationSettings();
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _sensorErrors.remove('gps');
            // log("Gps mode: ${_gpsMode.name}");
            if (_gpsMode == GpsMode.record) {
              _gpsEvents.add(
                RawGpsEvent.fromPosition(
                  position,
                  receivedElapsedMicroseconds:
                      _recordingClock.elapsedMicroseconds,
                ),
              );
            }
            _currentSpeedKmh = position.speed * 3.6;
            _accuracyGrade = _gradeAccuracy(position.accuracy);
            notifyListeners();
          },
          onError: (error) {
            _sensorErrors['gps'] = error.toString();
            _accuracyGrade = GpsAccuracy.unknown;
            log('GPS error', error: error);
            _positionStreamSubscription?.cancel();
            _positionStreamSubscription = null;
            notifyListeners();
          },
        );
  }

  void _startAccelerometerSubscription() {
    log("Starting accelerometer subscription");
    try {
      _accelerometerStreamSubscription = _sensorSource.userAccelerometerEvents
          .listen(
            (UserAccelerometerEvent event) {
              if (!_isRecording) return;
              _accelEvents.add(
                RawAccelerometerEvent.fromSensorPlusEvent(
                  event,
                  elapsedMicroseconds: _recordingClock.elapsedMicroseconds,
                ),
              );
            },
            onError: (error) {
              _sensorErrors['userAccelerometer'] = error.toString();
              log("Accelerometer-fel: $error");
            },
          );
    } catch (error) {
      _sensorErrors['userAccelerometer'] = error.toString();
      log("Accelerometer-fel: $error");
    }
  }

  void _startGyroscopeSubscription() {
    log('Starting gyroscope subscription');
    try {
      _gyroscopeStreamSubscription = _sensorSource.gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          if (!_isRecording) return;
          _gyroscopeEvents.add(
            RawGyroscopeEvent.fromSensorPlusEvent(
              event,
              elapsedMicroseconds: _recordingClock.elapsedMicroseconds,
            ),
          );
        },
        onError: (error) {
          _sensorErrors['gyroscope'] = error.toString();
          log('Gyroscope error: $error');
        },
      );
    } catch (error) {
      _sensorErrors['gyroscope'] = error.toString();
      log('Gyroscope error: $error');
    }
  }

  void _startBarometerSubscription() {
    log('Starting barometer subscription');
    try {
      _barometerStreamSubscription = _sensorSource.barometerEvents.listen(
        (BarometerEvent event) {
          if (!_isRecording) return;
          _barometerEvents.add(
            RawBarometerEvent.fromSensorPlusEvent(
              event,
              elapsedMicroseconds: _recordingClock.elapsedMicroseconds,
            ),
          );
        },
        onError: (error) {
          _sensorErrors['barometer'] = error.toString();
          log('Barometer error: $error');
        },
      );
    } catch (error) {
      _sensorErrors['barometer'] = error.toString();
      log('Barometer error: $error');
    }
  }

  void _startRotationVectorSubscription() {
    log('Starting rotation vector subscription');
    if (!_sensorSource.supportsRotationVector) {
      _sensorErrors['rotationVector'] = 'Platform not supported';
      return;
    }

    try {
      _rotationVectorStreamSubscription = _sensorSource.rotationVectorEvents
          .listen(
            (OrientationEvent event) {
              if (!_isRecording) return;
              _rotationVectorEvents.add(
                RawRotationVectorEvent.fromRotationSensorEvent(
                  event,
                  elapsedMicroseconds: _recordingClock.elapsedMicroseconds,
                ),
              );
            },
            onError: (error) {
              _sensorErrors['rotationVector'] = error.toString();
              log('Rotation vector error: $error');
            },
          );
    } catch (error) {
      _sensorErrors['rotationVector'] = error.toString();
      log('Rotation vector error: $error');
    }
  }

  void startRecording() {
    if (_isClosed || _isRecording) return;
    log("Starting recording");
    _gpsEvents.clear();
    _accelEvents.clear();
    _gyroscopeEvents.clear();
    _barometerEvents.clear();
    _rotationVectorEvents.clear();
    final gpsError = _sensorErrors['gps'];
    _sensorErrors.clear();
    if (gpsError != null) _sensorErrors['gps'] = gpsError;
    _isRecording = true;
    _recordingClock
      ..reset()
      ..start();
    _gpsMode = GpsMode.record;
    _startAccelerometerSubscription();
    _startGyroscopeSubscription();
    _startBarometerSubscription();
    _startRotationVectorSubscription();

    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void stopRecording() {
    _isRecording = false;
    _recordingClock.stop();
    _gpsMode = GpsMode.passive;
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    _accelerometerStreamSubscription?.cancel();
    _accelerometerStreamSubscription = null;
    _gyroscopeStreamSubscription?.cancel();
    _gyroscopeStreamSubscription = null;
    _barometerStreamSubscription?.cancel();
    _barometerStreamSubscription = null;
    _rotationVectorStreamSubscription?.cancel();
    _rotationVectorStreamSubscription = null;
  }

  void resetForNewRun() {
    log('Clearing data');
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    _gpsEvents.clear();
    _elapsedSeconds = 0;
    _accelEvents.clear();
    _gyroscopeEvents.clear();
    _barometerEvents.clear();
    _rotationVectorEvents.clear();
    _sensorErrors.clear();
    _recordingClock.reset();
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _isRecording = false;
    _recordingClock.stop();
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    await _accelerometerStreamSubscription?.cancel();
    _accelerometerStreamSubscription = null;
    await _gyroscopeStreamSubscription?.cancel();
    _gyroscopeStreamSubscription = null;
    await _barometerStreamSubscription?.cancel();
    _barometerStreamSubscription = null;
    await _rotationVectorStreamSubscription?.cancel();
    _rotationVectorStreamSubscription = null;
  }

  @override
  void dispose() {
    if (!_isClosed) {
      unawaited(close());
    }
    super.dispose();
  }

  LocationSettings _getLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 200),
        // Disabled for now: Causing strange flicker in the GPS recording.
        // When using foregroundService android behaves differently when giving location.
        // foregroundNotificationConfig: const ForegroundNotificationConfig(
        //   notificationTitle: "Min Skidpark - Glidlabbet körs",
        //   notificationText: "Använder GPS",
        //   enableWakeLock: true, // keep cpu awake
        //   setOngoing: true, // Can remove notification.
        // ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: false,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }
  }

  GpsAccuracy _gradeAccuracy(double accuracy) {
    // log(accuracy.toStringAsFixed(2));
    if (!accuracy.isFinite || accuracy <= 0) {
      return GpsAccuracy.unknown;
    }

    if (accuracy > 15) {
      return GpsAccuracy.bad;
    } else if (accuracy > 8) {
      return GpsAccuracy.decent;
    } else if (accuracy >= 6) {
      return GpsAccuracy.good;
    } else {
      // Below 7 meters.
      return GpsAccuracy.excellent;
    }
  }

  // Currently also showing UI messages. Hacky - but fast.
  static Future<bool> handleLocationPermissions(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!context.mounted) return false;
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Platstjänster är inaktiverade. Aktivera GPS och försök igen.',
          ),
          action: SnackBarAction(
            label: 'Inställningar',
            onPressed: Geolocator.openLocationSettings,
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (!context.mounted) return false;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!context.mounted) return false;

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Behörighet till platsdata nekades.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Behörighet är permanent nekad. Du måste ändra detta i app-inställningarna.',
          ),
          action: SnackBarAction(
            label: 'Inställningar',
            onPressed: Geolocator.openAppSettings,
          ),
        ),
      );
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (!context.mounted) return false;
      await _requestPreciseLocationIfAvailable(context);
    }
    return true;
  }

  static Future<void> _requestPreciseLocationIfAvailable(
    BuildContext context,
  ) async {
    try {
      var accuracy = await Geolocator.getLocationAccuracy();
      if (!context.mounted) return;
      if (accuracy == LocationAccuracyStatus.reduced) {
        accuracy = await Geolocator.requestTemporaryFullAccuracy(
          purposeKey: 'GlideRecording',
        );
        if (!context.mounted) return;
      }

      if (accuracy == LocationAccuracyStatus.reduced) {
        if (!context.mounted) return;
        _showReducedAccuracyWarning(context);
      }
    } catch (error) {
      if (!context.mounted) return;
      log('Could not request precise location', error: error);
      _showReducedAccuracyWarning(context);
    }
  }

  static void _showReducedAccuracyWarning(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Exakt plats kunde inte bekräftas. Åket fortsätter, men '
          'GPS-jämförelsen kan påverkas.',
        ),
        action: SnackBarAction(
          label: 'Inställningar',
          onPressed: () {
            unawaited(Geolocator.openAppSettings());
          },
        ),
      ),
    );
  }
}
