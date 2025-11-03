import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DataRecorder with ChangeNotifier {
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _stopwatchTimer;

  final List<Position> _positions = [];
  bool _isStreaming = false;
  double _currentSpeedKmh = 0.0;
  int _elapsedSeconds = 0;

  bool get isStreaming => _isStreaming;

  double get currentSpeedKmh => _currentSpeedKmh;

  int get elapsedSeconds => _elapsedSeconds;

  int get dataPoints => _positions.length;

  List<Position> get recordedPositions => _positions;

  void startRecordingGpsData() {
    if (_isStreaming) return;

    _positions.clear();
    _isStreaming = true;

    late LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 200),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.automotiveNavigation,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    log('Starting to stream positions data');
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _positions.add(position);
            _currentSpeedKmh = position.speed * 3.6;
            notifyListeners(); // todo call every other update?
          },
          onError: (error) {
            log('GPS error', stackTrace: error);
            print("GPS-fel: $error");
            stopStreaming();
          },
        );

    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void stopStreaming() {
    if (!_isStreaming) return;
    log('Stopped streaming position data');

    _positionStreamSubscription?.cancel();
    _stopwatchTimer?.cancel();
    _positionStreamSubscription = null;
    _stopwatchTimer = null;
    _isStreaming = false;
  }

  void clearPositions() {
    log('Cleared position data');
    _positions.clear();
    _elapsedSeconds = 0;
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
