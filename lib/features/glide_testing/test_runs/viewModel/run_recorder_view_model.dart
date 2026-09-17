import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import 'package:skidpark/features/ski_management/models/ski.dart';

import '../../../../common/database/database.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/services/volume_press_handler.dart';

enum RunViewState { selectSki, recordRun }

enum RunSaveState { idle, saving, saved, failed }

class RunRecorderViewModel extends ChangeNotifier {
  final VolumeButtonInput _volumeButtonInput;
  final TestRunRepository _testRunRepository;
  final SkiRepository _skiRepository;
  final GlideTestRepository _glideTestRepository;
  final DataRecorder dataRecorder;
  final int _glideTestId;

  List<StoredSkiData> _testSkis = [];
  List<StoredSkiData> _allActiveSkis = [];
  bool _showOtherSkis = false;
  bool _isVolumeInputEnabled = true;

  RunViewState _viewState = RunViewState.selectSki;
  int _currentMarkedSkiIndex = -1;
  DateTime? _startedAt;
  StoredSkiData? _selectedSki;
  bool _isHardwareStartTriggered = false;
  bool _isDisposed = false;
  RunSaveState _saveState = RunSaveState.idle;

  bool get isHardwareStartTriggered => _isHardwareStartTriggered;
  late final StreamSubscription<VolumeButton> _shortPressSubscription;

  late final StreamSubscription<VolumeButton> _longPressSubscription;
  late final StreamSubscription<List<StoredSkiData>> _testSkisSubscription;
  late final StreamSubscription<List<StoredSkiData>> _activeSkisSubscription;

  Timer? _autoSaveTimer;
  int _autoSaveCountdownSeconds = 0;

  RunRecorderViewModel({
    required TestRunRepository testRunRepository,
    required SkiRepository skiRepository,
    required GlideTestRepository glideTestRepository,
    required VolumeButtonInput volumeButtonInput,
    required this.dataRecorder,
    required int glideTestId,
  }) : _testRunRepository = testRunRepository,
       _skiRepository = skiRepository,
       _glideTestRepository = glideTestRepository,
       _volumeButtonInput = volumeButtonInput,
       _glideTestId = glideTestId {
    _listenToSkis();
    _setupVolumeKeyListeners();
    dataRecorder.addListener(_handleDataRecorderChange);
  }

  List<StoredSkiData> get availableSkis {
    if (_showOtherSkis || _testSkis.isEmpty) return otherSkis;
    return _testSkis;
  }

  List<StoredSkiData> get otherSkis {
    final testSkiIds = _testSkis.map((ski) => ski.id).toSet();
    return _allActiveSkis.where((ski) => !testSkiIds.contains(ski.id)).toList();
  }

  bool get isShowingOtherSkis => _showOtherSkis || _testSkis.isEmpty;

  bool get canChooseOtherSki => !_showOtherSkis && otherSkis.isNotEmpty;

  bool get canReturnToTestSkis => _showOtherSkis && _testSkis.isNotEmpty;

  RunViewState get viewState => _viewState;

  StoredSkiData? get selectedSki => _selectedSki;

  int get markedSkiIndex => _currentMarkedSkiIndex;

  int get autoSaveCountdownSeconds => _autoSaveCountdownSeconds;

  RunSaveState get saveState => _saveState;

  bool get isSaving => _saveState == RunSaveState.saving;

  Future<void> selectSki(StoredSkiData inputSki) async {
    if (!_testSkis.any((ski) => ski.id == inputSki.id)) {
      await _glideTestRepository.addSkiToTest(_glideTestId, inputSki.id);
      // Keep the selection stable while the database stream catches up.
      if (!_testSkis.any((ski) => ski.id == inputSki.id)) {
        _testSkis = [..._testSkis, inputSki];
      }
      _showOtherSkis = false;
    }
    _selectedSki = inputSki;
    _currentMarkedSkiIndex = availableSkis.indexWhere(
      (ski) => ski.id == inputSki.id,
    );
    notifyListeners();
  }

  Future<void> createAndSelectSki(SkiCandidate candidate) async {
    final skiId = await _skiRepository.save(candidate);
    final activeSkis = await _skiRepository.getActiveSkis();
    final createdSki = activeSkis.singleWhere((ski) => ski.id == skiId);

    _allActiveSkis = activeSkis;
    await selectSki(createdSki);
  }

  void suspendVolumeInput() {
    _isVolumeInputEnabled = false;
  }

  void resumeVolumeInput() {
    _isVolumeInputEnabled = true;
  }

