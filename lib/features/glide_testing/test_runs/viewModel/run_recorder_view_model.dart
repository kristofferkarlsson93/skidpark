import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_barometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gps_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gyroscope_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_rotation_vector_event.dart';
import 'package:skidpark/features/ski_management/models/ski.dart';

import '../../../../common/database/database.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/input/hands_free_controller.dart';
import '../../../../common/input/hands_free_input.dart';

enum RunViewState { selectSki, recordRun }

enum RunSaveState { idle, saving, saved, failed }

class RunRecorderViewModel extends ChangeNotifier {
  final HandsFreeController _controls;
  final TestRunRepository _testRunRepository;
  final SkiRepository _skiRepository;
  final GlideTestRepository _glideTestRepository;
  final DataRecorder dataRecorder;
  final int _glideTestId;

  List<StoredSkiData> _testSkis = [];
  List<StoredSkiData> _allActiveSkis = [];
  bool _testSkisLoaded = false;
  bool _activeSkisLoaded = false;
  bool _showOtherSkis = false;
  bool _isInputEnabled = true;
  bool _routeVisible = false;
  String? _inputError;
  String? _inputGuidance;
  Timer? _startTimer;
  int _startGeneration = 0;
  int _startCountdownSeconds = 0;

  RunViewState _viewState = RunViewState.selectSki;
  int _currentMarkedSkiIndex = -1;
  DateTime? _startedAt;
  StoredSkiData? _selectedSki;
  bool _isHardwareStartTriggered = false;
  bool _isDisposed = false;
  RunSaveState _saveState = RunSaveState.idle;

  bool get isHardwareStartTriggered => _isHardwareStartTriggered;
  late final StreamSubscription<List<StoredSkiData>> _testSkisSubscription;
  late final StreamSubscription<List<StoredSkiData>> _activeSkisSubscription;

  Timer? _autoSaveTimer;
  int _autoSaveCountdownSeconds = 0;

  RunRecorderViewModel({
    required TestRunRepository testRunRepository,
    required SkiRepository skiRepository,
    required GlideTestRepository glideTestRepository,
    required HandsFreeController controls,
    required this.dataRecorder,
    required int glideTestId,
  }) : _testRunRepository = testRunRepository,
       _skiRepository = skiRepository,
       _glideTestRepository = glideTestRepository,
       _controls = controls,
       _glideTestId = glideTestId {
    _listenToSkis();
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

  HandsFreeInstructions get inputInstructions => _controls.instructions;
  bool get isStarting => _isHardwareStartTriggered;
  int get startCountdownSeconds => _startCountdownSeconds;
  String? get inputError => _inputError;
  String? get inputGuidance => _inputGuidance;
  bool get inputEnabled =>
      _isInputEnabled &&
      !isStarting &&
      _inputError == null &&
      !isSaving &&
      (viewState == RunViewState.selectSki ||
          _controls.configuration.canStopRecording);

  RunSaveState get saveState => _saveState;

  bool get isSaving => _saveState == RunSaveState.saving;

  Future<void> selectSki(StoredSkiData inputSki) async {
    if (isStarting) return;
    await _selectSki(inputSki);
  }

  Future<void> _selectSki(StoredSkiData inputSki) async {
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

  void suspendHandsFreeInput() {
    _isInputEnabled = false;
    cancelPendingStart();
    notifyListeners();
  }

  void resumeHandsFreeInput() {
    _isInputEnabled = true;
    notifyListeners();
  }

  void setRouteVisible(bool visible) {
    _routeVisible = visible;
    if (!visible) cancelPendingStart();
    if (visible &&
        _currentMarkedSkiIndex >= 0 &&
        _currentMarkedSkiIndex < availableSkis.length &&
        viewState == RunViewState.selectSki) {
      _announce(availableSkis[_currentMarkedSkiIndex].name);
    }
  }

  void updateInputGuidance(String message) {
    _inputGuidance = message;
    notifyListeners();
  }

  void handleInputError(String message) {
    _inputError = message;
    cancelPendingStart();
    notifyListeners();
  }

  void showOtherSkis() {
    if (isStarting) return;
    _showOtherSkis = true;
    _selectedSki = null;
    _currentMarkedSkiIndex = -1;
    _selectInitialSki();
    notifyListeners();
  }

  void showTestSkis() {
    if (isStarting) return;
    _showOtherSkis = false;
    _selectedSki = null;
    _currentMarkedSkiIndex = -1;
    _selectInitialSki();
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
    final gpsEvents = List<RawGpsEvent>.from(dataRecorder.recordedGpsEvents);
    final elapsedSeconds = dataRecorder.elapsedSeconds;
    final accelerometerEvents = List<RawAccelerometerEvent>.from(
      dataRecorder.recordedAccelerometerEvents,
    );
    final gyroscopeEvents = List<RawGyroscopeEvent>.from(
      dataRecorder.recordedGyroscopeEvents,
    );
    final barometerEvents = List<RawBarometerEvent>.from(
      dataRecorder.recordedBarometerEvents,
    );
    final rotationVectorEvents = List<RawRotationVectorEvent>.from(
      dataRecorder.recordedRotationVectorEvents,
    );
    final sensorMetadata = dataRecorder.recordedSensorMetadata;

    log(
      'Stop and save: ${gpsEvents.length} GPS, '
      '${accelerometerEvents.length} accelerometer, '
      '${gyroscopeEvents.length} gyroscope, '
      '${barometerEvents.length} barometer and '
      '${rotationVectorEvents.length} rotation vector samples',
    );

    final candidate = TestRunCandidate(
      startedAt: startedAt,
      skiId: selectedSki.id,
      glideTestId: _glideTestId,
      elapsedSeconds: elapsedSeconds,
      gpsEvents: gpsEvents,
      accelerometerEvents: accelerometerEvents,
      gyroscopeEvents: gyroscopeEvents,
      barometerEvents: barometerEvents,
      rotationVectorEvents: rotationVectorEvents,
      sensorMetadata: sensorMetadata,
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
    cancelPendingStart();
    _cancelAutoSave();
    dataRecorder.stopRecording();
    dataRecorder.resetForNewRun();
    _currentMarkedSkiIndex = -1;
  }

  void handleHandsFreeAction(HandsFreeAction action) {
    if (!inputEnabled || !_routeVisible) return;
    if (viewState == RunViewState.recordRun) {
      if (action == HandsFreeAction.stopAndSave) unawaited(stopAndSaveRun());
      return;
    }
    switch (action) {
      case HandsFreeAction.previous:
        _moveSelection(-1);
      case HandsFreeAction.next:
        _moveSelection(1);
      case HandsFreeAction.confirm:
        unawaited(requestStart(fromHardware: true));
      case HandsFreeAction.stopAndSave:
        break;
    }
  }

  void _moveSelection(int offset) {
    if (availableSkis.isEmpty) return;
    _selectedSki = null;
    _currentMarkedSkiIndex = _currentMarkedSkiIndex < 0
        ? (offset > 0 ? 0 : availableSkis.length - 1)
        : (_currentMarkedSkiIndex + offset) % availableSkis.length;
    notifyListeners();
    _announce(availableSkis[_currentMarkedSkiIndex].name);
  }

  Future<void> requestStart({bool fromHardware = false}) async {
    if (isStarting || !_routeVisible || viewState != RunViewState.selectSki) {
      return;
    }
    final ski =
        _selectedSki ??
        (_currentMarkedSkiIndex >= 0 &&
                _currentMarkedSkiIndex < availableSkis.length
            ? availableSkis[_currentMarkedSkiIndex]
            : null);
    if (ski == null) return;
    final generation = ++_startGeneration;
    _isHardwareStartTriggered = true;
    notifyListeners();
    try {
      await _selectSki(ski);
      await _controls.pause();
      if (!_canFinishStart(generation)) return;
      final delay = fromHardware
          ? _controls.configuration.startDelay
          : Duration.zero;
      _startCountdownSeconds = delay.inSeconds;
      if (_startCountdownSeconds > 0) {
        _announce(
          '${ski.name}. Inspelning startar om $_startCountdownSeconds sekunder.',
        );
        _startTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_canFinishStart(generation)) {
            timer.cancel();
            return;
          }
          _startCountdownSeconds--;
          if (_startCountdownSeconds == 0) {
            timer.cancel();
            _finishStart(generation);
          } else {
            notifyListeners();
          }
        });
      } else {
        _startTimer = Timer(delay, () => _finishStart(generation));
      }
      notifyListeners();
    } catch (error) {
      if (_isDisposed || generation != _startGeneration) return;
      handleInputError(
        'Kunde inte förbereda starten. Prova igen med skärmknappen.',
      );
    }
  }

