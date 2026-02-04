import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/stop_and_save_button.dart';

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
            final countdown = viewModel.autoSaveCountdownSeconds;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GpsAccuracyBanner(
                    accuracyGrade: viewModel.dataRecorder.accuracyGrade,
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.error.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Samlar in data...',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/ski_icon.svg',
                          colorFilter: ColorFilter.mode(
                            theme.colorScheme.onPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Vald skida",
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            viewModel.selectedSki!.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FlatStatsCard(
                        label: 'Hastighet',
                        value: viewModel.dataRecorder.currentSpeedKmh
                            .toStringAsFixed(1),
                        unit: 'km/h',
                        icon: Icons.speed,
                        accentColor: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FlatStatsCard(
                        label: 'Tid',
                        value: viewModel.dataRecorder.elapsedSeconds.toString(),
                        unit: 's',
                        icon: Icons.timer_outlined,
                        accentColor: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    '${viewModel.dataRecorder.dataPoints} mätpunkter sparade',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Divider(),
                Center(child: _buildVolumeKeyGuide(theme)),
                const SizedBox(height: 16),

                if (countdown > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Stopp upptäckt. Avslutar automatiskt...",
                              style: textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                StopAndSaveButton(
                  countdownSeconds: countdown,
                  onStopAndSave: onStopAndSave,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: onAbort,
                    child: Text(
                      'Avbryt och kasta',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVolumeKeyGuide(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Icon(
            Icons.save_alt,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "VOLYM NER",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            Text(
              "Spara åket",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
