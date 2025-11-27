import 'package:sensors_plus/sensors_plus.dart';

class RawAccelerometerEvent {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const RawAccelerometerEvent({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  factory RawAccelerometerEvent.fromSensorPlusEvent(UserAccelerometerEvent e) {
    return RawAccelerometerEvent(
      x: e.x,
      y: e.y,
      z: e.z,
      timestamp: e.timestamp,
    );
  }

  factory RawAccelerometerEvent.fromJson(Map<String, dynamic> json) {
    return RawAccelerometerEvent(
      x: json['x'] as double,
      y: json['y'] as double,
      z: json['z'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z, 'timestamp': timestamp.toIso8601String()};
  }
}
