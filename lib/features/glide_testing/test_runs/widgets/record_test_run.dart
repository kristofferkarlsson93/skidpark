import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';

import '../../../../common/database/database.dart';
import '../../../../common/shared_widgets/flat_stats_card.dart';

class RecordTestRun extends StatefulWidget {
  final StoredSkiData testSki;

  final void Function(List<Position>, int elapsedSeconds) onStopAndSave;

  final VoidCallback onAbort;

  const RecordTestRun({
    super.key,
    required this.testSki,
    required this.onStopAndSave,
    required this.onAbort,
  });

  @override
  State<RecordTestRun> createState() => _RecordTestRunState();
}

class _RecordTestRunState extends State<RecordTestRun> {
  DataRecorder? service;

  @override
  void initState() {
    super.initState();
    service = context.read<DataRecorder>();
    service!.startRecordingGpsData();
  }

  void _storeAndStopRecording() {
    final positions = List<Position>.from(service!.recordedPositions);
    final elapsedSeconds = service!.elapsedSeconds;
    service!.stopStreaming();
    service!.clearPositions();

    widget.onStopAndSave(positions, elapsedSeconds);
  }

  void _discardTestRun() {
    service!.stopStreaming();
    service!.clearPositions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Consumer<DataRecorder>(
            builder: (context, recorder, child) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FlatStatsCard(
                          context: context,
                          label: 'Nuvarande hastighet',
                          value: recorder.currentSpeedKmh.toStringAsFixed(2),
                          unit: 'km/h',
                          borderColor: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FlatStatsCard(
                          context: context,
                          label: 'Duration',
                          value: recorder.elapsedSeconds.toString(),
                          unit: 'seconds',
                          borderColor: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${recorder.dataPoints} data points collected',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              );
            },
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
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
