import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    var theme = Theme.of(context);
    final viewModel = context.watch<CompareRunsViewModel>();
    final isEditMode =
        viewModel.releasePointAnalysisMode == ReleasePointAnalysisMode.edit;

    final runsToShow = isEditMode
        ? viewModel.currentSelectedTestRuns
        : viewModel.currentSelectedReleasePointTestRuns;

    final lines = runsToShow.map(GraphLine.fromEnrichedTestRun).toList();

    final maxY = lines.isNotEmpty
        ? runsToShow.map((r) => r.maxSpeed).fold(0.0, math.max)
        : 0.0;

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: CompareGraph(
            lines: lines,
            maxY: maxY,
            maybeVerticalLineXCoordinate: isEditMode
                ? viewModel.releasePoint
                : null,
            emptyGraphContent: _buildEmptyState(),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  isEditMode
                      ? "Välj startpunkt med hjälp av slidern"
                      : "Resultat: Jämförelse från ${viewModel.releasePoint.toStringAsFixed(1)} m",
                  style: TextStyle(
                    color: isEditMode
                        ? Colors.white70
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 100,
                child: ReleasePointControls(isEditMode: isEditMode),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text("Välj ett eller flera åk i kontrollpanelen"),
        SizedBox(height: 12),
        Text(
          "Tips: Håll in volym ner för att spela in ett nytt åk.",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white54),
        ),
      ],
    );
  }
}
