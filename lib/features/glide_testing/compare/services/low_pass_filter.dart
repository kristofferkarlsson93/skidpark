// Control how big/small changes we should react to.
// Small alpha value means we only react to larger increases.
class LowPassFilter {
  double _output = 0.0;
  final double alpha;
  bool _isInitialized = false;

  LowPassFilter({this.alpha = 0.1});

  double filter(double input) {
    if (!_isInitialized) {
      _output = input;
      _isInitialized = true;
      return input;
    }
    _output = _output + alpha * (input - _output);
    return _output;
  }

  void reset() {
    _output = 0.0;
    _isInitialized = false;
  }
}
