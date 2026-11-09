import 'dart:math' as math;

import '../hands_free_input.dart';

enum IosTiltProgress {
  calibrating,
  ready,
  tiltFurtherLeft,
  tiltFurtherRight,
  holdLeft,
  holdRight,
  returnToNeutral,
  settling,
  motionBlocked,
}

/// Core Motion device axes: x points right across the portrait display.
/// Acceleration and gravity are in g; time is monotonic time since boot.
class IosMotionSample {
  const IosMotionSample({
    required this.time,
    required this.gravityX,
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
    required this.rotationRate,
  });

  final Duration time;
  final double gravityX;
  final double accelerationX;
  final double accelerationY;
  final double accelerationZ;

  /// Magnitude of angular velocity, in radians per second.
  final double rotationRate;

  double get acceleration => math.sqrt(
    accelerationX * accelerationX +
        accelerationY * accelerationY +
        accelerationZ * accelerationZ,
  );

  List<double> get accelerationVector => [
    accelerationX,
    accelerationY,
    accelerationZ,
  ];
}

/// A tilt commits after a debounced excursion AND a return to neutral.
/// Motion cancels the pending tilt before any shake can confirm the selection.
class IosMotionGestureDetector {
  static const calibrationTime = Duration(milliseconds: 250);
  static const tiltHoldTime = Duration(milliseconds: 40);
  static const neutralHoldTime = Duration(milliseconds: 40);
  static const movementHoldoff = Duration(milliseconds: 200);
  static const shakeRestTime = Duration(milliseconds: 500);
  static const shakeWindow = Duration(milliseconds: 700);
  static const shakeCooldown = Duration(milliseconds: 1200);
  static const tiltAngle = 12 * math.pi / 180;
  static const neutralAngle = 6 * math.pi / 180;
  static const calibrationTolerance = 3 * math.pi / 180;

  HandsFreeStage _stage = HandsFreeStage.overview;
  double? _neutralAngle;
  double? _calibrationAngle;
  IosTiltProgress _progress = IosTiltProgress.calibrating;
  Duration? _quietSince;
  Duration? _lastMovement;
  Duration? _lastSample;
  Duration? _tiltSince;
  Duration? _returnSince;
  int _tiltDirection = 0;
  bool _tiltHeld = false;
  Duration? _shakeSince;
  Duration? _lastImpulse;
  Duration? _lastShake;
  Duration? _shakeRestSince;
  bool _shakeNeedsRest = false;
  List<double>? _previousImpulse;
  int _impulses = 0;

  IosTiltProgress get progress => _progress;

  void setStage(HandsFreeStage stage) {
    reset(stage: stage, preserveShakeCooldown: true, preserveCalibration: true);
  }

  void reset({
    required HandsFreeStage stage,
    bool preserveShakeCooldown = false,
    bool preserveCalibration = false,
  }) {
    _stage = stage;
    if (!preserveCalibration) _neutralAngle = null;
    _calibrationAngle = null;
    _progress = _neutralAngle == null
        ? IosTiltProgress.calibrating
        : IosTiltProgress.ready;
    _quietSince = null;
    _lastMovement = null;
    _shakeRestSince = null;
    if (!preserveShakeCooldown) {
      _lastSample = null;
      _lastShake = null;
      _shakeNeedsRest = false;
    }
    _clearTilt();
    _clearShake();
  }

