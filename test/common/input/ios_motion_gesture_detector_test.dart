import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/input/hands_free_input.dart';
import 'package:skidpark/common/input/ios/ios_motion_gesture_detector.dart';

void main() {
  test(
    'first shake after recording does not require new observed stillness',
    () {
      final trial = _MotionTrial();
      trial.hold(600);
      trial.shake();
      trial.detector.reset(
        stage: HandsFreeStage.overview,
        preserveShakeCooldown: true,
        preserveCalibration: true,
      );
      trial.time += const Duration(seconds: 30);
      trial.shake();
      expect(trial.actions, [HandsFreeAction.confirm, HandsFreeAction.confirm]);
    },
  );

  test(
    'short source restart preserves the grip without calibrating mid-tilt',
    () {
      final trial = _MotionTrial(stage: HandsFreeStage.overview);
      trial.hold(600);
      trial.detector.reset(
        stage: HandsFreeStage.overview,
        preserveShakeCooldown: true,
        preserveCalibration: true,
      );
      trial.detector.setStage(HandsFreeStage.skiSelection);
      trial.time += const Duration(milliseconds: 400);
      trial.tiltTo(18, milliseconds: 80);
      trial.tiltTo(0, milliseconds: 80);
      trial.hold(40);
      expect(trial.actions, [HandsFreeAction.next]);
    },
  );

  test('a small quick flick selects within 200 ms without a hold', () {
    final trial = _MotionTrial();
    trial.hold(600);
    trial.tiltTo(18, milliseconds: 80);
    trial.tiltTo(0, milliseconds: 80);
    trial.hold(40);
    expect(trial.actions, [HandsFreeAction.next]);

    trial.tiltTo(-18, milliseconds: 80);
    trial.tiltTo(0, milliseconds: 80);
    trial.hold(40);
    expect(trial.actions, [HandsFreeAction.next, HandsFreeAction.previous]);
  });

  test('small grip variation does not select a ski', () {
    final trial = _MotionTrial();
    trial.hold(600);
    for (var i = 0; i < 4; i++) {
      trial.tiltTo(8, milliseconds: 80);
      trial.tiltTo(-8, milliseconds: 80);
      trial.tiltTo(0, milliseconds: 80);
    }
    expect(trial.actions, isEmpty);
  });

  test(
    'a continuous out-and-back tilt selects within 320 ms without stopping',
    () {
      final trial = _MotionTrial();
      trial.hold(600);
      trial.tiltTo(30, milliseconds: 140);
      trial.tiltTo(0, milliseconds: 140);
      trial.hold(40);
      expect(trial.actions, [HandsFreeAction.next]);

      trial.tiltTo(-30, milliseconds: 140);
      trial.tiltTo(0, milliseconds: 140);
      trial.hold(40);
      expect(trial.actions, [HandsFreeAction.next, HandsFreeAction.previous]);
    },
  );

  test('opening selection preserves the grip calibrated before shaking', () {
    final trial = _MotionTrial(stage: HandsFreeStage.overview);
    trial.hold(600);
    trial.shake();
    trial.detector.setStage(HandsFreeStage.skiSelection);
    trial.hold(1800, degrees: 30);
    expect(trial.detector.progress, IosTiltProgress.returnToNeutral);
    trial.hold(400);
    expect(trial.actions, [HandsFreeAction.confirm, HandsFreeAction.next]);
  });

  test('slowly changing grip cannot be mistaken for a stable calibration', () {
    final trial = _MotionTrial();
    for (var degrees = 0.0; degrees <= 30; degrees += 0.5) {
      trial.hold(20, degrees: degrees, rotationRate: 0.44);
    }
    expect(trial.detector.progress, IosTiltProgress.calibrating);
    trial.hold(600, degrees: 30);
    expect(trial.detector.progress, IosTiltProgress.ready);
    expect(trial.actions, isEmpty);
  });

  test('a normal wrist rotation on return must not cancel a held tilt', () {
    final trial = _MotionTrial();
    trial.hold(600);
    trial.hold(400, degrees: 30);
    trial.hold(160, degrees: 10, rotationRate: 3, acceleration: 0.2);
    trial.hold(400);
    expect(trial.actions, [HandsFreeAction.next]);
  });

  test('tilt selects once, only after a steady return to the natural grip', () {
    final trial = _MotionTrial(neutralDegrees: 10);
    trial.hold(600, degrees: 10);
    trial.hold(1000, degrees: 45);
    expect(trial.actions, isEmpty);

    trial.hold(400, degrees: 10);
    expect(trial.actions, [HandsFreeAction.next]);
    trial.hold(1000, degrees: 10);
    expect(trial.actions, hasLength(1));

    trial.hold(500, degrees: -20);
    trial.hold(400, degrees: 10);
    expect(trial.actions, [HandsFreeAction.next, HandsFreeAction.previous]);
  });

  test('a shake cancels a held tilt and confirms without changing skis', () {
    final trial = _MotionTrial();
    trial.hold(600);
    trial.hold(500, degrees: 35);
    trial.hold(20);
    trial.shake(degrees: 40);
    trial.hold(1200);

    expect(trial.actions, [HandsFreeAction.confirm]);
  });

  test('one bump and a brief angular spike do not select or confirm', () {
    final trial = _MotionTrial();
    trial.hold(600);
    trial.hold(40, degrees: 40);
    trial.hold(400);
    trial.hold(20, acceleration: 1.0);
    trial.hold(1200);

    expect(trial.actions, isEmpty);
  });

  test('the shake opening ski selection cannot also confirm a ski', () {
    final trial = _MotionTrial(stage: HandsFreeStage.overview);
    trial.hold(600);
    trial.shake();
    expect(trial.actions, [HandsFreeAction.confirm]);

    trial.detector.reset(
      stage: HandsFreeStage.skiSelection,
      preserveShakeCooldown: true,
    );
    trial.shake();
    trial.hold(200);
    trial.shake();
    expect(trial.actions, hasLength(1));

    trial.hold(1400);
    trial.shake();
    expect(trial.actions, [HandsFreeAction.confirm, HandsFreeAction.confirm]);
  });

  test('overview ignores tilt and reset discards a pending selection', () {
    final trial = _MotionTrial(stage: HandsFreeStage.overview);
    trial.hold(600);
    trial.hold(600, degrees: 35);
    trial.hold(400);
    expect(trial.actions, isEmpty);

    trial.detector.reset(stage: HandsFreeStage.skiSelection);
    trial.hold(600);
    trial.hold(600, degrees: 35);
    trial.detector.reset(stage: HandsFreeStage.skiSelection);
    trial.hold(1000);
    expect(trial.actions, isEmpty);
  });

  test('one continuous shake stays one action even across a stage change', () {
    final trial = _MotionTrial(stage: HandsFreeStage.overview);
    trial.shake();
    trial.detector.reset(
      stage: HandsFreeStage.skiSelection,
      preserveShakeCooldown: true,
    );
    for (var i = 0; i < 15; i++) {
      trial.shake();
    }
    expect(trial.actions, [HandsFreeAction.confirm]);
    trial.hold(1400);
    trial.shake();
    expect(trial.actions, [HandsFreeAction.confirm, HandsFreeAction.confirm]);
  });

  test('a sampling interruption discards a pending tilt', () {
    final trial = _MotionTrial();
    trial.hold(600);
    trial.hold(600, degrees: 35);
    trial.time += const Duration(seconds: 1);
    trial.hold(1000);
    expect(trial.actions, isEmpty);
  });
}

