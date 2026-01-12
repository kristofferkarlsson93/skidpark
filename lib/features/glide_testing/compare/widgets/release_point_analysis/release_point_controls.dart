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
    final viewModel = context.watch<CompareRunsViewModel>();

    final shortestDistance = viewModel.currentSelectedTestRuns.isNotEmpty
        ? viewModel.currentSelectedTestRuns
        .map((r) => r.traveledDistance)
        .fold(100.0, math.min)
        : 100.0;

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: isEditMode
          ? _buildEditControls(context, viewModel, shortestDistance)
          : _buildViewControls(context, viewModel),
    );
  }

  Widget _buildEditControls(
      BuildContext context,
      CompareRunsViewModel viewModel,
      double maxDist
      ) {
    final hasRuns = viewModel.currentSelectedTestRuns.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ReleasePointSelector(
            enabled: hasRuns,
            maxValue: maxDist,
            value: viewModel.releasePoint,
            onChanged: (newValue) => viewModel.setReleasePoint(newValue),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: FilledButton.icon(
            onPressed: hasRuns ? () => viewModel.triggerReleasePointAnalysis() : null,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text("Analysera Glid"),
          ),
        ),
      ],
    );
  }

  Widget _buildViewControls(BuildContext context, CompareRunsViewModel viewModel) {
    return Column(
      children: [
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: () => viewModel.enterEditReleasePointAnalysisMode(),
            icon: const Icon(Icons.edit),
            label: const Text("Justera startpunkt"),
          ),
        ),
      ],
    );
  }
}