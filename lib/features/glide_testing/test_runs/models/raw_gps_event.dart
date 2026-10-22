import 'package:geolocator/geolocator.dart';

class RawGpsEvent {
  static const receivedElapsedMicrosecondsKey = 'receivedElapsedMicroseconds';

  final Position position;

  /// Monotonic app time when the GPS event reached Dart. The provider's
  /// [Position.timestamp] remains the time when the position was measured.
  final int? receivedElapsedMicroseconds;

  const RawGpsEvent({
    required this.position,
    required this.receivedElapsedMicroseconds,
  });

  factory RawGpsEvent.fromPosition(
    Position position, {
    int? receivedElapsedMicroseconds,
  }) {
    return RawGpsEvent(
      position: position,
      receivedElapsedMicroseconds: receivedElapsedMicroseconds,
    );
  }

  factory RawGpsEvent.fromJson(Map<String, dynamic> json) {
    final positionJson = Map<String, dynamic>.from(json)
      ..remove(receivedElapsedMicrosecondsKey);
    return RawGpsEvent(
      position: Position.fromMap(positionJson),
      receivedElapsedMicroseconds:
          (json[receivedElapsedMicrosecondsKey] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...position.toJson(),
      if (receivedElapsedMicroseconds != null)
        receivedElapsedMicrosecondsKey: receivedElapsedMicroseconds,
    };
  }
}