  HandsFreeAction? add(IosMotionSample sample) {
    if (!_isValid(sample)) return null;
    final previousTime = _lastSample;
    if (previousTime != null && sample.time <= previousTime) return null;
    if (previousTime != null &&
        sample.time - previousTime > const Duration(milliseconds: 200)) {
      final gap = sample.time - previousTime;
      // Preserve the grip during a short route transition, but never finish a
      // partial gesture across it. A longer absence requires a new grip.
      reset(
        stage: _stage,
        preserveShakeCooldown: true,
        preserveCalibration: gap < const Duration(seconds: 2),
      );
      // Recording stops this source entirely. Requiring observed stillness
      // from that missing stream would swallow the first shake on returning.
      if (gap >= shakeCooldown) _shakeNeedsRest = false;
    }
    _lastSample = sample.time;

    // Wrist rotation is part of a tilt, including a brisk return. Cancel only
    // for strong translation; ordinary rotation merely delays the stable hold.
    if (sample.acceleration > 0.5) {
      _lastMovement = sample.time;
      _quietSince = null;
      _clearTilt();
    }

    if (_detectShake(sample)) {
      _clearTilt();
      _progress = IosTiltProgress.motionBlocked;
      return HandsFreeAction.confirm;
    }

    if (_lastMovement != null &&
        sample.time - _lastMovement! < movementHoldoff) {
      _progress = IosTiltProgress.motionBlocked;
      return null;
    }
    final isCalibrating = _neutralAngle == null;
    // Calibrating needs a steady grip. Once calibrated, follow normal wrist
    // motion instead of requiring a pause at both ends of every tilt.
    final excessiveMotion = isCalibrating
        ? sample.acceleration > 0.2 || sample.rotationRate > 0.8
        : sample.acceleration > 0.35 || sample.rotationRate > 6;
    if (excessiveMotion) {
      _quietSince = null;
      _tiltSince = null;
      _returnSince = null;
      _progress = _neutralAngle == null
          ? IosTiltProgress.calibrating
          : IosTiltProgress.settling;
      return null;
    }

    final angle = math.asin(sample.gravityX.clamp(-1.0, 1.0));
    if (_neutralAngle == null) {
      _progress = IosTiltProgress.calibrating;
      // A phone held on its side leaves too little range for left/right tilt.
      if (sample.gravityX.abs() > 0.8) {
        _quietSince = null;
        return null;
      }
      if (_quietSince == null ||
          (angle - _calibrationAngle!).abs() > calibrationTolerance) {
        _quietSince = sample.time;
        _calibrationAngle = angle;
      }
      if (sample.time - _quietSince! >= calibrationTime) {
        _neutralAngle = angle;
        _progress = IosTiltProgress.ready;
      }
      return null;
    }
    if (_stage != HandsFreeStage.skiSelection) {
      _progress = IosTiltProgress.ready;
      return null;
    }
    return _detectTilt(sample.time, angle - _neutralAngle!);
  }

  bool _isValid(IosMotionSample sample) => [
    sample.gravityX,
    ...sample.accelerationVector,
    sample.rotationRate,
  ].every((value) => value.isFinite);

  bool _detectShake(IosMotionSample sample) {
    if (_shakeNeedsRest) {
      if (sample.acceleration > 0.12 || sample.rotationRate > 0.6) {
        _shakeRestSince = null;
        return false;
      }
      _shakeRestSince ??= sample.time;
      if (sample.time - _shakeRestSince! < shakeRestTime) return false;
      _shakeNeedsRest = false;
    }
    if (_lastShake != null && sample.time - _lastShake! < shakeCooldown) {
      return false;
    }
    if (_shakeSince != null && sample.time - _shakeSince! > shakeWindow) {
      _clearShake();
    }
    if (sample.acceleration < 0.75) return false;
    if (_lastImpulse != null &&
        sample.time - _lastImpulse! < const Duration(milliseconds: 60)) {
      return false;
    }
    final vector = sample.accelerationVector;
    final previous = _previousImpulse;
    if (previous != null) {
      final dot =
          vector[0] * previous[0] +
          vector[1] * previous[1] +
          vector[2] * previous[2];
      if (dot >= 0) return false;
    }
    _shakeSince ??= sample.time;
    _lastImpulse = sample.time;
    _previousImpulse = vector;
    _impulses++;
    if (_impulses < 3) return false;
    _lastShake = sample.time;
    _shakeNeedsRest = true;
    _clearShake();
    return true;
  }

  HandsFreeAction? _detectTilt(Duration time, double angle) {
    if (angle.abs() <= neutralAngle) {
      if (!_tiltHeld) {
        _clearTilt();
        _progress = IosTiltProgress.ready;
        return null;
      }
      _returnSince ??= time;
      _progress = IosTiltProgress.settling;
      if (time - _returnSince! < neutralHoldTime) return null;
      final action = _tiltDirection > 0
          ? HandsFreeAction.next
          : HandsFreeAction.previous;
      _clearTilt();
      _progress = IosTiltProgress.ready;
      return action;
    }

    _returnSince = null;
    if (angle.abs() < tiltAngle) {
      _tiltSince = null;
      _progress = _tiltHeld
          ? IosTiltProgress.returnToNeutral
          : (angle > 0
                ? IosTiltProgress.tiltFurtherRight
                : IosTiltProgress.tiltFurtherLeft);
      return null;
    }
    final direction = angle > 0 ? 1 : -1;
    if (direction != _tiltDirection) {
      _clearTilt();
      _tiltDirection = direction;
    }
    _tiltSince ??= time;
    if (time - _tiltSince! >= tiltHoldTime) _tiltHeld = true;
    _progress = _tiltHeld
        ? IosTiltProgress.returnToNeutral
        : (direction > 0
              ? IosTiltProgress.holdRight
              : IosTiltProgress.holdLeft);
    return null;
  }

  void _clearTilt() {
    _tiltDirection = 0;
    _tiltHeld = false;
    _tiltSince = null;
    _returnSince = null;
  }

  void _clearShake() {
    _shakeSince = null;
    _lastImpulse = null;
    _previousImpulse = null;
    _impulses = 0;
  }
}
