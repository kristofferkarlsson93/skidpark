import 'dart:async';

import 'package:flutter/services.dart';

import '../hands_free_input.dart';
import 'ios_motion_gesture_detector.dart';

class IosMotionHandsFreeInput implements HandsFreeInput {
  static const _motion = EventChannel('com.skidpark.app/ios_hands_free_motion');

  final _detector = IosMotionGestureDetector();
  final _actions = StreamController<HandsFreeAction>.broadcast(sync: true);
  final _errors = StreamController<String>.broadcast(sync: true);
  final _guidance = StreamController<String>.broadcast(sync: true);
  String? _lastGuidance;
  StreamSubscription<dynamic>? _subscription;
  HandsFreeStage _stage = HandsFreeStage.overview;

  static const inputConfiguration = HandsFreeConfiguration(
    startDelay: Duration(seconds: 2),
    selectFirstSki: true,
  );
  static const inputInstructions = HandsFreeInstructions(
    openRun: 'Skaka avsiktligt för att öppna skidvalet.',
    selectSki:
        'Håll skärmen uppåt. Gör en liten, snabb tippning med vänster eller höger kant nedåt '
        'och tillbaka. '
        'Valet ändras när du återgår till ditt vanliga grepp.',
    confirmSki: 'Skaka för att bekräfta den markerade skidan.',
    selectionLabel: 'Tippa och tillbaka',
    confirmationLabel: 'Skaka',
  );

  @override
  HandsFreeConfiguration get configuration => inputConfiguration;
  @override
  HandsFreeInstructions get instructions => inputInstructions;

  @override
  Stream<HandsFreeAction> get actions => _actions.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  Stream<String> get guidance => _guidance.stream;

  @override
  void setStage(HandsFreeStage stage) {
    _stage = stage;
    _detector.setStage(stage);
    _publishGuidance();
  }

  @override
  void start() {
    if (_subscription != null) return;
    _lastGuidance = null;
    _publishGuidance();
    _subscription = _motion.receiveBroadcastStream().listen(
      (dynamic event) {
        if (_subscription == null) return;
        final values = (event as List<dynamic>).cast<num>();
        final action = _detector.add(
          IosMotionSample(
            time: Duration(microseconds: (values[0] * 1000000).round()),
            gravityX: values[1].toDouble(),
            accelerationX: values[2].toDouble(),
            accelerationY: values[3].toDouble(),
            accelerationZ: values[4].toDouble(),
            rotationRate: values[5].toDouble(),
          ),
        );
        _publishGuidance();
        if (action != null) _actions.add(action);
      },
      onError: (Object error) => _errors.add(
        'Rörelsestyrningen kunde inte startas eller avbröts. '
        'Prova igen på en fysisk iPhone.',
      ),
    );
  }

  void _publishGuidance() {
    final message = switch (_detector.progress) {
      IosTiltProgress.calibrating => 'Håll skärmen uppåt och stilla ett ögonblick för att ställa in utgångsläget.',
      IosTiltProgress.ready => 'Utgångsläget är klart. Du kan luta telefonen.',
      IosTiltProgress.tiltFurtherLeft => 'Luta lite mer åt vänster.',
      IosTiltProgress.tiltFurtherRight => 'Luta lite mer åt höger.',
      IosTiltProgress.holdLeft => 'Vänsterlutning känns av.',
      IosTiltProgress.holdRight => 'Högerlutning känns av.',
      IosTiltProgress.returnToNeutral => 'Lutningen är registrerad. Återgå till utgångsläget för att byta skida.',
      IosTiltProgress.settling => 'Återgår till utgångsläget.',
      IosTiltProgress.motionBlocked =>
        'Rörelse känns av. Återta ditt vanliga grepp och håll stilla en stund.',
    };
    if (message == _lastGuidance) return;
    _lastGuidance = message;
    _guidance.add(message);
  }

  @override
  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    _detector.reset(
      stage: _stage,
      preserveShakeCooldown: true,
      preserveCalibration: true,
    );
    await subscription?.cancel();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _actions.close();
    await _errors.close();
    await _guidance.close();
  }
}

class IosSpokenHandsFreeFeedback implements HandsFreeFeedback {
  static const _channel = MethodChannel(
    'com.skidpark.app/ios_hands_free_feedback',
  );
  int _generation = 0;

  @override
  Future<void> announce(String message) async {
    final generation = ++_generation;
    await HapticFeedback.mediumImpact();
    if (generation != _generation) return;
    await _channel.invokeMethod<void>('speak', message);
  }

  @override
  Future<void> stop() {
    _generation++;
    return _channel.invokeMethod<void>('stop');
  }
}
