class SpeedKalmanFilter {
  // The current estimated speed (what we believe is the truth)
  double _currentSpeedEstimate = 0.0;

  // "Bias" represents the invisible force (e.g., gravity on a slope)
  // that the accelerometer cannot feel (since it's in freefall/sliding).
  // This allows the filter to "learn" the slope of the hill.
  double _accelerationBias = 0.0;

  // How unsure we are about our current estimate.
  // Starts high because we haven't seen any data yet.
  double _estimationUncertainty = 1.0;

  // --- TUNING PARAMETERS ---

  // How much uncertainty we add for every second of prediction (using accelerometer).
  // A lower number means we trust the physics/accelerometer more.
  // A higher number means we think the speed changes randomly or the accel is noisy.
  final double _predictionUncertaintyPerSecond = 0.5;

  // How much "noise" we expect from the GPS.
  // A lower number (e.g., 0.3) means we trust the GPS highly for absolute speed.
  // A higher number would mean we rely more on the accelerometer curve.
  final double _gpsMeasurementUncertainty = 0.3;

  // Controls how fast the filter adapts to changes in the slope/bias.
  // Used as a multiplier for the learning rate of the bias.
  // 0.1 is conservative/stable.
  final double _biasLearningRate = 0.1;

  SpeedKalmanFilter({double initialSpeed = 0.0}) {
    _currentSpeedEstimate = initialSpeed;
  }

  /// STEP 1: PREDICT (Physics Step)
  /// Uses the accelerometer to guess the new speed based on the old speed,
  /// while accounting for the learned bias (slope).
  ///
  /// [accelerationY]: The forward acceleration in m/s² (filtered magnitude).
  /// [secondsSinceLastUpdate]: Time elapsed since the last prediction.
  void predict({
    required double accelerationY,
    required double secondsSinceLastUpdate,
  }) {
    // 1. Apply Physics Formula: velocity = velocity + (acceleration + bias) * time
    // We add _accelerationBias to compensate for gravity/slope that the sensor misses.
    _currentSpeedEstimate +=
        (accelerationY + _accelerationBias) * secondsSinceLastUpdate;

    // 2. Increase our uncertainty (Entropy increases over time).
    // The longer time passes without a GPS fix, the less sure we are.
    _estimationUncertainty +=
        _predictionUncertaintyPerSecond * secondsSinceLastUpdate;

    // Physical constraint: We assume you don't ski backwards during a glide test.
    if (_currentSpeedEstimate < 0) _currentSpeedEstimate = 0;
  }

  /// STEP 2: UPDATE (Correction Step)
  /// Uses the actual GPS reading to correct both our speed estimate AND our understanding of the slope (bias).
  ///
  /// [measuredGpsSpeed]: The speed reported by the GPS in m/s.
  void update(double measuredGpsSpeed) {
    // 3. Calculate the difference between Map (GPS) and Reality (Our Guess).
    double error = measuredGpsSpeed - _currentSpeedEstimate;

    // 4. Calculate "Kalman Gain" (Trust Factor).
    // This calculates a value between 0.0 and 1.0.
    // Near 1.0 = Trust GPS entirely.
    // Near 0.0 = Trust our calculated prediction entirely.
    double trustFactor =
        _estimationUncertainty /
        (_estimationUncertainty + _gpsMeasurementUncertainty);

    // 5. Correct the speed.
    // We take the difference between GPS and our guess, scale it by the Trust Factor,
    // and apply it to our estimate.
    _currentSpeedEstimate = _currentSpeedEstimate + (trustFactor * error);

    // 6. Correct the Bias (Learn the Slope).
    // If we consistently guess too low (error > 0), it means we have a tailwind or slope.
    // We nudge the bias so we guess correctly next time.
    _accelerationBias += error * _biasLearningRate * trustFactor;

    // 7. Decrease uncertainty.
    // Since we just got a real measurement, we are now more confident in our value.
    _estimationUncertainty = (1.0 - trustFactor) * _estimationUncertainty;
  }

  double get speed => _currentSpeedEstimate;

  double get slopeBias => _accelerationBias;
}
