import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import '../../../../common/database/database.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/services/VolumePressHandler.dart';

enum RunViewState { selectSki, recordRun }

class RunRecorderViewModel extends ChangeNotifier {
  final VolumePressHandler _volumePressHandler = VolumePressHandler();
  final TestRunRepository _testRunRepository;
  final SkiRepository _skiRepository;
  final DataRecorder dataRecorder;
  final int _glideTestId;
  final VoidCallback _onStopAndSaveCallback;

  List<StoredSkiData> _availableSkis = [];

  RunViewState _viewState = RunViewState.selectSki;
  int _currentMarkedSkiIndex = -1;
  DateTime? _startedAt;
  StoredSkiData? _selectedSki;
  late final StreamSubscription<VolumeButton> _shortPressSubscription;

  late final StreamSubscription<VolumeButton> _longPressSubscription;

  Timer? _autoSaveTimer;
  int _autoSaveCountdownSeconds = 0;

  RunRecorderViewModel({
    required TestRunRepository testRunRepository,
    required SkiRepository skiRepository,
    required this.dataRecorder,
    required int glideTestId,
    required VoidCallback onStopAndSaveCallback,
  }) : _testRunRepository = testRunRepository,
       _skiRepository = skiRepository,
       _glideTestId = glideTestId,
       _onStopAndSaveCallback = onStopAndSaveCallback {
    _listenToSkis();
    _setupVolumeKeyListeners();
    dataRecorder.addListener(_handleDataRecorderChange);
  }

  List<StoredSkiData> get availableSkis => _availableSkis;

  RunViewState get viewState => _viewState;

  StoredSkiData? get selectedSki => _selectedSki;

  int get markedSkiIndex => _currentMarkedSkiIndex;

  int get autoSaveCountdownSeconds => _autoSaveCountdownSeconds;

  void selectSki(StoredSkiData inputSki) {
    _selectedSki = inputSki;
    _currentMarkedSkiIndex = _availableSkis.indexWhere(
      (ski) => ski.id == inputSki.id,
    );
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
    final accelerometerEvents = List<RawAccelerometerEvent>.from(
      dataRecorder.recordedAccelerometerEvents,
    );

    dataRecorder.resetForNewRun();
    _currentMarkedSkiIndex = -1;

    log(
      "Stop and save: ${accelerometerEvents.length} accel events and ${positions.length} GPS positions",
    );

    final candidate = TestRunCandidate(
      startedAt: _startedAt!,
      skiId: _selectedSki!.id,
      glideTestId: _glideTestId,
      elapsedSeconds: elapsedSeconds,
      gpsData: positions,
      accelerometerEvents: accelerometerEvents,
    );
    await _testRunRepository.storeTestRun(candidate);
    _onStopAndSaveCallback();
  }

  void abortRun() {
    _cancelAutoSave();
    dataRecorder.stopRecording();
    dataRecorder.resetForNewRun();
    _currentMarkedSkiIndex = -1;
  }

  void _setupVolumeKeyListeners() {
    _shortPressSubscription = _volumePressHandler.shortPressStream.listen((
      VolumeButton buttonId,
    ) async {
      log("Pressed $buttonId");
      if (viewState == RunViewState.recordRun) {
        if (buttonId == VolumeButton.down) {
          await stopAndSaveRun();
        }
      } else {
        handleSkiSelectVolumeNavigation(buttonId);
        notifyListeners();
      }
    });

    _longPressSubscription = _volumePressHandler.longPressStream.listen((
      VolumeButton volumeButton,
    ) async {
      log("Long press ${volumeButton}");
      if (viewState == RunViewState.selectSki) {
        if (volumeButton == VolumeButton.down && _currentMarkedSkiIndex >= 0) {
          final selectedSki = _availableSkis[_currentMarkedSkiIndex];
          selectSki(selectedSki);
          await Future.delayed(const Duration(milliseconds: 500));
          startRun();
        }
      }
    });
  }

  void handleSkiSelectVolumeNavigation(VolumeButton buttonId) {
    if (buttonId == VolumeButton.up) {
      // If is start value (-1) or zero - go to last list item.
      if (_currentMarkedSkiIndex <= 0) {
        _currentMarkedSkiIndex = availableSkis.length - 1;
      } else {
        _currentMarkedSkiIndex -= 1;
      }
    } else {
      if (_currentMarkedSkiIndex == availableSkis.length - 1) {
        _currentMarkedSkiIndex = 0;
      } else {
        _currentMarkedSkiIndex += 1;
      }
    }
  }

  void _listenToSkis() {
    _skiRepository.watchActiveSkis().listen((List<StoredSkiData> storedSkis) {
      _availableSkis = storedSkis;
      log("skis: ${storedSkis.length}");
      notifyListeners();
    });
  }

  void _handleDataRecorderChange() {
    if (viewState != RunViewState.recordRun) {
      _cancelAutoSave();
      return;
    }

    if (dataRecorder.recordedPositions.length >= 20) {
      final last2Positions = dataRecorder.recordedPositions.sublist(
        dataRecorder.recordedPositions.length - 2,
      );
      // 0.15 ms ~= 0.54 kmh.
      final hasStopped = last2Positions.every((pos) => pos.speed <= 0.15);
      if (hasStopped) {
        _startAutoSaveCountdown();
      } else {
        _cancelAutoSave();
      }
    }
  }

  void _startAutoSaveCountdown() {
    if (_autoSaveTimer != null) return;

    _autoSaveCountdownSeconds = 3;
    notifyListeners();

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _autoSaveCountdownSeconds--;
      notifyListeners();

      if (_autoSaveCountdownSeconds <= 0) {
        timer.cancel();
        log("Auto-saving run after stop detection.");
        await stopAndSaveRun();
      }
    });
  }

  void _cancelAutoSave() {
    if (_autoSaveTimer != null) {
      _autoSaveTimer!.cancel();
      _autoSaveTimer = null;
      _autoSaveCountdownSeconds = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    log("Disposing RunRecorderViewModel");
    _shortPressSubscription.cancel();
    _longPressSubscription.cancel();
    _volumePressHandler.dispose();
    _autoSaveTimer?.cancel();
    dataRecorder.removeListener(_handleDataRecorderChange);
    super.dispose();
  }
}
