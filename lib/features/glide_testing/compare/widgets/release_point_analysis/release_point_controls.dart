import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/release_point_analysis/Release_point_selector.dart';

import '../../compare_runs_view_model.dart';

enum ReleasePointAnalysisMode { edit, view }

class ReleasePointControls extends StatelessWidget {
  final bool isEditMode;

  const ReleasePointControls({super.key, required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    if (!isEditMode) return const SizedBox.shrink();

    final viewModel = context.watch<CompareRunsViewModel>();
    final hasRuns = viewModel.currentSelectedTestRuns.isNotEmpty;

    final shortestDistance = hasRuns
        ? viewModel.currentSelectedTestRuns
              .map((r) => r.traveledDistance)
              .fold(100.0, math.max)
        : 100.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slider
        SizedBox(
          height: 40,
          child: ReleasePointSelector(
            enabled: hasRuns,
            maxValue: shortestDistance,
            value: viewModel.releasePoint,
            onChanged: (newValue) => viewModel.setReleasePoint(newValue),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: FilledButton.icon(
            onPressed: hasRuns
                ? () => viewModel.triggerReleasePointAnalysis()
                : null,
            icon: const Icon(Icons.analytics),
            label: const Text("Analysera Glid"),
          ),
        ),
      ],
    );
  }
}
