import 'package:flutter/material.dart';

/// Opaque so recording readiness cannot be confused with ski selection.
class RecordingStartCountdown extends StatelessWidget {
  const RecordingStartCountdown({
    super.key,
    required this.seconds,
    required this.skiName,
  });

  final int seconds;
  final String skiName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Semantics(
                    liveRegion: true,
                    label: 'Inspelning startar om $seconds sekunder',
                    excludeSemantics: true,
                    child: Text(
                      '$seconds',
                      style: TextStyle(
                        fontSize: 200,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                skiName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
