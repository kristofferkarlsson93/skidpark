import 'package:flutter/material.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';

import '../screen/run_recording_screen.dart';
import '../../../../common/shared_widgets/simple_ski_list_item.dart';
import '../viewModel/run_recorder_view_model.dart';

class StartTestRunWidget extends StatefulWidget {
  final RunRecorderViewModel viewModel;

  const StartTestRunWidget({
    super.key,
    required this.viewModel,
  });

  @override
  State<StartTestRunWidget> createState() => _StartTestRunWidgetState();
}

class _StartTestRunWidgetState extends State<StartTestRunWidget> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 100.0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_scrollToCurrentIndex);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_scrollToCurrentIndex);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentIndex() {
    final index = widget.viewModel.markedSkiIndex;

    if (index >= 0) {
      final targetOffset = index * _itemHeight;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectableSkis = widget.viewModel.availableSkis;
    final currentMarkedIndex = widget.viewModel.markedSkiIndex;

    return SafeArea(
      child: Center(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: widget.viewModel.dataRecorder,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.all(
                    RunRecorderScreen.paddingFromEdge,
                  ),
                  child: GpsAccuracyBanner(
                    accuracyGrade: widget.viewModel.dataRecorder.accuracyGrade,
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            Text("Välj skida för åket", style: theme.textTheme.titleMedium),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(
                  RunRecorderScreen.paddingFromEdge,
                ),
                itemCount: selectableSkis.length,
                controller: _scrollController,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final currentSki = selectableSkis[index];
                  final isSelected = widget.viewModel.selectedSki != null &&
                      widget.viewModel.selectedSki!.id == currentSki.id;
                  return SimpleSkiListItem(
                    height: _itemHeight,
                    skiDetails: currentSki,
                    isSelected: isSelected,
                    isMarked: index == currentMarkedIndex,
                    onSelected: () {
                      widget.viewModel.selectSki(currentSki);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                RunRecorderScreen.paddingFromEdge,
              ),
              child: BigButton(
                backgroundColor: theme.colorScheme.primary,
                title: 'STARTA TEST',
                onPress: widget.viewModel.selectedSki == null
                    ? null
                    : () {
                  widget.viewModel.startRun();
                },
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: SizedBox(
                child: Text(
                  "Avbryt",
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}