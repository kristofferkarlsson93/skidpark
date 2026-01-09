import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_graph.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/release_point_analysis/release_point_controls.dart';

import '../../compare_runs_view_model.dart';
import '../../models/graph_line.dart';

// NEXT STEPS
/**
 * FLytta slidern upp närmare grafen
 * Visa skid-legends så man vet vilken linje som är vilken skida.
 * Räkna om vid sensor-fursion toggle.
 */

class ReleasePointContainer extends StatelessWidget {
  const ReleasePointContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final selectedRuns = viewModel.currentSelectedTestRuns;

    final isEditMode =
        viewModel.releasePointAnalysisMode == ReleasePointAnalysisMode.edit;

    var lines = isEditMode
        ? selectedRuns.map((r) => GraphLine.fromEnrichedTestRun(r)).toList()
        : viewModel.currentSelectedReleasePointTestRuns
              .map(GraphLine.fromEnrichedTestRun)
              .toList();

    if (lines.isNotEmpty) {
      log(lines.first.positionData.length.toString());
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: CompareGraph(
            lines: lines,
            maxY: selectedRuns.map((r) => r.maxSpeed).fold(0, math.max),
            maybeVerticalLineXCoordinate:
                viewModel.releasePointAnalysisMode ==
                    ReleasePointAnalysisMode.edit
                ? viewModel.releasePoint
                : null,
            emptyGraphContent: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (viewModel.testRuns.isNotEmpty) ...[
                  Text("Välj ett eller flera åk i kontrollpanelen"),
                  SizedBox(height: 12),
                ],
                Text(
                  "Tips: Håll in volym ner för att spela in ett nytt åk.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        Expanded(flex: 2, child: ReleasePointControls()),
      ],
    );
  }
}
