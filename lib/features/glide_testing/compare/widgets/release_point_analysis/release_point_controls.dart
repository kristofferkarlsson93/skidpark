import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/release_point_analysis/Release_point_selector.dart';

import '../../compare_runs_view_model.dart';

enum ReleasePointAnalysisMode { edit, view }

class ReleasePointControls extends StatelessWidget {
  const ReleasePointControls({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final shortestDistance = viewModel.currentSelectedTestRuns
        .map((r) => r.traveledDistance)
        .fold(100.0, math.min);
    final isEditable =
        viewModel.releasePointAnalysisMode == ReleasePointAnalysisMode.edit &&
        viewModel.currentSelectedTestRuns.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 10,
          child: ReleasePointSelector(
            enabled: isEditable,
            maxValue: shortestDistance,
            value: viewModel.releasePoint,
            onChanged: (newValue) {
              viewModel.setReleasePoint(newValue);
            },
          ),
        ),
        Flexible(
          flex: 2,
          child:
              viewModel.releasePointAnalysisMode ==
                  ReleasePointAnalysisMode.edit
              ? IconButton(
                  onPressed: () {
                    // Don't do anything if no runs are selected. Graph is hidden
                    if (viewModel
                        .currentSelectedReleasePointTestRuns
                        .isNotEmpty) {
                      viewModel.triggerReleasePointAnalysis();
                    }
                  },
                  icon: const Icon(Icons.check),
                )
              : IconButton(
                  onPressed: () {
                    if (viewModel
                        .currentSelectedReleasePointTestRuns
                        .isNotEmpty) {
                      viewModel.enterEditReleasePointAnalysisMode();
                    }
                  },
                  icon: const Icon(Icons.edit),
                ),
        ),
      ],
    );
  }
}
