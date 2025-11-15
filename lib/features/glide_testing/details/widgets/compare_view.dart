import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/details/widgets/compare_graph.dart';

import '../../compare/compare_runs_view_model.dart';
import 'compare_list.dart';

class CompareView extends StatelessWidget {
  const CompareView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final selectedRuns = viewModel.currentSelectedTestRuns;
    return Column(
      children: [
        Flexible(flex: 2, child: CompareGraph(runs: selectedRuns)),
        Flexible(flex: 2, child: CompareList(runs: selectedRuns)),
        SizedBox(height: 64),
      ],
    );
  }
}
