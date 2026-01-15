import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/calculated_position.dart';

class EnrichedTestRun {
  final int id;
  final DateTime startedAt;
  final int skiId;
  final int glideTestId;
  final int elapsedSeconds;
  final double traveledDistance;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final String skiName;
  final List<CalculatedPosition> positionData;
  final int runNumber;
  late Color runColor = _createColor();

  EnrichedTestRun(
    this.id,
    this.startedAt,
    this.skiId,
    this.glideTestId,
    this.elapsedSeconds,
    this.traveledDistance,
    this.averageSpeedKmh,
    this.maxSpeedKmh,
    this.skiName,
    this.positionData,
    this.runNumber,
  );

  void setColor(Color color) {
    runColor = color;
  }

  @override
  String toString() {
    return 'EnrichedTestRun(id: $id, startedAt: $startedAt, skiId: $skiId, glideTestId: $glideTestId, elapsedSeconds: $elapsedSeconds, traveledDistance: $traveledDistance, averageSpeed: $averageSpeedKmh, maxSpeed: $maxSpeedKmh, positionData: $positionData, runNumber: $runNumber)';
  }

  Color _createColor() {
    final hue =
        (runNumber * 137) % 360; // 137 is a prime for better distribution
    const saturation = 0.7; // 0.0 - 1.0
    const lightness = 0.6; // 0.0 - 1.0, >0.5 for brighter colors

    final hslColor = HSLColor.fromAHSL(
      1.0,
      hue.toDouble(),
      saturation,
      lightness,
    );
    return hslColor.toColor();
  }
}
