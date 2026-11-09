import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ski_selection/test_ski_selection_screen.dart';
import '../compare_runs_view_model.dart';

class TestSkisSection extends StatelessWidget {
  const TestSkisSection({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CompareRunsViewModel>();
    final theme = Theme.of(context);
    final test = model.glideTest;
    final names = model.selectedSkis.map(
      (ski) => ski.archivedAt == null ? ski.name : '${ski.name} (arkiverad)',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Skidor i testet',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            if (test != null && !test.isExample)
              TextButton(
                onPressed: model.isEditingDetails
                    ? null
                    : () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) =>
                              TestSkiSelectionScreen(glideTestId: test.id),
                        ),
                      ),
                child: const Text('Ändra skidor'),
              ),
          ],
        ),
        Text(
          names.isEmpty ? 'Inga skidor valda.' : names.join(', '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
