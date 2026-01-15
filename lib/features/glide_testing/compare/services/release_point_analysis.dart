import 'dart:math' as math;
import '../models/calculated_position.dart';
import '../models/enriched_test_run.dart';

class ReleasePointAnalysis {
  // Vi matchar trenden i ett fönster CENTRERAT runt release point.
  // Detta fångar både "hur vi kom hit" (acceleration) och "vart vi är på väg" (glid).
  // Totalt 10m fönster (-5m till +5m).
  static const double _lookBackDistance = 5.0;
  static const double _lookAheadDistance = 5.0;

  // Striktare brus-golv. Allt under ca 0.8 km/h räknas som stillastående.
  // Garanterar att grafen landar på 0 i slutet.
  static const double _noiseFloor = 0.22;

  // Vi använder ett litet fönster (3m) för att bestämma den visuella startnivån (Ankaret)
  static const double _anchorWindowSize = 3.0;

  static List<EnrichedTestRun> performAnalysis({
    required List<EnrichedTestRun> testRuns,
    required double releasePoint,
  }) {
    if (testRuns.isEmpty) return [];

    // ---------------------------------------------------------
    // STEG 1: Analysera segmentet (-5m till +5m) för trendmatchning
    // ---------------------------------------------------------
    final Map<int, double> segmentAverages = {};
    double maxStartAnchorFound = 0.0;

    for (var run in testRuns) {
      // SÄKERHET: Se till att vi inte tittar bakom startlinjen (negativ distans)
      double startWindow = releasePoint - _lookBackDistance;
      if (startWindow < 0) startWindow = 0;

      double endWindow = releasePoint + _lookAheadDistance;

      // Hämta snittfart för hela fönstret
      final double? avgSpeed = _getAverageSpeedInSegment(
        run.positionData,
        startWindow,
        endWindow,
      );

      if (avgSpeed != null) segmentAverages[run.id] = avgSpeed;

      // Hitta ett robust startvärde (snitt 0-3m efter release) för den visuella nivån
      final double? startAnchor = _getAverageSpeedInSegment(
        run.positionData,
        releasePoint,
        releasePoint + _anchorWindowSize,
      );

      if (startAnchor != null && startAnchor > maxStartAnchorFound) {
        maxStartAnchorFound = startAnchor;
      }
    }

    if (segmentAverages.isEmpty) return [];

    // Bestäm "Målsnittet" (den skida som hade högst energi i fönstret)
    final double targetSegmentAvg = segmentAverages.values.reduce(math.max);

    List<EnrichedTestRun> analyzedRuns = [];

    // ---------------------------------------------------------
    // STEG 2: Skapa de nya kurvorna
    // ---------------------------------------------------------
    for (var run in testRuns) {
      if (!segmentAverages.containsKey(run.id)) continue;

      final CalculatedPosition? firstPoint = run.positionData
          .cast<CalculatedPosition?>()
          .firstWhere(
            (p) => p != null && p.distanceTraveled >= releasePoint,
            orElse: () => null,
          );

      if (firstPoint == null) continue;

      final double mySegmentAvg = segmentAverages[run.id]!;
      if (mySegmentAvg < 0.1) continue;

      // A. Beräkna Scaling Factor (Ren Fysik-multiplikation)
      final double scalingFactor = targetSegmentAvg / mySegmentAvg;

      // B. Beräkna Fading Correction (Visuell start-limning)
      // Vi använder vårt robusta ankare (3m snitt) för att bestämma startnivån
      final double? myStartAnchor = _getAverageSpeedInSegment(
        run.positionData,
        releasePoint,
        releasePoint + _anchorWindowSize,
      );

      final double effectiveStartSpeed = myStartAnchor ?? firstPoint.speed;
      final double projectedStartLevel = effectiveStartSpeed * scalingFactor;

      // Skillnaden mellan "Taket" (maxStartAnchorFound) och min projicerade start
      final double cosmeticCorrection =
          maxStartAnchorFound - projectedStartLevel;

      final double anchorDistance = firstPoint.distanceTraveled;
      final double anchorSpeed = firstPoint.speed;

      final List<CalculatedPosition> newPositions = [];

      for (var p in run.positionData) {
        if (p.distanceTraveled < releasePoint) continue;

        // --- STRIKT NOLL-KONTROLL ---
        // Om rådatan är brus/noll, tvinga till noll direkt.
        if (p.speed < _noiseFloor) {
          newPositions.add(
            CalculatedPosition(
              0.0,
              p.timestamp,
              p.distanceTraveled - anchorDistance,
            ),
          );
          continue;
        }

        // 1. Fysik-skalning
        double scaledBaseSpeed = p.speed * scalingFactor;

        // 2. Fading Correction
        // Fasa ut korrigeringen baserat på farten.
        // (Ratio går mot 0 när farten går mot 0)
        double speedRatio = anchorSpeed > 0 ? (p.speed / anchorSpeed) : 0.0;
        if (speedRatio > 1.0) speedRatio = 1.0;
        if (speedRatio < 0.0) speedRatio = 0.0;

        double currentCorrection = cosmeticCorrection * speedRatio;

        // 3. Resultat
        double finalSpeed = scaledBaseSpeed + currentCorrection;

        // Sista säkerhetskoll (fysikalisk orimlighet med negativ fart)
        if (finalSpeed < 0) finalSpeed = 0.0;

        newPositions.add(
          CalculatedPosition(
            finalSpeed,
            p.timestamp,
            p.distanceTraveled - anchorDistance, // Nollställ X-axeln
          ),
        );
      }

      if (newPositions.isEmpty) continue;

      // Inget smoothing-steg här. Vi kör på ren, ärlig (men skalad) data.

      // Stats calculation
      final double newDistance = newPositions.last.distanceTraveled;
      final double newMaxSpeed = newPositions
          .map((p) => p.speed)
          .reduce(math.max);
      final double newAvgSpeed =
          newPositions.map((p) => p.speed).fold(0.0, (a, b) => a + b) /
          newPositions.length;

      var recalculatedRun = run.simpleCopy(
        _msToKmh(newAvgSpeed),
        _msToKmh(newMaxSpeed),
        newDistance,
        newPositions,
      );
      analyzedRuns.add(recalculatedRun);
    }

    return analyzedRuns;
  }

  // Helpers
  static double? _getAverageSpeedInSegment(
    List<CalculatedPosition> positions,
    double startDist,
    double endDist,
  ) {
    final pointsInWindow = positions
        .where(
          (p) =>
              p.distanceTraveled >= startDist && p.distanceTraveled <= endDist,
        )
        .toList();
    if (pointsInWindow.isEmpty) return null;
    final double totalSpeed = pointsInWindow.fold(
      0.0,
      (sum, p) => sum + p.speed,
    );
    return totalSpeed / pointsInWindow.length;
  }

  static double _msToKmh(double ms) => ms * 3.6;
}
