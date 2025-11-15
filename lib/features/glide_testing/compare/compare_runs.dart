import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/compare_runs_view_model.dart';
import 'package:skidpark/features/glide_testing/compare/models/calculated_position.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/select_run_card.dart';

class CompareRuns extends StatefulWidget {
  const CompareRuns({super.key});

  @override
  State<CompareRuns> createState() => _CompareRunsState();
}

class _CompareRunsState extends State<CompareRuns> {
  final Set<int> _selectedRunIds = {};

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final theme = Theme.of(context);
    final testRuns = viewModel.testRuns;

    final selectedRuns = testRuns
        .where((run) => _selectedRunIds.contains(run.id))
        .toList();

    final orientation = MediaQuery.of(context).orientation;
    final listWidget = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: Text(
            "Välj åk att jämföra i grafen:",
            style: theme.textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: testRuns.length,
            itemBuilder: (context, index) {
              final run = testRuns[index];
              final isSelected = _selectedRunIds.contains(run.id);
              return SelectRunCard(
                isSelected: isSelected,
                testRun: run,
                runNumber: index + 1,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedRunIds.remove(run.id);
                    } else {
                      _selectedRunIds.add(run.id);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );

    if (orientation == Orientation.portrait) {
      return Column(
        children: [
          _buildChartContainer(context, selectedRuns, orientation),
          Expanded(child: listWidget),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 7,
            child: _buildChartContainer(context, selectedRuns, orientation),
          ),
          Expanded(flex: 3, child: listWidget),
        ],
      );
    }
  }

  Widget _buildChartContainer(
    BuildContext context,
    List<EnrichedTestRun> runs,
    Orientation orientation,
  ) {
    final chartWidget = Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: runs.isEmpty
            ? Center(child: Text("Välj ett eller flera åk nedan."))
            : LineChart(
                transformationConfig: _enableZoom(),
                _buildChartData(runs),
              ),
      ),
    );

    if (orientation == Orientation.portrait) {
      return AspectRatio(aspectRatio: 1.3, child: chartWidget);
    } else {
      return chartWidget;
    }
  }

  FlTransformationConfig _enableZoom() {
    return FlTransformationConfig(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 10.0,

      // Set which axis can be scaled
      scaleAxis: FlScaleAxis.horizontal, // Or .vertical, or .all
    );
  }

  /// Skapar all data som fl_chart behöver.
  LineChartData _buildChartData(List<EnrichedTestRun> runs) {
    // 5. Loopa igenom varje valt åk och skapa en linje för det
    final List<LineChartBarData> lines = [];
    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      final spots = _createSpots(run.positionData);

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: run.runColor,
          barWidth: 3,
          dotData: FlDotData(show: false),
          // Ge linjen ett ID så tooltips vet vilken det är
          // (Detta är en förenkling, men fungerar för tooltips)
          // Du kan använda run.id.toString() om du vill
        ),
      );
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} km/h\n${spot.x.toStringAsFixed(0)} m',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),

      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        show: true,
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          axisNameWidget: Text("Distans (m)"),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          axisNameWidget: Text("Hastighet (km/h)"),
          drawBelowEverything: true,
        ),
      ),
      borderData: FlBorderData(show: true),

      // Skicka in listan med alla våra linjer
      lineBarsData: lines,
    );
  }

  List<FlSpot> _createSpots(List<CalculatedPosition> positions) {
    return positions
        .map((pos) => FlSpot(pos.distanceTraveled, pos.speed * 3.6))
        .toList();
  }
}
