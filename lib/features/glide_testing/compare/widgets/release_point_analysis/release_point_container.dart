import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_graph.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/release_point_analysis/release_point_controls.dart';

import '../../compare_runs_view_model.dart';
import '../../models/enriched_test_run.dart';
import '../../models/graph_line.dart';

class ReleasePointGraph extends StatelessWidget {
  const ReleasePointGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final isEditMode =
        viewModel.releasePointAnalysisMode == ReleasePointAnalysisMode.edit;

    final runsToShow = isEditMode
        ? viewModel.currentDisplayRuns
        : viewModel.currentSelectedReleasePointTestRuns;

    final lines = runsToShow
        .map(
          (r) =>
              GraphLine.fromEnrichedTestRun(r, viewModel.calculateRunLabel(r)),
        )
        .toList();

    final maxY = lines.isNotEmpty
        ? runsToShow.map((r) => r.maxSpeedKmh).fold(0.0, math.max)
        : 0.0;

    return CompareGraph(
      lines: lines,
      maxY: maxY,
      maybeVerticalLineXCoordinate: isEditMode ? viewModel.releasePoint : null,
      emptyGraphContent: const Center(child: Text('Ingen data vald')),
    );
  }
}

class ReleasePointPanel extends StatelessWidget {
  const ReleasePointPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CompareRunsViewModel>();
    final useAverageView = viewModel.useAverageView;
    final isEditMode =
        viewModel.releasePointAnalysisMode == ReleasePointAnalysisMode.edit;
    final runsToShow = isEditMode
        ? viewModel.currentDisplayRuns
        : viewModel.currentSelectedReleasePointTestRuns;

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => _showInfoDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.info_outline,
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isEditMode
                              ? "Välj släpp-punkt"
                              : "Simulerat släpp: ${viewModel.releasePoint.toStringAsFixed(0)} m",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isEditMode)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: "Justera punkt",
                    onPressed: () =>
                        viewModel.enterEditReleasePointAnalysisMode(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          Expanded(
            child: isEditMode
                ? _buildEditControlsPanel(context)
                : _buildResultList(context, runsToShow, useAverageView),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Simulera släpp vid punkt"),
          content: const Text(
            'Kurvorna räknas om för jämförelse från en vald punkt. '
            'Flytta linjen med reglaget och tryck på Analysera från punkten.\n\n'
            'Det är en beräknad jämförelse. Resultatet visar inte säkert hur '
            'två skidåkare skulle ha glidit bredvid varandra. Jämför också '
            'variationen mellan flera åk med samma skidor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditControlsPanel(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: const ReleasePointControls(isEditMode: true),
      ),
    );
  }

  Widget _buildResultList(
    BuildContext context,
    List<EnrichedTestRun> runs,
    bool useAverageView,
  ) {
    if (runs.isEmpty) {
      return const Center(child: Text("Ingen data att visa"));
    }
    final theme = Theme.of(context);

    final worstDistance = runs.isNotEmpty
        ? (runs as Iterable).fold<double>(
            100000.0,
            (minDist, r) => math.min(minDist, r.traveledDistance as double),
          )
        : 0.0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      itemCount: runs.length,
      itemBuilder: (context, index) {
        final run = runs[index];
        var title = useAverageView
            ? "${run.skiName} (${run.runNumber} åk)"
            : "Åk ${run.runNumber} - ${run.skiName}";

        double speedLossPer10m = 0.0;
        if (run.positionData.isNotEmpty && run.traveledDistance > 0) {
          final startKmh = run.positionData.first.speed * 3.6;
          final endKmh = run.positionData.last.speed * 3.6;
          speedLossPer10m = ((startKmh - endKmh) / run.traveledDistance) * 10.0;
        }

        final diff = run.traveledDistance - worstDistance;
        final isReference = diff <= 0.05;

        final diffText = isReference
            ? "Referens"
            : "+${diff.toStringAsFixed(1)} m";
        final diffColor = isReference
            ? theme.colorScheme.onSurfaceVariant
            : Colors.green;
        final diffWeight = isReference ? FontWeight.normal : FontWeight.bold;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: run.runColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isReference
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Tappar ${speedLossPer10m.toStringAsFixed(2)} km/h per 10m",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(
                          150,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                diffText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: diffWeight,
                  color: diffColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
