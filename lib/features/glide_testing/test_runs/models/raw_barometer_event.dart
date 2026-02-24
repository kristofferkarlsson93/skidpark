import 'package:sensors_plus/sensors_plus.dart';

class RawBarometerEvent {
  final double pressure;
  final DateTime timestamp;

  const RawBarometerEvent({required this.pressure, required this.timestamp});

  factory RawBarometerEvent.fromSensorPlusEvent(BarometerEvent event) {
    return RawBarometerEvent(
      pressure: event.pressure,
      timestamp: event.timestamp,
    );
  }

  factory RawBarometerEvent.fromJson(Map<String, dynamic> json) {
    return RawBarometerEvent(
      pressure: json['pressure'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'pressure': pressure, 'timestamp': timestamp.toIso8601String()};
  }
}
