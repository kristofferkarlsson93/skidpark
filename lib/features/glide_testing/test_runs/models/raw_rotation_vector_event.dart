import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

class RawRotationVectorEvent {
  final double x;
  final double y;
  final double z;
  final double w;
  final double accuracyRadians;
  final int sensorTimestampNanoseconds;
  final int elapsedMicroseconds;

  const RawRotationVectorEvent({
    required this.x,
    required this.y,
    required this.z,
    required this.w,
    required this.accuracyRadians,
    required this.sensorTimestampNanoseconds,
    required this.elapsedMicroseconds,
  });

  factory RawRotationVectorEvent.fromRotationSensorEvent(
    OrientationEvent event, {
    required int elapsedMicroseconds,
  }) {
    return RawRotationVectorEvent(
      x: event.quaternion.x,
      y: event.quaternion.y,
      z: event.quaternion.z,
      w: event.quaternion.w,
      accuracyRadians: event.accuracy,
      sensorTimestampNanoseconds: event.timestamp,
      elapsedMicroseconds: elapsedMicroseconds,
    );
  }

  factory RawRotationVectorEvent.fromJson(Map<String, dynamic> json) {
    return RawRotationVectorEvent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      accuracyRadians: (json['accuracyRadians'] as num).toDouble(),
      sensorTimestampNanoseconds: (json['sensorTimestampNanoseconds'] as num)
          .toInt(),
      elapsedMicroseconds: (json['elapsedMicroseconds'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'w': w,
      'accuracyRadians': accuracyRadians,
      'sensorTimestampNanoseconds': sensorTimestampNanoseconds,
      'elapsedMicroseconds': elapsedMicroseconds,
    };
  }
}
