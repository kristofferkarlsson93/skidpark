import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/input/hands_free_controls_factory.dart';

import 'package:skidpark/features/glide_testing/compare/models/graph_line.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_graph.dart';

import '../compare_runs_view_model.dart';

class OverviewGraph extends StatelessWidget {
  const OverviewGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final controls = context.read<HandsFreeControlsFactory>();
    final selectedRuns = viewModel.currentDisplayRuns;
    return CompareGraph(
      lines: selectedRuns
          .map(
            (r) => GraphLine.fromEnrichedTestRun(
              r,
              viewModel.calculateRunLabel(r),
            ),
          )
          .toList(),
      maxY: selectedRuns.map((r) => r.maxSpeedKmh).fold(0, math.max),
      highlightedLineId: viewModel.highlightedRunId,
      emptyGraphContent: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (viewModel.testRuns.isNotEmpty) ...[
              Text("Välj ett eller flera åk i kontrollpanelen"),
              SizedBox(height: 12),
            ],
            if (controls.isSupported)
              Text(
                'Tips: ${controls.instructions.openRun}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}
