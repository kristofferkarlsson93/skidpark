import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/compare/models/enriched_test_run.dart';
import 'package:skidpark/features/glide_testing/compare/screens/glide_test_compare_screen.dart';
import 'package:skidpark/features/glide_testing/compare/services/average_per_ski_calculator.dart';
import 'package:skidpark/features/glide_testing/compare/services/glide_test_export_service.dart';
import 'package:skidpark/features/glide_testing/compare/services/release_point_analysis.dart';
import 'package:skidpark/features/glide_testing/compare/services/run_data_processor.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/release_point_analysis/release_point_controls.dart';
import 'package:skidpark/features/glide_testing/models/decoded_test_run.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';

class CompareRunsViewModel extends ChangeNotifier {
  final TestRunRepository _testRunRepository;
  final GlideTestRepository _glideTestRepository;

  StreamSubscription? _runsSubscription;
  StreamSubscription? _glideTestSubscription;

  StoredGlideTestData? _glideTest;
  List<DecodedTestRun> _rawRuns = [];
  List<EnrichedTestRun> _testRuns = [];
  List<EnrichedTestRun> _releasePointTestRuns = [];
  List<EnrichedTestRun> _averageRunPerSki = [];
  int? _baselineRunId;

  bool _useAverageView = false;

  bool get useAverageView => _useAverageView;
  int? _highlightedRunId;

  int? get highlightedRunId => _highlightedRunId;

  final List<int> _deselectedRunIds = [];

  AnalysisPage _activeAnalysisPage = AnalysisPage.overview;

  double? _releasePoint;

  ReleasePointAnalysisMode _releasePointAnalysisMode =
      ReleasePointAnalysisMode.edit;

  ReleasePointAnalysisMode get releasePointAnalysisMode =>
      _releasePointAnalysisMode;

  double get releasePoint {
    if (_releasePoint != null) {
      return _releasePoint!;
    } else if (currentSelectedTestRuns.isNotEmpty) {
      return currentSelectedTestRuns
          .expand((r) => r.positionData)
          .reduce(
            (a, b) => a.speed > b.speed ? a : b,
          ) // Finding max speed of any run
          .distanceTraveled;
    } else {
      return 0;
    }
  }

  AnalysisPage get activeAnalysisPage => _activeAnalysisPage;

  bool get isLoading => _glideTest == null;

  List<EnrichedTestRun> get testRuns => _testRuns;

  List<EnrichedTestRun> get currentSelectedTestRuns =>
      _testRuns.where((run) => !_deselectedRunIds.contains(run.id)).toList();

  List<EnrichedTestRun> get currentSelectedReleasePointTestRuns {
    if (_useAverageView) {
      return _releasePointTestRuns;
    } else {
      return _releasePointTestRuns
          .where((run) => !_deselectedRunIds.contains(run.id))
          .toList();
    }
  }

  StoredGlideTestData? get glideTest => _glideTest;

  bool get useSensorFusion => _glideTest?.useSensorFusion ?? false;

  String get testTitle => _glideTest?.title ?? "";

  List<EnrichedTestRun> get currentDisplayRuns {
    if (useAverageView) {
      return _averageRunPerSki;
    } else {
      return currentSelectedTestRuns;
    }
  }

  bool get areAllRunsSelected {
    if (_testRuns.isEmpty) return false;
    return _testRuns.every((run) => !_deselectedRunIds.contains(run.id));
  }

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
    if (_highlightedRunId == testRun.id) _highlightedRunId = null;
    if (_deselectedRunIds.contains(testRun.id)) {
      _deselectedRunIds.remove(testRun.id);
    } else {
      _deselectedRunIds.add(testRun.id);
    }

