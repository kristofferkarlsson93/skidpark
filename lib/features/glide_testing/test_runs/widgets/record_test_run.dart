import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';

import '../../../../common/database/database.dart';
import '../../../../common/shared_widgets/flat_stats_card.dart';

class RecordTestRun extends StatefulWidget {
  final StoredSkiData testSki;

  final void Function(List<Position>, int elapsedSeconds) onStopAndSave;

  final VoidCallback onAbort;
  final DataRecorder dataRecorder;

  const RecordTestRun({
    super.key,
    required this.testSki,
    required this.onStopAndSave,
    required this.onAbort,
    required this.dataRecorder,
  });

  @override
  State<RecordTestRun> createState() => _RecordTestRunState();
}

class _RecordTestRunState extends State<RecordTestRun> {
  @override
  void initState() {
    super.initState();
    widget.dataRecorder.startRecording();
  }

  void _storeAndStopRecording() {
    widget.dataRecorder.stopRecording();
    final positions = List<Position>.from(
      widget.dataRecorder.recordedPositions,
    );
    final elapsedSeconds = widget.dataRecorder.elapsedSeconds;

    widget.dataRecorder.resetForNewRun();

    widget.onStopAndSave(positions, elapsedSeconds);
  }

  void _discardTestRun() {
    widget.dataRecorder.stopRecording();
    widget.dataRecorder.resetForNewRun();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListenableBuilder(
          listenable: widget.dataRecorder,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GpsAccuracyBanner(
                  accuracyGrade: widget.dataRecorder.accuracyGrade,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Samlar in data...',
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.colorScheme.primary),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(widget.testSki.name),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FlatStatsCard(
                            label: 'Nuvarande hastighet',
                            value: widget.dataRecorder.currentSpeedKmh
                                .toStringAsFixed(2),
                            unit: 'km/h',
                            borderColor: theme.colorScheme.primary,
                            size: FlatStatsCardSize.large,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FlatStatsCard(
                            label: 'Duration',
                            value: widget.dataRecorder.elapsedSeconds
                                .toString(),
                            unit: 'seconds',
                            borderColor: theme.colorScheme.secondary,
                            size: FlatStatsCardSize.large,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '${widget.dataRecorder.dataPoints} data points collected',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                BigButton(
                  backgroundColor: theme.colorScheme.error,
                  title: 'SPARA',
                  onPress: _storeAndStopRecording,
                ),
                const SizedBox(height: 42),
                Center(
                  child: TextButton(
                    onPressed: () {
                      _discardTestRun();
                      widget.onAbort();
                    },
                    child: Text(
                      'Avbryt',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}
