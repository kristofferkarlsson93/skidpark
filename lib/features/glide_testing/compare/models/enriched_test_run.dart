import 'dart:ui';

import 'package:skidpark/features/glide_testing/compare/models/calculated_position.dart';

class EnrichedTestRun {
  final int id;
  final DateTime startedAt;
  final int skiId;
  final int glideTestId;
  final int elapsedSeconds;
  final double traveledDistance;
  final double averageSpeed;
  final double maxSpeed;
  final String skiName;
  final List<CalculatedPosition> positionData;
  late Color runColor = _createColor();

  EnrichedTestRun(
    this.id,
    this.startedAt,
    this.skiId,
    this.glideTestId,
    this.elapsedSeconds,
    this.traveledDistance,
    this.averageSpeed,
    this.maxSpeed,
    this.skiName,
    this.positionData,
  );

  @override
  String toString() {
    return 'EnrichedTestRun(id: $id, startedAt: $startedAt, skiId: $skiId, glideTestId: $glideTestId, elapsedSeconds: $elapsedSeconds, traveledDistance: $traveledDistance, averageSpeed: $averageSpeed, maxSpeed: $maxSpeed, positionData: $positionData)';
  }

  Color _createColor() {
    final hash = '$id-$glideTestId-$elapsedSeconds-$traveledDistance-$skiName'.hashCode; // Or use a combination: '${run.id}_${run.skiName}'.hashCode
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(0xFF, r, g, b);
  }
}
