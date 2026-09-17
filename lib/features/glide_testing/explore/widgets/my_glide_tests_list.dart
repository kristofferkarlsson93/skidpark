import 'package:flutter/material.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../compare/screens/glide_test_compare_screen.dart';
import 'glide_test_list_card.dart';

class MyGlideTestsList extends StatelessWidget {
  const MyGlideTestsList({
    super.key,
    required this.glideTests,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  final List<GlideTestSummary> glideTests;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
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
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GlideTestCompareScreen(glideTestId: summary.test.id),
      ),
    );
  }
}
