import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import '../../../../common/database/database.dart';
import '../../../../common/database/repository/test_run_repository.dart';

enum RunViewState { selectSki, recordRun }

class RunRecorderViewModel extends ChangeNotifier {
  final TestRunRepository _testRunRepository;
  final DataRecorder dataRecorder;
  final int _glideTestId;

  RunRecorderViewModel({
    required TestRunRepository testRunRepository,
    required this.dataRecorder,
    required int glideTestId,
  })  : _testRunRepository = testRunRepository,
        _glideTestId = glideTestId;

  RunViewState _viewState = RunViewState.selectSki;
  RunViewState get viewState => _viewState;

  StoredSkiData? _selectedSki;
  StoredSkiData? get selectedSki => _selectedSki;

  DateTime? _startedAt;

  void selectSki(StoredSkiData ski) {
    _selectedSki = ski;
    notifyListeners();
  }

  void startRun() {
    if (_selectedSki == null) return;

    _startedAt = DateTime.now();
    _viewState = RunViewState.recordRun;
    dataRecorder.startRecording();
    notifyListeners();
  }

  Future<void> stopAndSaveRun() async {
    dataRecorder.stopRecording();
    final positions = List<Position>.from(dataRecorder.recordedPositions);
    final elapsedSeconds = dataRecorder.elapsedSeconds;

    dataRecorder.resetForNewRun();

    // Logic moved from the old _RunRecorderScreenState
    final candidate = TestRunCandidate(
      startedAt: _startedAt!,
      skiId: _selectedSki!.id,
      glideTestId: _glideTestId,
      elapsedSeconds: elapsedSeconds,
      gpsData: positions,
    );
    await _testRunRepository.storeTestRun(candidate);
  }

  /// Called when the user presses "Avbryt" during recording.
  void abortRun() {
    dataRecorder.stopRecording();
    dataRecorder.resetForNewRun();
    // Navigation will be handled by the View
  }
}