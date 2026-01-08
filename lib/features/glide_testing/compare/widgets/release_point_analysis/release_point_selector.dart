import 'package:flutter/material.dart';

class ReleasePointSelector extends StatelessWidget {
  final bool enabled;
  final double maxValue;
  final double value;

  final Function(double) onChanged;

  const ReleasePointSelector({
    super.key,
    required this.value,
    required this.enabled,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      divisions: 200,
      onChanged: enabled ? onChanged : null,
      label: "${value.toStringAsFixed(0)} m",
      min: 0,
      max: maxValue,
    );
  }
}
