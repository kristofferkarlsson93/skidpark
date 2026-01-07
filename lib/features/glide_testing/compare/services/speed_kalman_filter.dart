class SpeedKalmanFilter {
  // Aktuell uppskattad hastighet
  double _currentSpeedEstimate = 0.0;

  // NYTT: "Bias" representerar det osynliga glidet (lutningen)
  // som accelerometern inte känner av.
  double _accelerationBias = 0.0;

  // Osäkerhet i våra uppskattningar
  double _estimationUncertainty = 1.0;

  // --- TUNING PARAMETERS ---

  // Hur snabbt vi vågar lita på att "biasen" (lutningen) ändras.
  // Högre värde = anpassar sig snabbare till backens lutning, men kan "overshoota".
  final double _biasProcessNoise = 0.1;

  // Vi litar MER på GPS nu för den absoluta hastigheten.
  // Lägre siffra = Vi litar mer på GPS.
  // Tidigare var denna 1.0, nu sänker vi den drastiskt.
  final double _gpsMeasurementUncertainty = 0.3;

  // Hur mycket vi tror accel fladdrar.
  final double _predictionUncertaintyPerSecond = 0.5;

  SpeedKalmanFilter({double initialSpeed = 0.0}) {
    _currentSpeedEstimate = initialSpeed;
  }

  /// STEP 1: PREDICT
  /// Vi gissar ny fart baserat på sensor + vår inlärda bias (lutning).
  void predict({required double accelerationY, required double secondsSinceLastUpdate}) {
    // 1. Fysikformel: Fart = Fart + (SensorKraft + OsynligKraft) * tid
    // Här lägger vi till _accelerationBias för att kompensera för gravitationen.
    _currentSpeedEstimate += (accelerationY + _accelerationBias) * secondsSinceLastUpdate;

    // 2. Öka osäkerheten (entropi ökar över tid)
    _estimationUncertainty += _predictionUncertaintyPerSecond * secondsSinceLastUpdate;

    if (_currentSpeedEstimate < 0) _currentSpeedEstimate = 0;
  }

  /// STEP 2: UPDATE
  /// Korrigera både fart OCH bias baserat på verkligheten (GPS).
  void update(double measuredGpsSpeed) {
    // Skillnaden mellan karta (GPS) och verklighet (Vår gissning)
    double error = measuredGpsSpeed - _currentSpeedEstimate;

    // Kalman Gain: Vem litar vi på?
    double trustFactor = _estimationUncertainty / (_estimationUncertainty + _gpsMeasurementUncertainty);

    // 1. Korrigera hastigheten
    _currentSpeedEstimate = _currentSpeedEstimate + (trustFactor * error);

    // 2. NYTT: Korrigera Biasen (Lär oss lutningen)
    // Om vi konstant gissar för lågt (error > 0), betyder det att vi har medlut.
    // Vi ökar biasen lite grann så vi gissar rätt nästa gång.
    // Faktorn 0.5 * trustFactor är "Learning Rate".
    // Kan justeras (små steg är säkrast).
    _accelerationBias += error * 0.1 * trustFactor;

    // Minska osäkerheten nu när vi fått en mätpunkt
    _estimationUncertainty = (1.0 - trustFactor) * _estimationUncertainty;
  }

  double get speed => _currentSpeedEstimate;

  // Debug-info om du vill se hur mycket "gratis-fart" backen ger
  double get slopeBias => _accelerationBias;
}