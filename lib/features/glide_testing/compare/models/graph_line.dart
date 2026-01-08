import 'dart:ui';

import 'calculated_position.dart';
import 'enriched_test_run.dart';

class GraphLine {
  final int id;
  final List<CalculatedPosition> positionData;
  final Color runColor;

  GraphLine(this.id, this.positionData, this.runColor);

  factory GraphLine.fromEnrichedTestRun(EnrichedTestRun run) {
    return GraphLine(run.runNumber, run.positionData, run.runColor);
  }
}
