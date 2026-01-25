import 'dart:ui';

import 'calculated_position.dart';
import 'enriched_test_run.dart';

class GraphLine {
  final int id;
  final List<CalculatedPosition> positionData;
  final Color runColor;
  final String label;

  GraphLine(this.id, this.positionData, this.runColor, this.label);

  factory GraphLine.fromEnrichedTestRun(EnrichedTestRun run, String runLabel) {
    return GraphLine(run.runNumber, run.positionData, run.runColor, runLabel);
  }
}
