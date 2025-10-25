import 'dart:async';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

// (LogEntry class and StatefulWidget setup remains the same)
class LogEntry {
  final DateTime timestamp;
  final Position? position;
  final UserAccelerometerEvent? accelerometerEvent;

  LogEntry({required this.timestamp, this.position, this.accelerometerEvent});
}

class DataStreamer extends StatefulWidget {
  const DataStreamer({super.key});

  @override
  State<StatefulWidget> createState() => _DataStreamerState();
}

class _DataStreamerState extends State<DataStreamer> {
  // Two separate StreamSubscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerStreamSubscription;

  // Two separate lists for the data
  final List<Position> _positions = [];
  final List<UserAccelerometerEvent> _accelEvents = [];

  // Variabler för UI
  bool _isStreaming = false;
  double _currentSpeedKmh = 0.0;

  Future<bool> _handleLocationPermission() async {
    // ... (Permission handling code is correct and unchanged)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Platstjänster är inaktiverade. Aktivera dem i inställningarna.',
          ),
        ),
      );
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Behörighet till platsdata nekades.')),
        );
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Behörighet till platsdata är permanent nekad. Vi kan inte fråga igen.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  void _startStreaming() {
    if (_isStreaming) return;

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
        // Ger en hint till iOS att detta är viktig navigering
        activityType: ActivityType.automotiveNavigation,
      );
    } else {
      // Generiska inställningar för andra plattformar
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            setState(() {
              _positions.add(position);
              _currentSpeedKmh = position.speed * 3.6;
            });
          },
          onError: (error) {
            // Alltid bra att ha felhantering
            print("GPS-fel: $error");
            _stopStreaming();
          },
        );

    _accelerometerStreamSubscription = userAccelerometerEventStream().listen(
      (UserAccelerometerEvent event) {
        _accelEvents.add(event);
      },
      onError: (error) {
        print("Accelerometer-fel: $error");
      },
    );

    setState(() {
      _isStreaming = true;
      _positions.clear();
      _accelEvents.clear();
    });
  }

  void _stopStreaming() {
    if (!_isStreaming) return;

    _positionStreamSubscription?.cancel();
    _accelerometerStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _accelerometerStreamSubscription = null;

    if (_positions.isNotEmpty || _accelEvents.isNotEmpty) {
      _exportData();
    }

    setState(() {
      _isStreaming = false;
    });
  }

  Future<void> _exportData() async {
    // ... (Zipping and export code is correct and unchanged)
    final directory = await getTemporaryDirectory();
    final path = directory.path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archive = Archive();

    if (_positions.isNotEmpty) {
      String gpsCsv = "Timestamp,Latitude,Longitude,Speed(m/s)\n";
      for (final pos in _positions) {
        gpsCsv +=
            "${pos.timestamp},${pos.latitude},${pos.longitude},${pos.speed}\n";
      }
      final gpsArchiveFile = ArchiveFile(
        'gps_data_$timestamp.csv',
        gpsCsv.length,
        gpsCsv.codeUnits,
      );
      archive.addFile(gpsArchiveFile);
    }

    if (_accelEvents.isNotEmpty) {
      String accelCsv = "Timestamp,AccelX,AccelY,AccelZ\n";
      for (final event in _accelEvents) {
        accelCsv +=
            "${event.timestamp.toIso8601String()},${event.x},${event.y},${event.z}\n";
      }
      final accelArchiveFile = ArchiveFile(
        'accel_data_$timestamp.csv',
        accelCsv.length,
        accelCsv.codeUnits,
      );
      archive.addFile(accelArchiveFile);
    }

    if (archive.isEmpty) return;

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    if (zipData == null) {
      print("Kunde inte skapa zip-filen.");
      return;
    }

    final zipFile = File('$path/gliddata_$timestamp.zip');
    await zipFile.writeAsBytes(zipData);

    final shareParams = ShareParams(
      subject: 'Data från Glidlabbet',
      files: [XFile(zipFile.path)],
    );
    await SharePlus.instance.share(shareParams);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _accelerometerStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI Build method is correct and unchanged)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Min skidpark - Prototyp'),
        backgroundColor: Colors.lightGreenAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_currentSpeedKmh.toStringAsFixed(2)} km/h',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'GPS-punkter: ${_positions.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Accel-punkter: ${_accelEvents.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming
                    ? Colors.redAccent
                    : Colors.lightGreenAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () async {
                if (_isStreaming) {
                  _stopStreaming();
                } else {
                  final hasPermission = await _handleLocationPermission();
                  if (!hasPermission) return;
                  _startStreaming();
                }
              },
              child: Text(
                _isStreaming ? 'Stoppa' : 'Starta',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
