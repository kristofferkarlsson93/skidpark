import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';

typedef _GpsDisplayConfig = ({IconData icon, Color color, String text});

class GpsAccuracyBanner extends StatelessWidget {
  final GpsAccuracy accuracyGrade;

  const GpsAccuracyBanner({super.key, required this.accuracyGrade});

  _GpsDisplayConfig _getConfig(BuildContext context, GpsAccuracy accuracyGrade) {
    final theme = Theme.of(context);
    switch (accuracyGrade) {
      case GpsAccuracy.unknown:
        return (
        icon: Icons.signal_cellular_nodata,
        color: theme.colorScheme.onSurfaceVariant,
        text: 'Söker GPS...',
        );
      case GpsAccuracy.bad:
        return (
        icon: Icons.signal_cellular_off,
        color: theme.colorScheme.error,
        text: 'Dålig signal. Prova stå still en stund',
        );
      case GpsAccuracy.decent:
        return (
        icon: Icons.signal_cellular_alt_1_bar,
        color: Colors.orangeAccent,
        text: 'Svag signal. Prova stå still en stund',
        );
      case GpsAccuracy.good:
        return (
        icon: Icons.signal_cellular_alt_2_bar,
        color: Colors.greenAccent, // Tydligare grön mot mörk bakgrund
        text: 'Bra GPS-signal',
        );
      case GpsAccuracy.excellent:
        return (
        icon: Icons.signal_cellular_4_bar,
        color: Colors.greenAccent,
        text: 'Utmärkt signal',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(context, accuracyGrade);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              config.text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: config.color,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}