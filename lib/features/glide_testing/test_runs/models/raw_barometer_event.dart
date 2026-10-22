import 'package:sensors_plus/sensors_plus.dart';

class RawBarometerEvent {
  final double pressureHpa;
  final DateTime sensorTimestamp;
  final int elapsedMicroseconds;

  const RawBarometerEvent({
    required this.pressureHpa,
    required this.sensorTimestamp,
    required this.elapsedMicroseconds,
  });

  factory RawBarometerEvent.fromSensorPlusEvent(
    BarometerEvent event, {
    required int elapsedMicroseconds,
  }) {
    return RawBarometerEvent(
      pressureHpa: event.pressure,
      sensorTimestamp: event.timestamp,
      elapsedMicroseconds: elapsedMicroseconds,
    );
  }

  factory RawBarometerEvent.fromJson(Map<String, dynamic> json) {
    final pressure = json['pressureHpa'] ?? json['pressure'];
    return RawBarometerEvent(
      pressureHpa: (pressure as num).toDouble(),
      sensorTimestamp: DateTime.parse(
        (json['sensorTimestamp'] ?? json['timestamp']) as String,
      ),
      elapsedMicroseconds: (json['elapsedMicroseconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pressureHpa': pressureHpa,
      'sensorTimestamp': sensorTimestamp.toIso8601String(),
      'elapsedMicroseconds': elapsedMicroseconds,
    };
  }
}
