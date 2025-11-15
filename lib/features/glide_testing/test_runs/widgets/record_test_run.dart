import 'package:flutter/material.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';

import '../../../../common/shared_widgets/flat_stats_card.dart';
import '../viewModel/run_recorder_view_model.dart';

class RecordTestRun extends StatelessWidget {
  final RunRecorderViewModel viewModel;
  final VoidCallback onStopAndSave;
  final VoidCallback onAbort;

  const RecordTestRun({
    super.key,
    required this.viewModel,
    required this.onStopAndSave,
    required this.onAbort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListenableBuilder(
          listenable: viewModel.dataRecorder,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GpsAccuracyBanner(
                  accuracyGrade: viewModel.dataRecorder.accuracyGrade,
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
                      child: Text(viewModel.selectedSki!.name),
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
                            value: viewModel.dataRecorder.currentSpeedKmh
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
                            value: viewModel.dataRecorder.elapsedSeconds
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
                        '${viewModel.dataRecorder.dataPoints} data points collected',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                BigButton(
                  backgroundColor: theme.colorScheme.error,
                  title: 'SPARA',
                  onPress: onStopAndSave,
                ),
                const SizedBox(height: 42),
                Center(
                  child: TextButton(
                    onPressed: onAbort,
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
