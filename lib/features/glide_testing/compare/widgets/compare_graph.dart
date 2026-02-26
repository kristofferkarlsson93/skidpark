import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skidpark/features/glide_testing/compare/models/graph_line.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/side_scrolled_run_legend.dart';

class CompareGraph extends StatelessWidget {
  final List<GraphLine> lines;
  final double maxY;
  final Widget emptyGraphContent;
  final double? maybeVerticalLineXCoordinate;
  final bool isFullscreen;
  final int? highlightedLineId;

  const CompareGraph({
    super.key,
    required this.lines,
    required this.maxY,
    required this.emptyGraphContent,
    this.maybeVerticalLineXCoordinate,
    this.highlightedLineId,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget graphContent = lines.isEmpty
        ? emptyGraphContent
        : LineChart(
            transformationConfig: _enableZoom(),
            duration: const Duration(milliseconds: 0),
            _buildChartData(lines, theme),
          );

    return Card(
      elevation: isFullscreen ? 0 : 12,
      margin: isFullscreen ? EdgeInsets.zero : null,
      color: isFullscreen ? theme.scaffoldBackgroundColor : null,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Padding(
              padding: isFullscreen
                  ? const EdgeInsets.all(8.0)
                  : const EdgeInsets.all(16.0),
              child: graphContent,
            ),
            if (!isFullscreen && lines.isNotEmpty)
              Positioned(
                right: 8,
                // Try to calculate where it would fit in the left hand toolbar.. Dirty.
                // Basically - the toolbar, space, first icon, second icon, space
                top: kToolbarHeight + 8 + (20 * 2) + (48 * 2) + 8,
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen_outlined,
                      color: Colors.white,
                    ),
                    tooltip: "Helskärm",
                    onPressed: () => _openFullScreen(context),
                  ),
                ),
              ),
            if (isFullscreen)
              Positioned(
                right: 0,
                top: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha((0.5 * 255).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_fullscreen,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    tooltip: "Stäng helskärm",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            if (isFullscreen && lines.isNotEmpty)
              Positioned(
                top: 8,
                right: 60,
                left: 40,
                child: SideScrolledRunLegend(lines: lines),
              ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _LandscapeGraphPage(
          child: CompareGraph(
            lines: lines,
            maxY: maxY,
            emptyGraphContent: emptyGraphContent,
            maybeVerticalLineXCoordinate: maybeVerticalLineXCoordinate,
            highlightedLineId: highlightedLineId,
            isFullscreen: true,
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<GraphLine> originalRuns, ThemeData theme) {
    if (originalRuns.isEmpty) return LineChartData();

    // Sort the highlighed line last, to draw it on top of all lines.
    final runs = List<GraphLine>.from(originalRuns);
    if (highlightedLineId != null) {
      runs.sort((a, b) {
        if (a.id == highlightedLineId) return 1;
        if (b.id == highlightedLineId) return -1;
        return 0;
      });
    }

    final List<LineChartBarData> lines = [];
    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      final spots = run.positionData
          .map((pos) => FlSpot(pos.distanceTraveled, pos.speed * 3.6))
          .toList();

      final bool isHighlighted = highlightedLineId == run.id;
      final bool isFaded = highlightedLineId != null && !isHighlighted;

      lines.add(
        LineChartBarData(
          spots: spots,
          color: isFaded ? run.runColor.withAlpha(70) : run.runColor,
          barWidth: isHighlighted ? 4 : (isFaded ? 2 : 3),
          isStepLineChart: false,
          dotData: const FlDotData(show: false),
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
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  value == meta.max
                      ? "${value.toInt()} m"
                      : value.toInt().toString(),
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
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

class _LandscapeGraphPage extends StatefulWidget {
  final Widget child;

  const _LandscapeGraphPage({required this.child});

  @override
  State<_LandscapeGraphPage> createState() => _LandscapeGraphPageState();
}

class _LandscapeGraphPageState extends State<_LandscapeGraphPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: widget.child));
  }
}
