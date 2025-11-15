import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';

import '../../compare/compare_runs_view_model.dart';
import '../../compare/widgets/select_run_card.dart';

class CompareControls extends StatelessWidget {
  final StoredGlideTestData glideTest;

  const CompareControls({super.key, required this.glideTest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CompareRunsViewModel>();
    final allRunsInTest = viewModel.testRuns;
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.1,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Card(
          elevation: 0,
          // elevation: 12,
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              // color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              color: theme.colorScheme.outline,
              width: 1.0,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
                child: Text(
                  glideTest.title,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 0, 8),
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
      },
    );
  }
}