    if (_useAverageView) {
      _recalculateAverages();
    }
    _recalculateReleasePointAnalysisIfActive();
    notifyListeners();
  }

  void toggleSelectAllRuns() {
    _highlightedRunId = null;
    if (areAllRunsSelected) {
      final allIds = _testRuns.map((r) => r.id).toList();
      _deselectedRunIds.clear();
      _deselectedRunIds.addAll(allIds);
    } else {
      _deselectedRunIds.clear();
    }

    if (_useAverageView) {
      _recalculateAverages();
    }
    _recalculateReleasePointAnalysisIfActive();
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

  void setReleasePoint(double newValue) {
    _releasePoint = newValue;
    notifyListeners();
  }

  void toggleAverageView(bool shouldUse) {
    _useAverageView = shouldUse;
    _highlightedRunId = null;
    if (shouldUse) {
      _recalculateAverages();
    }
    _recalculateReleasePointAnalysisIfActive();
    notifyListeners();
  }

  toggleHighlightedRun(int runId) {
    if (_highlightedRunId == runId) {
      _highlightedRunId = null;
    } else {
      _highlightedRunId = runId;
    }
    notifyListeners();
  }

  void triggerReleasePointAnalysis() {
    _releasePointAnalysisMode = ReleasePointAnalysisMode.view;
    _recalculateReleasePointAnalysisIfActive();

    notifyListeners();
  }

  void enterEditReleasePointAnalysisMode() {
    _releasePointAnalysisMode = ReleasePointAnalysisMode.edit;
    notifyListeners();
  }

  void updateGlideTestInfo(GlideTestCandidate updatedTest) {
    _glideTestRepository.update(_glideTest!.id, updatedTest);
  }

  void exportAllGlideTestData() async {
    final data = await _glideTestRepository.exportRelatedData(_glideTest!.id);
    GlideTestExportService.exportAndShare(data);
  }

  String calculateRunLabel(EnrichedTestRun run) {
    if (_useAverageView) {
      return "${run.skiName} (${run.runNumber} åk)";
    } else {
      return "Åk ${run.runNumber} - ${run.skiName}";
    }
  }

  void deleteCurrentGlideTest() {
    _glideTestRepository.deleteGlideTest(glideTest!.id);
  }

  void deleteTestRun(int testRunId) {
    // The Dismissible widget that performs the delete required immediate delete, else it throws an error.
    // No time to wait for the DB to refresh the stream
    _rawRuns.removeWhere((run) => run.id == testRunId);
    _testRuns.removeWhere((run) => run.id == testRunId);
    if (_highlightedRunId == testRunId) _highlightedRunId = null;
    _deselectedRunIds.remove(testRunId);
    notifyListeners();

    _testRunRepository.deleteById(testRunId);
  }

  void _listenToGlideTest(int glideTestId) {
    _glideTestSubscription = _glideTestRepository
        .watchTestById(glideTestId)
        .listen((test) {
          if (test == null) return;

          final sensorFusionChanged =
              _glideTest?.useSensorFusion != test.useSensorFusion;
          _glideTest = test;
          if (sensorFusionChanged) {
            _recalculate();
            if (_useAverageView) {
              _recalculateAverages();
            }
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
          if (_useAverageView) {
            _recalculateAverages();
          }
          _recalculateReleasePointAnalysisIfActive();
          notifyListeners();
        });
  }

  void _recalculate() {
    log("Recalculating runs. SensorFusion: $useSensorFusion");

    if (_rawRuns.isEmpty) {
      _testRuns = [];
      notifyListeners();
      return;
    }

    _baselineRunId ??= _rawRuns.map((r) => r.id).reduce(math.min);

    _testRuns = _rawRuns.map((run) {
      final int runNumber = (run.id - _baselineRunId!) + 1;
      return _calculateTestRunData(run, runNumber);
    }).toList();

    notifyListeners();
  }

  void _recalculateAverages() {
    log("Recalculating average per ski");
    _averageRunPerSki = AveragePerSkiCalculator.calculateAveragedRuns(
      currentSelectedTestRuns,
    );
  }

  void _recalculateReleasePointAnalysisIfActive() {
    if (_activeAnalysisPage == AnalysisPage.deepAnalysis &&
        _releasePointAnalysisMode == ReleasePointAnalysisMode.view) {
      final runs = _useAverageView
          ? _averageRunPerSki
          : currentSelectedTestRuns;
      _releasePointTestRuns = ReleasePointAnalysis.performAnalysis(
        testRuns: runs,
        releasePoint: releasePoint,
      );
    }
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

  //   List<EnrichedTestRun> get displayTestRuns {
  //     // 1. Hämta de valda åken
  //     final selected = currentSelectedTestRuns;
  //
  //     if (selected.length < 2) {
  //       return selected;
  //     }
  //
  //     // 3. Extrahera bara positions-listorna för att skicka till Aligner
  //     final List<List<CalculatedPosition>> rawPositionLists = selected
  //         .map((r) => r.positionData)
  //         .toList();
  //
  //     // 4. Kör Alignment-logiken
  //     final List<List<CalculatedPosition>> alignedPositionLists =
  //         RunAligner.alignMultipleRuns(runs: rawPositionLists);
  //
  //     // 5. Packa ner de nya positionerna i nya EnrichedTestRun-objekt
  //     // Vi måste skapa kopior eftersom EnrichedTestRun antagligen är immutable
  //     List<EnrichedTestRun> alignedRuns = [];
  //
  //     for (int i = 0; i < selected.length; i++) {
  //       final originalRun = selected[i];
  //       final newPositions = alignedPositionLists[i];
  //
  //       // Skapa en kopia av run-objektet men med nya positions
  //       alignedRuns.add(
  //         EnrichedTestRun(
  //           originalRun.id,
  //           originalRun.startedAt,
  //           originalRun.skiId,
  //           originalRun.glideTestId,
  //           originalRun.elapsedSeconds,
  //           originalRun.traveledDistance,
  //           // Behåll original-statistiken!
  //           originalRun.averageSpeed,
  //           // Behåll original-statistiken!
  //           originalRun.maxSpeed,
  //           // Behåll original-statistiken!
  //           originalRun.skiName,
  //           newPositions,
  //           // <--- HÄR ÄR ÄNDRINGEN
  //           originalRun.runNumber,
  //         ),
  //       );
  //     }
  //
  //     return alignedRuns;
  //   }
}
