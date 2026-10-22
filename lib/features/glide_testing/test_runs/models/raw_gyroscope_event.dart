import 'package:sensors_plus/sensors_plus.dart';

class RawGyroscopeEvent {
  final double x;
  final double y;
  final double z;
  final DateTime sensorTimestamp;
  final int elapsedMicroseconds;

  const RawGyroscopeEvent({
    required this.x,
    required this.y,
    required this.z,
    required this.sensorTimestamp,
    required this.elapsedMicroseconds,
  });

  factory RawGyroscopeEvent.fromSensorPlusEvent(
    GyroscopeEvent event, {
    required int elapsedMicroseconds,
  }) {
    return RawGyroscopeEvent(
      x: event.x,
      y: event.y,
      z: event.z,
      sensorTimestamp: event.timestamp,
      elapsedMicroseconds: elapsedMicroseconds,
    );
  }

  factory RawGyroscopeEvent.fromJson(Map<String, dynamic> json) {
    return RawGyroscopeEvent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      sensorTimestamp: DateTime.parse(json['sensorTimestamp'] as String),
      elapsedMicroseconds: (json['elapsedMicroseconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'sensorTimestamp': sensorTimestamp.toIso8601String(),
      'elapsedMicroseconds': elapsedMicroseconds,
    };
  }
}
