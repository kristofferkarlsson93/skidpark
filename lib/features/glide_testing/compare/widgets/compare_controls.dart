import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/average_per_ski_switch.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/sensor_fusion_switch.dart';

import '../../compare/compare_runs_view_model.dart';
import '../../../../legacy/select_run_card.dart';

class CompareControls extends StatelessWidget {
  const CompareControls({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CompareRunsViewModel>();
    final allRunsInTest = viewModel.testRuns;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(viewModel.testTitle, style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Inställningar', style: theme.textTheme.labelLarge),
          ),
          SensorFusionToggle(
            isActive: viewModel.useSensorFusion,
            onChanged: (newValue) {
              viewModel.setUseSensorFusion(newValue);
            },
          ),
          AveragePerSkiSwitch(
            isActive: viewModel.useAverageView,
            onChanged: (newValue) {
              viewModel.toggleAverageView(newValue);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Välj åk att visa i vyn',
              style: theme.textTheme.labelLarge,
            ),
          ),

          ...allRunsInTest.asMap().entries.map((entry) {
            final index = entry.key;
            final run = entry.value;
            final isSelected = viewModel.isRunSelected(run.id);
            return SelectRunCard(
              isSelected: isSelected,
              testRun: run,
              runNumber: index + 1,
              onTap: () {
                viewModel.toggleSelectedTestRun(run);
              },
            );
          }),
        ],
      ),
    );
  }
}
