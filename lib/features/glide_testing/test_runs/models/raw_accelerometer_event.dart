import 'package:sensors_plus/sensors_plus.dart';

class RawAccelerometerEvent {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  final int? elapsedMicroseconds;

  const RawAccelerometerEvent({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
    this.elapsedMicroseconds,
  });

  factory RawAccelerometerEvent.fromSensorPlusEvent(
    UserAccelerometerEvent e, {
    int? elapsedMicroseconds,
  }) {
    return RawAccelerometerEvent(
      x: e.x,
      y: e.y,
      z: e.z,
      timestamp: e.timestamp,
      elapsedMicroseconds: elapsedMicroseconds,
    );
  }

  factory RawAccelerometerEvent.fromJson(Map<String, dynamic> json) {
    return RawAccelerometerEvent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      elapsedMicroseconds: (json['elapsedMicroseconds'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp.toIso8601String(),
      if (elapsedMicroseconds != null)
        'elapsedMicroseconds': elapsedMicroseconds,
    };
  }
}
