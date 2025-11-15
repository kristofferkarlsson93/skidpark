import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';

typedef _GpsDisplayConfig = ({IconData icon, Color color, String text});

class GpsAccuracyBanner extends StatelessWidget {
  final GpsAccuracy accuracyGrade;

  const GpsAccuracyBanner({super.key, required this.accuracyGrade});

  _GpsDisplayConfig _getConfig(
    BuildContext context,
    GpsAccuracy accuracyGrade,
  ) {
    final theme = Theme.of(context);
    switch (accuracyGrade) {
      case GpsAccuracy.unknown:
        return (
          icon: Icons.signal_cellular_nodata_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          text: 'Söker GPS...  Prova stå stilla en stund',
        );
      case GpsAccuracy.bad:
        return (
          icon: Icons.signal_cellular_off_outlined,
          color: theme.colorScheme.error,
          text: 'Dålig GPS-signal. Prova stå stilla en stund',
        );
      case GpsAccuracy.decent:
        return (
          icon: Icons.signal_cellular_alt_1_bar_outlined,
          color: Colors.orangeAccent, // A good 'warning' color
          text: 'Svag GPS-signal. Prova stå stilla en stund',
        );
      case GpsAccuracy.good:
        return (
          icon: Icons.signal_cellular_alt_2_bar_outlined,
          color: theme.colorScheme.secondary,
          text: 'Bra GPS-signal',
        );
      case GpsAccuracy.excellent:
        return (
          icon: Icons.signal_cellular_4_bar_outlined,
          color: theme.colorScheme.secondary,
          text: 'Mycket bra GPS-signal',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(context, accuracyGrade);

    return Card(
      color: config.color.withValues(alpha: 0.15),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      // Ensures the child respects the border
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon with the dynamic color
            Icon(config.icon, color: config.color, size: 20),
            const SizedBox(width: 12),
            // Text message
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  // Fade and slide text in from below
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  config.text,
                  // Key tells AnimatedSwitcher that the content has changed
                  key: ValueKey('text_${config.text}'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: config.color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
