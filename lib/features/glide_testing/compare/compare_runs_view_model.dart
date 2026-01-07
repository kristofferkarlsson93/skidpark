import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';
import 'package:skidpark/features/glide_testing/compare/screens/glide_test_compare_screen.dart';
import 'package:skidpark/features/glide_testing/compare/services/run_data_processor.dart';
import 'package:skidpark/features/glide_testing/models/decoded_test_run.dart';

class CompareRunsViewModel extends ChangeNotifier {
  final TestRunRepository _testRunRepository;
  final GlideTestRepository _glideTestRepository;

  StreamSubscription? _runsSubscription;
  StreamSubscription? _glideTestSubscription;

  StoredGlideTestData? _glideTest;
  List<DecodedTestRun> _rawRuns = [];
  List<EnrichedTestRun> _testRuns = [];
  final List<int> _deselectedRunIds = [];

  AnalysisPage _activeAnalysisPage = AnalysisPage.overview;

  AnalysisPage get activeAnalysisPage => _activeAnalysisPage;

  bool get isLoading => _glideTest == null;

  List<EnrichedTestRun> get testRuns => _testRuns;

  List<EnrichedTestRun> get currentSelectedTestRuns =>
      _testRuns.where((run) => !_deselectedRunIds.contains(run.id)).toList();

  bool get useSensorFusion => _glideTest?.useSensorFusion ?? false;

  String get testTitle => _glideTest?.title ?? "";

  CompareRunsViewModel({
    required testRunRepository,
    required GlideTestRepository glideTestRepository,
    required int glideTestId,
  }) : _testRunRepository = testRunRepository,
       _glideTestRepository = glideTestRepository {
    log("Starting CompareRunsViewModel for glideTest $glideTestId");
    _listenToGlideTest(glideTestId);
    _listenToRuns(glideTestId);
  }

  void toggleSelectedTestRun(EnrichedTestRun testRun) {
    if (_deselectedRunIds.contains(testRun.id)) {
      _deselectedRunIds.remove(testRun.id);
    } else {
      _deselectedRunIds.add(testRun.id);
    }
    notifyListeners();
  }

  bool isRunSelected(int testRunId) {
    return !_deselectedRunIds.contains(testRunId);
  }

  void setUseSensorFusion(bool shouldUse) {
    _glideTestRepository.setUseSensorFusion(_glideTest!.id, shouldUse);
    notifyListeners();
  }

  void setCurrentAnalysisPage(AnalysisPage page) {
    _activeAnalysisPage = page;
    notifyListeners();
  }

  void _listenToGlideTest(int glideTestId) {
    _glideTestSubscription = _glideTestRepository
        .watchTestById(glideTestId)
        .listen((test) {
          final sensorFusionChanged =
              _glideTest?.useSensorFusion != test.useSensorFusion;
          _glideTest = test;
          if (sensorFusionChanged) {
            _recalculate();
          } else {
            notifyListeners();
          }
        });
  }

  void _listenToRuns(int glideTestId) {
    _runsSubscription = _testRunRepository
        .streamByGlideTest(glideTestId)
        .listen((storedRuns) {
          _rawRuns = storedRuns;
          _recalculate();
          notifyListeners();
        });
  }

  void _recalculate() {
    log("Recalculating runs. SensorFusion: $useSensorFusion");
    _testRuns = _rawRuns.indexed.map(((int, DecodedTestRun) entry) {
      return _calculateTestRunData(entry.$2, entry.$1 + 1);
    }).toList();
    notifyListeners();
  }

  EnrichedTestRun _calculateTestRunData(
    DecodedTestRun storedRun,
    int runNumber,
  ) {
    // calculate max speed on raw data, to not lose speed by interpolation.
    final maxSpeed = RunDataProcessor.calculateMaxSpeed(storedRun.gpsData);
    final normalizedPositions = RunDataProcessor.processRun(
      rawPositions: storedRun.gpsData,
      accelerometerReadings: storedRun.accelerometerEvents,
      useSensorFusion: useSensorFusion,
    );
    final totalDistance = normalizedPositions.isNotEmpty
        ? normalizedPositions.last.distanceTraveled
        : 0.0;
    final averageSpeed = RunDataProcessor.calculateAverageSpeed(
      normalizedPositions,
    );
    return EnrichedTestRun(
      storedRun.id,
      storedRun.startedAt,
      storedRun.skiId,
      storedRun.glideTestId,
      storedRun.elapsedSeconds,
      totalDistance,
      _msToKmh(averageSpeed),
      _msToKmh(maxSpeed),
      storedRun.skiName,
      normalizedPositions,
      runNumber,
    );
  }

  double _msToKmh(double ms) {
    return ms * 3.6;
  }

  @override
  void dispose() {
    _runsSubscription?.cancel();
    _glideTestSubscription?.cancel();
    super.dispose();
  }
}
