import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/distinct_colors.dart';

Color getSafeAverageColor(int number) {
  return averageColors[math.max(0, number - 1) % averageColors.length];
}
