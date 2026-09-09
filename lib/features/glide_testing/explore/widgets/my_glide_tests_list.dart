import 'package:flutter/material.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../compare/screens/glide_test_compare_screen.dart';
import '../../test_runs/data_recorder.dart';
import 'glide_test_list_card.dart';

class MyGlideTestsList extends StatelessWidget {
  const MyGlideTestsList({super.key, required this.glideTests});

  final List<GlideTestSummary> glideTests;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: glideTests.length,
      itemBuilder: (context, index) {
        final summary = glideTests[index];
        return GlideTestListCard(
          summary: summary,
          onTestCardClicked: () => _openTest(context, summary),
        );
      },
    );
  }

  Future<void> _openTest(BuildContext context, GlideTestSummary summary) async {
    // Permission handling intentionally remains here until Etapp 2 moves GPS
    // startup into the explicit "Nytt åk" flow.
    final hasPermissions = await DataRecorder.handleLocationPermissions(
      context,
    );
    if (!hasPermissions || !context.mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GlideTestCompareScreen(glideTestId: summary.test.id),
      ),
    );
  }
}
