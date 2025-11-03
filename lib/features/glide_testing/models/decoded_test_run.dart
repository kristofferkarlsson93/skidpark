import 'package:geolocator/geolocator.dart';

class DecodedTestRun {
  final int id;
  final DateTime startedAt;
  final int skiId;
  final int glideTestId;
  final int elapsedSeconds;
  final String skiName;
  final List<Position> gpsData;

  DecodedTestRun(
    this.id,
    this.startedAt,
    this.skiId,
    this.glideTestId,
    this.elapsedSeconds,
    this.skiName,
    this.gpsData,
  );
}
