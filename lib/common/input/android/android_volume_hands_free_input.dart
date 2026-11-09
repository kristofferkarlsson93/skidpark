import 'dart:async';

import '../../services/volume_press_handler.dart';
import '../hands_free_input.dart';

/// Uses the existing Android button source without taking ownership of it.
class AndroidVolumeHandsFreeInput implements HandsFreeInput {
  AndroidVolumeHandsFreeInput(this._volumeInput);

  final VolumeButtonInput _volumeInput;
  final _actions = StreamController<HandsFreeAction>.broadcast(sync: true);
  StreamSubscription<VolumeButton>? _shortPress;
  StreamSubscription<VolumeButton>? _longPress;
  HandsFreeStage _stage = HandsFreeStage.overview;

  static const inputConfiguration = HandsFreeConfiguration(
    startDelay: Duration(milliseconds: 500),
    canStopRecording: true,
  );
  static const inputInstructions = HandsFreeInstructions(
    openRun: 'Håll in volym ner för att öppna skidvalet.',
    selectSki: 'Tryck kort på volym upp eller ner för att byta skida.',
    confirmSki: 'Håll in volym ner för att bekräfta skidan och starta åket.',
    selectionLabel: 'Volym + / -',
    confirmationLabel: 'Håll in volym -',
    stopLabel: 'Volym -',
  );

  @override
  HandsFreeConfiguration get configuration => inputConfiguration;
  @override
  HandsFreeInstructions get instructions => inputInstructions;

  @override
  Stream<HandsFreeAction> get actions => _actions.stream;

  @override
  Stream<String> get errors => const Stream.empty();

  @override
  Stream<String> get guidance => const Stream.empty();

  @override
  void setStage(HandsFreeStage stage) => _stage = stage;

  @override
  void start() {
    if (_shortPress != null) return;
    _shortPress = _volumeInput.shortPressStream.listen((button) {
      if (_stage == HandsFreeStage.recording && button == VolumeButton.down) {
        _actions.add(HandsFreeAction.stopAndSave);
        return;
      }
      if (_stage != HandsFreeStage.skiSelection) return;
      _actions.add(
        button == VolumeButton.up
            ? HandsFreeAction.previous
            : HandsFreeAction.next,
      );
    });
    _longPress = _volumeInput.longPressStream.listen((button) {
      if (_stage != HandsFreeStage.recording && button == VolumeButton.down) {
        _actions.add(HandsFreeAction.confirm);
      }
    });
  }

  @override
  Future<void> stop() async {
    final shortPress = _shortPress;
    final longPress = _longPress;
    _shortPress = null;
    _longPress = null;
    await shortPress?.cancel();
    await longPress?.cancel();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _actions.close();
  }
}
