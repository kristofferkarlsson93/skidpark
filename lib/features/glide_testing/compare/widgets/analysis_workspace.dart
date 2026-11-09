import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../compare_runs_view_model.dart';
import '../models/analysis_page.dart';
import 'compare_list.dart';
import 'test_info.dart';
import 'overview_container.dart';
import 'release_point_analysis/release_point_container.dart';

class AnalysisWorkspace extends StatelessWidget {
  final VoidCallback onOpenControls;

  const AnalysisWorkspace({super.key, required this.onOpenControls});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.testRuns.isEmpty) {
      return ListView(
        key: const PageStorageKey('empty-test-info'),
        padding: const EdgeInsets.fromLTRB(21, kToolbarHeight + 16, 21, 28),
        children: const [
          TestInfo(),
          SizedBox(height: 24),
          TestGuide(initiallyExpanded: true),
        ],
      );
    }

    final page = viewModel.activeAnalysisPage;
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: IndexedStack(
            index: page.index,
            sizing: StackFit.expand,
            children: [
              const OverviewGraph(),
              const ReleasePointGraph(),
              ListView(
                key: const PageStorageKey('test-info'),
                padding: const EdgeInsets.fromLTRB(
                  21,
                  kToolbarHeight + 16,
                  21,
                  18,
                ),
                children: const [TestInfo()],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: IndexedStack(
            index: page.index,
            sizing: StackFit.expand,
            children: [
              for (final page in AnalysisPage.values)
                _AnalysisPanel(page: page, onOpenControls: onOpenControls),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  final AnalysisPage page;
  final VoidCallback onOpenControls;

  const _AnalysisPanel({required this.page, required this.onOpenControls});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    return NestedScrollView(
      key: PageStorageKey('analysis-panel-${page.name}'),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: DefaultTabController(
            key: ValueKey(viewModel.activeAnalysisPage),
            length: AnalysisPage.values.length,
            initialIndex: page.index,
            child: TabBar(
              onTap: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                viewModel.setCurrentAnalysisPage(AnalysisPage.values[index]);
              },
              tabs: const [
                Tab(text: 'Översikt'),
                Tab(text: 'Släppunkt'),
                Tab(text: 'Testet'),
              ],
            ),
          ),
        ),
        if (page != AnalysisPage.testInfo)
          SliverToBoxAdapter(
            child: _AnalysisSelectionSummary(onOpenControls: onOpenControls),
          ),
      ],
      body: switch (page) {
        AnalysisPage.overview => CompareList(
          key: const PageStorageKey('overview-runs'),
          runs: viewModel.currentDisplayRuns,
          isAverageView: viewModel.useAverageView,
          highlightedRunId: viewModel.highlightedRunId,
          onRunTapped: viewModel.toggleHighlightedRun,
        ),
        AnalysisPage.releasePoint => const ReleasePointPanel(),
        AnalysisPage.testInfo => ListView(
          key: const PageStorageKey('test-guide'),
          padding: const EdgeInsets.fromLTRB(17, 14, 17, 20),
          children: const [TestGuide()],
        ),
      },
    );
  }
}

class _AnalysisSelectionSummary extends StatelessWidget {
  final VoidCallback onOpenControls;

  const _AnalysisSelectionSummary({required this.onOpenControls});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CompareRunsViewModel>();
    final theme = Theme.of(context);
    final selection =
        '${viewModel.currentSelectedTestRuns.length} av ${viewModel.testRuns.length} åk';
    final display = viewModel.useAverageView
        ? 'Medel per skida'
        : 'Enskilda åk';
    return TextButton(
      onPressed: onOpenControls,
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        textStyle: theme.textTheme.labelSmall,
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text('$selection · $display')),
        ],
      ),
    );
  }
}
