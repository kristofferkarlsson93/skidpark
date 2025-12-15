class SpeedKalmanFilter {
  // The current estimated speed (what we believe is the truth)
  double _currentSpeedEstimate = 0.0;

  // How unsure we are about our current estimate.
  // Starts high because we haven't seen any data yet.
  double _estimationUncertainty = 1.0;

  // --- TUNING PARAMETERS ---

  // How much uncertainty we add for every second of prediction (using accelerometer).
  // A lower number means we trust the physics/accelerometer more.
  // A higher number means we think the speed changes randomly or the accel is noisy.
  final double _predictionUncertaintyPerSecond = 0.2;

  // How much "noise" we expect from the GPS.
  // A higher number means we trust the GPS less (it's jumpy).
  // A lower number means we trust the GPS completely.
  final double _gpsMeasurementUncertainty = 3.0;

  SpeedKalmanFilter({double initialSpeed = 0.0}) {
    _currentSpeedEstimate = initialSpeed;
  }

  /// STEP 1: PREDICT (Physics Step)
  /// Uses the accelerometer to guess the new speed based on the old speed.
  ///
  /// [accelerationY]: The forward acceleration in m/s².
  /// [secondsSinceLastUpdate]: Time elapsed since the last prediction (previously 'dt').
  void predict({required double accelerationY, required double secondsSinceLastUpdate}) {
    // 1. Apply Physics Formula: velocity = velocity + (acceleration * time)
    // NOTE: Depending on phone orientation, we might need to negate accelerationY (-accelerationY).
    _currentSpeedEstimate += (accelerationY * secondsSinceLastUpdate);

    // 2. Increase our uncertainty.
    // Since we are just calculating based on sensors, errors might accumulate.
    // The longer time passes without a GPS fix, the less sure we are.
    _estimationUncertainty += _predictionUncertaintyPerSecond * secondsSinceLastUpdate;

    // Physical constraint: We assume you don't ski backwards during a glide test.
    if (_currentSpeedEstimate < 0) _currentSpeedEstimate = 0;
  }

  /// STEP 2: UPDATE (Correction Step)
  /// Uses the actual GPS reading to correct our calculated guess.
  ///
  /// [measuredGpsSpeed]: The speed reported by the GPS in m/s.
  void update(double measuredGpsSpeed) {
    // 3. Calculate "Kalman Gain" (Trust Factor).
    // This calculates a value between 0.0 and 1.0.
    // Near 1.0 = Trust GPS entirely.
    // Near 0.0 = Trust our calculated prediction entirely.
    double trustFactor = _estimationUncertainty / (_estimationUncertainty + _gpsMeasurementUncertainty);

    // 4. Correct the speed.
    // We take the difference between GPS and our guess, scale it by the Trust Factor,
    // and apply it to our estimate.
    double difference = measuredGpsSpeed - _currentSpeedEstimate;
    _currentSpeedEstimate = _currentSpeedEstimate + (trustFactor * difference);

    // 5. Decrease uncertainty.
    // Since we just got a real measurement, we are now more confident in our value.
    _estimationUncertainty = (1.0 - trustFactor) * _estimationUncertainty;
  }

  // Getter for the UI to use
  double get speed => _currentSpeedEstimate;
}