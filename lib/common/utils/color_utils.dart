import 'package:flutter/material.dart';

import '../../theme/distinct_colors.dart';

Color getSafeColor(int number) {
  return distinctColors[number % distinctColors.length];
}