  void showOtherSkis() {
    _showOtherSkis = true;
    _selectedSki = null;
    _currentMarkedSkiIndex = -1;
    notifyListeners();
  }

  void showTestSkis() {
    _showOtherSkis = false;
    _selectedSki = null;
    _currentMarkedSkiIndex = -1;
    notifyListeners();
  }

  void startRun() {
    if (_selectedSki == null || _viewState != RunViewState.selectSki) return;

    _startedAt = DateTime.now();
    _viewState = RunViewState.recordRun;
    _saveState = RunSaveState.idle;
    dataRecorder.startRecording();
    notifyListeners();
  }

  Future<void> stopAndSaveRun() async {
    if (_saveState == RunSaveState.saving || _saveState == RunSaveState.saved) {
      return;
    }

    final startedAt = _startedAt;
    final selectedSki = _selectedSki;
    if (startedAt == null || selectedSki == null) {
      log('Ignoring save because no run has been started.');
      return;
    }

    _cancelAutoSave();
    dataRecorder.stopRecording();
    final positions = List<Position>.from(dataRecorder.recordedPositions);
    final elapsedSeconds = dataRecorder.elapsedSeconds;
    final accelerometerEvents = List<RawAccelerometerEvent>.from(
      dataRecorder.recordedAccelerometerEvents,
    );

    log(
      "Stop and save: ${accelerometerEvents.length} accel events and ${positions.length} GPS positions",
    );

    final candidate = TestRunCandidate(
      startedAt: startedAt,
      skiId: selectedSki.id,
      glideTestId: _glideTestId,
      elapsedSeconds: elapsedSeconds,
      gpsData: positions,
      accelerometerEvents: accelerometerEvents,
    );

    _saveState = RunSaveState.saving;
    notifyListeners();

    try {
      await _testRunRepository.storeTestRun(candidate);
      if (_isDisposed) return;

      dataRecorder.resetForNewRun();
      _currentMarkedSkiIndex = -1;
      _saveState = RunSaveState.saved;
      notifyListeners();
    } catch (error, stackTrace) {
      log('Failed to save test run', error: error, stackTrace: stackTrace);
      if (_isDisposed) return;

      _saveState = RunSaveState.failed;
      notifyListeners();
    }
  }

  void abortRun() {
    _cancelAutoSave();
    dataRecorder.stopRecording();
    dataRecorder.resetForNewRun();
    _currentMarkedSkiIndex = -1;
  }

  void _setupVolumeKeyListeners() {
    _shortPressSubscription = _volumeButtonInput.shortPressStream.listen((
      VolumeButton buttonId,
    ) async {
      if (!_isVolumeInputEnabled) return;
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

    _longPressSubscription = _volumeButtonInput.longPressStream.listen((
      VolumeButton volumeButton,
    ) async {
      if (!_isVolumeInputEnabled) return;
      log("Long press $volumeButton");
      if (viewState == RunViewState.selectSki) {
        if (volumeButton == VolumeButton.down && _currentMarkedSkiIndex >= 0) {
          _isHardwareStartTriggered = true;
          notifyListeners();
          final selectedSki = availableSkis[_currentMarkedSkiIndex];
          await selectSki(selectedSki);
          await Future.delayed(const Duration(milliseconds: 500));
          if (_isDisposed) return;
          startRun();
          _isHardwareStartTriggered = false;
        }
      }
    });
  }

  void handleSkiSelectVolumeNavigation(VolumeButton buttonId) {
    if (availableSkis.isEmpty) return;
    // If we navigate with hardware, we need to make sure to reset whatever we did with touch before
    _selectedSki = null;
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
    _testSkisSubscription = _glideTestRepository
        .watchSkisForTest(_glideTestId)
        .listen((storedSkis) {
          _testSkis = storedSkis;
          log("test skis: ${storedSkis.length}");
          notifyListeners();
        });
    _activeSkisSubscription = _skiRepository.watchActiveSkis().listen((
      storedSkis,
    ) {
      _allActiveSkis = storedSkis;
      log("active skis: ${storedSkis.length}");
      notifyListeners();
    });
  }

  void _handleDataRecorderChange() {
    if (viewState != RunViewState.recordRun ||
        _saveState != RunSaveState.idle) {
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
    _isDisposed = true;
    _shortPressSubscription.cancel();
    _longPressSubscription.cancel();
    _testSkisSubscription.cancel();
    _activeSkisSubscription.cancel();
    _autoSaveTimer?.cancel();
    dataRecorder.removeListener(_handleDataRecorderChange);
    super.dispose();
  }
}
