import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/glide_test/decoded_test_run.dart';

class CompareRuns extends StatefulWidget {
  const CompareRuns({super.key});

  @override
  State<CompareRuns> createState() => _CompareRunsState();
}

class _CompareRunsState extends State<CompareRuns> {
  // 1. Ny state-variabel: Håller reda på ID:n för ALLA valda åk
  final Set<int> _selectedRunIds = {};

  // En lista med färger att loopa igenom för graferna
  final List<Color> _lineColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    // Hämta hela listan med åk från providern
    final testRuns = context.watch<List<DecodedTestRun>>();

    // 2. Filtrera ut de åk som faktiskt ska visas i grafen
    final selectedRuns = testRuns
        .where((run) => _selectedRunIds.contains(run.id))
        .toList();

    return Expanded(
      child: Column(
        children: [
          // --- GRAF-SEKTION ---
          _buildChartContainer(context, selectedRuns),

          // --- LIST-SEKTION ---
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Text(
              "Välj åk att jämföra i grafen:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: testRuns.length,
              itemBuilder: (context, index) {
                final run = testRuns[index];
                // 3. Kolla om åket är valt
                final isSelected = _selectedRunIds.contains(run.id);

                return Card(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text("Åk ${run.id} (Skida: ${run.skiId})"),
                    subtitle:
                    Text("Varaktighet: ${run.elapsedSeconds} sekunder"),
                    trailing: Text("${run.gpsData.length} datapunkter"),
                    onTap: () {
                      // 4. Uppdatera state: Lägg till eller ta bort ID:t
                      setState(() {
                        if (isSelected) {
                          _selectedRunIds.remove(run.id);
                        } else {
                          _selectedRunIds.add(run.id);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Bygger en container för vår graf.
  Widget _buildChartContainer(BuildContext context, List<DecodedTestRun> runs) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: runs.isEmpty
              ? Center(child: Text("Välj ett eller flera åk nedan."))
              : LineChart(
            _buildChartData(runs), // Skicka in listan med valda åk
          ),
        ),
      ),
    );
  }

  /// Skapar all data som fl_chart behöver.
  LineChartData _buildChartData(List<DecodedTestRun> runs) {

    // 5. Loopa igenom varje valt åk och skapa en linje för det
    final List<LineChartBarData> lines = [];
    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      final spots = _createSpots(run.gpsData);
      final color = _lineColors[i % _lineColors.length]; // Loopa igenom färgerna

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: color,
          barWidth: 3,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          // Ge linjen ett ID så tooltips vet vilken det är
          // (Detta är en förenkling, men fungerar för tooltips)
          // Du kan använda run.id.toString() om du vill
        ),
      );
    }

    return LineChartData(
      // Interaktivitet
      lineTouchData: LineTouchData(
        // BUGGFIX: Bytte namn på parametern
        // getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              // Försök hitta vilket åk detta är (kräver mer logik,
              // men vi visar bara värdena just nu)
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} km/h\n${spot.x.toStringAsFixed(0)} m',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),

      // ... (Resten av din kod för grid, titlar, border är densamma)
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
        ),
      ),
      borderData: FlBorderData(show: true),

      // Skicka in listan med alla våra linjer
      lineBarsData: lines,
    );
  }

  /// Din beräkningslogik (oförändrad, den är perfekt)
  List<FlSpot> _createSpots(List<Position> positions) {
    final List<FlSpot> spots = [];
    double totalDistance = 0.0;

    if (positions.isEmpty) {
      return spots;
    }

    spots.add(FlSpot(0.0, positions.first.speed * 3.6));

    for (int i = 1; i < positions.length; i++) {
      final pos1 = positions[i - 1];
      final pos2 = positions[i];

      final distanceInMeters = Geolocator.distanceBetween(
        pos1.latitude,
        pos1.longitude,
        pos2.latitude,
        pos2.longitude,
      );

      totalDistance += distanceInMeters;

      spots.add(FlSpot(totalDistance, pos2.speed * 3.6));
    }

    return spots;
  }
}