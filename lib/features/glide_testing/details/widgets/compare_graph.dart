import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';

class CompareGraph extends StatelessWidget {
  final List<EnrichedTestRun> runs;

  const CompareGraph({super.key, required this.runs});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: runs.isEmpty
            ? Center(child: Text("Välj ett eller flera åk i kontrollpanelen."))
            : LineChart(
                transformationConfig: _enableZoom(),
                _buildChartData(runs),
              ),
      ),
    );
  }

  LineChartData _buildChartData(List<EnrichedTestRun> runs) {
    final List<LineChartBarData> lines = [];
    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      final spots = run.positionData
          .map((pos) => FlSpot(pos.distanceTraveled, pos.speed * 3.6))
          .toList();

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: run.runColor,
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      );
    }

    return LineChartData(
      lineTouchData: getLineTouchData(),
      gridData: FlGridData(show: true),
      lineBarsData: lines,
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
    );
  }

  // What happens when a line is touched.
  LineTouchData getLineTouchData() {
    return LineTouchData(
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
    );
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
}
