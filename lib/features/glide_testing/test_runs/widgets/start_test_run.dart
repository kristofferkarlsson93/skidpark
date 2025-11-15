import 'package:flutter/material.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';

import '../../../../common/database/database.dart';
import '../screen/run_recording_screen.dart';
import '../../../../common/shared_widgets/simple_ski_list_item.dart';
import '../viewModel/run_recorder_view_model.dart';

class StartTestRunWidget extends StatelessWidget {
  final List<StoredSkiData> selectableSkis;
  final RunRecorderViewModel viewModel;

  const StartTestRunWidget({
    super.key,
    required this.selectableSkis,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: viewModel.dataRecorder,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.all(
                    RunRecorderScreen.paddingFromEdge,
                  ),
                  child: GpsAccuracyBanner(
                    accuracyGrade: viewModel.dataRecorder.accuracyGrade,
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
                separatorBuilder: (context, index) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final currentSki = selectableSkis[index];
                  final isSelected = viewModel.selectedSki != null &&
                      viewModel.selectedSki!.id == currentSki.id;
                  return SimpleSkiListItem(
                    skiDetails: currentSki,
                    isSelected: isSelected,
                    isMarked: false,
                    onSelected: () {
                      viewModel.selectSki(currentSki);
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
                backgroundColor: theme.colorScheme.secondary,
                title: 'STARTA TEST',
                onPress: viewModel.selectedSki == null
                    ? null
                    : () {
                  viewModel.startRun();
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