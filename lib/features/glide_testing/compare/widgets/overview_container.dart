import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/models/graph_line.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_graph.dart';

import '../compare_runs_view_model.dart';
import 'compare_list.dart';

class OverviewContainer extends StatelessWidget {
  const OverviewContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final selectedRuns = viewModel.currentDisplayRuns;
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: CompareGraph(
            lines: selectedRuns
                .map(
                  (r) => GraphLine.fromEnrichedTestRun(
                    r,
                    viewModel.calculateRunLabel(r),
                  ),
                )
                .toList(),
            maxY: selectedRuns.map((r) => r.maxSpeedKmh).fold(0, math.max),
            emptyGraphContent: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
        ),
        Expanded(
          flex: 2,
          child: CompareList(
            runs: selectedRuns,
            isAverageView: viewModel.useAverageView,
            highlightedRunId: viewModel.highlightedRunId,
            onRunTapped: (runId) => viewModel.toggleHighlightedRun(runId),
          ),
        ),
      ],
    );
  }
}
