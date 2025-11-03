import 'package:geolocator/geolocator.dart';

class TestRunCandidate {
  final DateTime startedAt;
  final int skiId;
  final int glideTestId;
  final int elapsedSeconds;
  final List<Position> gpsData;

  TestRunCandidate({
    required this.startedAt,
    required this.skiId,
    required this.glideTestId,
    required this.elapsedSeconds,
    required this.gpsData,
  });
}
