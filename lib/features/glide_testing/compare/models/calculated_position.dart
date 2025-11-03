class CalculatedPosition {
  final double speed; // ms
  final DateTime timestamp;
  final double distanceTraveled;

  CalculatedPosition(this.speed, this.timestamp, this.distanceTraveled);

  @override
  String toString() {
    return 'CalculatedPosition(speed: $speed, timestamp: $timestamp, distanceTraveled: $distanceTraveled)';
  }
}
