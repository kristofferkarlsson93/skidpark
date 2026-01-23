import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/compare/models/graph_line.dart';

class CompareGraph extends StatelessWidget {
  final List<GraphLine> lines;
  final double maxY;
  final Widget emptyGraphContent;
  final double? maybeVerticalLineXCoordinate;

  const CompareGraph({
    super.key,
    required this.lines,
    required this.maxY,
    required this.emptyGraphContent,
    this.maybeVerticalLineXCoordinate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 12,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: lines.isEmpty
              ? emptyGraphContent
              : LineChart(
                  transformationConfig: _enableZoom(),
                  _buildChartData(lines, theme),
                ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<GraphLine> runs, ThemeData theme) {
    final List<LineChartBarData> lines = [];
    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      final spots = run.positionData
          .map((pos) => FlSpot(pos.distanceTraveled, pos.speed * 3.6))
          .toList();

      lines.add(
        LineChartBarData(
          spots: spots,
          color: run.runColor,
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      );
    }

    ExtraLinesData? extraLines;
    if (maybeVerticalLineXCoordinate != null) {
      extraLines = ExtraLinesData(
        verticalLines: [
          VerticalLine(
            strokeCap: StrokeCap.square,
            x: maybeVerticalLineXCoordinate!,
            color: theme.colorScheme.error,
            strokeWidth: 2,
            dashArray: [5, 5],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.only(right: 5, bottom: 10, left: 5),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    }

    final graphMaxY = _calculateExtendedMaxY(maxY);
    return LineChartData(
      lineTouchData: getLineTouchData(theme),
      extraLinesData: extraLines,
      maxY: graphMaxY,
      minY: 0,
      minX: 0,
      gridData: FlGridData(show: true),
      lineBarsData: lines,
      titlesData: FlTitlesData(
        show: true,
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                value == meta.max ? "${value.toInt()} m" : value.toInt().toString(),
                style: theme.textTheme.labelSmall
              ),
            );
          }),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              // Remove last Y number (which is added "manually" to create vertical space),
              // so that we get more space for the back button.
              if (value == meta.max) {
                return const SizedBox.shrink();
              }
              // only add km/h to the top most value (visually).
              if (value == meta.max - meta.appliedInterval) {
                return Text(
                  "${value.toInt()} km/h",
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                );
              } else {
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                );
              }
            },
          ),
          drawBelowEverything: true,
        ),
      ),
      borderData: FlBorderData(show: true),
    );
  }

  LineTouchData getLineTouchData(ThemeData theme) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        fitInsideVertically: true,
        fitInsideHorizontally: true,
        getTooltipColor: (touchedSpot) => theme.cardColor,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              '${spot.y.toStringAsFixed(1)} km/h',
              TextStyle(color: spot.bar.color),
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
      scaleAxis: FlScaleAxis.horizontal,
    );
  }

  // Trying to figure out the intervals fl_chart uses, and add an extra.
  double _calculateExtendedMaxY(double highestValue) {
    if (highestValue <= 0) return 1;
    final rawStep = highestValue / 5;
    final niceStep = _intervalFriendlyNumber(rawStep);
    final roundedMax = (highestValue / niceStep).ceil() * niceStep;
    return roundedMax + niceStep;
  }

  double _intervalFriendlyNumber(double value) {
    final exponent = (log(value) / ln10).floor();
    final fraction = value / pow(10, exponent);

    double niceFraction;
    if (fraction < 1.5) {
      niceFraction = 1;
    } else if (fraction < 3) {
      niceFraction = 2;
    } else if (fraction < 7) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }

    return niceFraction * pow(10, exponent);
  }
}