  bool _canFinishStart(int generation) =>
      !_isDisposed &&
      _routeVisible &&
      generation == _startGeneration &&
      isStarting;

  void _finishStart(int generation) {
    if (!_canFinishStart(generation)) return;
    _isHardwareStartTriggered = false;
    _startCountdownSeconds = 0;
    startRun();
    _announce('Inspelning startad.');
  }

  void cancelPendingStart() {
    _startGeneration++;
    _startTimer?.cancel();
    if (!isStarting) return;
    _isHardwareStartTriggered = false;
    _startCountdownSeconds = 0;
    unawaited(_controls.feedback.stop());
    notifyListeners();
  }

  void _announce(String message) {
    if (!_routeVisible || _isDisposed) return;
    unawaited(
      _controls.feedback.announce(message).catchError((Object error) {}),
    );
  }

  void _selectInitialSki() {
    if (!_testSkisLoaded ||
        !_activeSkisLoaded ||
        !_controls.configuration.selectFirstSki ||
        _currentMarkedSkiIndex >= 0 ||
        isStarting ||
        availableSkis.isEmpty) {
      return;
    }
    _currentMarkedSkiIndex = 0;
    _announce(availableSkis.first.name);
  }

  void _listenToSkis() {
    _testSkisSubscription = _glideTestRepository
        .watchSkisForTest(_glideTestId)
        .listen((storedSkis) {
          _testSkis = storedSkis;
          _testSkisLoaded = true;
          _selectInitialSki();
          log("test skis: ${storedSkis.length}");
          notifyListeners();
        });
    _activeSkisSubscription = _skiRepository.watchActiveSkis().listen((
      storedSkis,
    ) {
      _allActiveSkis = storedSkis;
      _activeSkisLoaded = true;
      _selectInitialSki();
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

    final positions = dataRecorder.recordedPositions;
    if (positions.length >= 20) {
      final last2Positions = positions.sublist(positions.length - 2);
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
    _startGeneration++;
    _startTimer?.cancel();
    _testSkisSubscription.cancel();
    _activeSkisSubscription.cancel();
    _autoSaveTimer?.cancel();
    dataRecorder.removeListener(_handleDataRecorderChange);
    super.dispose();
  }
}
