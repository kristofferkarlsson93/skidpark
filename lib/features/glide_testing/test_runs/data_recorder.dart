import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'models/raw_accelerometer_event.dart';

enum GpsMode { record, passive }

enum GpsAccuracy { unknown, bad, decent, good, excellent }

class DataRecorder extends ChangeNotifier {
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerStreamSubscription;

  Timer? _stopwatchTimer;
  final List<Position> _positions = [];
  final List<RawAccelerometerEvent> _accelEvents = [];

  GpsAccuracy _accuracyGrade = GpsAccuracy.unknown;
  double _currentSpeedKmh = 0.0;
  int _elapsedSeconds = 0;
  GpsMode _gpsMode = GpsMode.passive;

  double get currentSpeedKmh => _currentSpeedKmh;

  int get elapsedSeconds => _elapsedSeconds;

  GpsAccuracy get accuracyGrade => _accuracyGrade;

  List<Position> get recordedPositions => _positions;

  List<RawAccelerometerEvent> get recordedAccelerometerEvents => _accelEvents;

  int get dataPoints => _positions.length;

  void startGPSSubscription(GpsMode startInMode) {
    log("starting GPS in $startInMode mode");
    _gpsMode = startInMode;
    final LocationSettings locationSettings = _getLocationSettings();
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            // log("Gps mode: ${_gpsMode.name}");
            if (_gpsMode == GpsMode.record) {
              _positions.add(position);
            }
            _currentSpeedKmh = position.speed * 3.6;
            _accuracyGrade = _gradeAccuracy(position.accuracy);
            notifyListeners();
          },
          onError: (error) {
            log('GPS error', stackTrace: error);
            _positionStreamSubscription?.cancel();
            _positionStreamSubscription = null;
          },
        );
  }

  void _startAccelerometerSubscription() {
    log("Starting accelerometer subscription");
    _accelerometerStreamSubscription =
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          (UserAccelerometerEvent event) {
            _accelEvents.add(RawAccelerometerEvent.fromSensorPlusEvent(event));
          },
          onError: (error) {
            log("Accelerometer-fel: $error");
          },
        );
  }

  void startRecording() {
    log("Starting recording");
    _positions.clear();
    _accelEvents.clear();
    _gpsMode = GpsMode.record;
    _startAccelerometerSubscription();

    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void stopRecording() {
    _gpsMode = GpsMode.passive;
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    _accelerometerStreamSubscription?.cancel();
  }

  void resetForNewRun() {
    log('Clearing data');
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    _positions.clear();
    _elapsedSeconds = 0;
    _accelEvents.clear();
  }

  @override
  void dispose() {
    // Clean up resources here
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    _accelerometerStreamSubscription?.cancel();
    _accelerometerStreamSubscription = null;
    super.dispose();
  }

  LocationSettings _getLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 200),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Min Skidpark - GlidLabbet körs",
          notificationText: "Spelar in glidtest",
          enableWakeLock: true, // keep cpu awake
          setOngoing: true, // Can remove notification.
        ),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.automotiveNavigation,
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
    if (accuracy > 10) {
      return GpsAccuracy.bad;
    } else if (accuracy > 5) {
      return GpsAccuracy.decent;
    } else if (accuracy > 3) {
      return GpsAccuracy.good;
    } else {
      // Below 3 meters.
      return GpsAccuracy.excellent;
    }
  }

  // Currently also showing UI messages. Hacky - but fast.
  static Future<bool> handleLocationPermissions(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Platstjänster är inaktiverade. Aktivera GPS och försök igen.',
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Behörighet till platsdata nekades.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Behörighet är permanent nekad. Du måste ändra detta i app-inställningarna.',
          ),
        ),
      );
      return false;
    }
    return true;
  }
}
