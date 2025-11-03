import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/compare/models/calculated_position.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';
import 'package:skidpark/features/glide_testing/models/decoded_test_run.dart';

class CompareRunsViewModel extends ChangeNotifier {
  final TestRunRepository _testRunRepository;

  final StoredGlideTestData _glideTest;
  List<EnrichedTestRun> _testRuns = [];

  List<EnrichedTestRun> get testRuns => _testRuns;

  CompareRunsViewModel({
    required testRunRepository,
    required StoredGlideTestData glideTest,
  }) : _testRunRepository = testRunRepository,
       _glideTest = glideTest {
    _listenToData();
  }

  void _listenToData() {
    _testRunRepository.streamByGlideTest(_glideTest.id).listen((storedRuns) {
      _testRuns = storedRuns.map(_enrichRun).toList();
      notifyListeners();
    });
  }

  EnrichedTestRun _enrichRun(DecodedTestRun storedRun) {
    final gpsData = storedRun.gpsData;
    // Need at least 2 data points to do anything useful.
    if (gpsData.length < 2) {
      log('Got less than 2 data points, skipping data enrichment.');
      return EnrichedTestRun(
        storedRun.id,
        storedRun.startedAt,
        storedRun.skiId,
        storedRun.glideTestId,
        storedRun.elapsedSeconds,
        0,
        0,
        0,
        storedRun.skiName,
        List.empty(),
      );
    }
    var totalDistance = 0.0;
    List<CalculatedPosition> positions = [];
    for (int i = 1; i < gpsData.length; i++) {
      final previousPosition = gpsData[i - 1];
      final currentPosition = gpsData[i];

      final distanceInMeters = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      totalDistance += distanceInMeters;

      positions.add(
        CalculatedPosition(
          currentPosition.speed,
          currentPosition.timestamp,
          totalDistance,
        ),
      );
    }

    return EnrichedTestRun(
      storedRun.id,
      storedRun.startedAt,
      storedRun.skiId,
      storedRun.glideTestId,
      storedRun.elapsedSeconds,
      totalDistance,
      _calculateAverageSpeed(positions),
      _calculateMaxSpeed(positions),
      storedRun.skiName,
      positions,
    );
  }

  double _calculateAverageSpeed(List<CalculatedPosition> positions) {
    if (positions.isEmpty) return 0.0;
    final totalSpeed = positions.fold(0.0, (sum, pos) => sum + pos.speed);
    return totalSpeed / positions.length;
  }

  double _calculateMaxSpeed(List<CalculatedPosition> positions) {
    if (positions.isEmpty) return 0.0;
    return positions.map((pos) => pos.speed).reduce((a, b) => a > b ? a : b);
  }
}