class _MotionTrial {
  _MotionTrial({
    HandsFreeStage stage = HandsFreeStage.skiSelection,
    this.neutralDegrees = 0,
  }) {
    detector.reset(stage: stage);
  }

  final double neutralDegrees;
  final detector = IosMotionGestureDetector();
  final actions = <HandsFreeAction>[];
  Duration time = Duration.zero;
  double _degrees = 0;

  void tiltTo(double degrees, {required int milliseconds}) {
    final start = _degrees;
    final steps = milliseconds ~/ 20;
    final rotationRate =
        (degrees - start).abs() * math.pi / 180 / (milliseconds / 1000);
    for (var step = 1; step <= steps; step++) {
      hold(
        20,
        degrees: start + (degrees - start) * step / steps,
        rotationRate: rotationRate,
        acceleration: 0.15,
      );
    }
  }

  void hold(
    int milliseconds, {
    double? degrees,
    double acceleration = 0,
    double rotationRate = 0,
  }) {
    _degrees = degrees ?? neutralDegrees;
    for (var tick = 0; tick < milliseconds; tick += 20) {
      time += const Duration(milliseconds: 20);
      final action = detector.add(
        IosMotionSample(
          time: time,
          gravityX: math.sin((degrees ?? neutralDegrees) * math.pi / 180),
          accelerationX: acceleration,
          accelerationY: 0,
          accelerationZ: 0,
          rotationRate: rotationRate,
        ),
      );
      if (action != null) actions.add(action);
    }
  }

  void shake({double degrees = 0}) {
    hold(80, degrees: degrees, acceleration: 1);
    hold(80, degrees: -degrees, acceleration: -1);
    hold(80, degrees: degrees, acceleration: 1);
  }
}
