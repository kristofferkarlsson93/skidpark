import 'package:flutter/material.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';

import '../../../../common/database/database.dart';
import '../screen/run_recording_screen.dart';
import '../../../../common/shared_widgets/simple_ski_list_item.dart';

class StartTestRunWidget extends StatefulWidget {
  final List<StoredSkiData> selectableSkis;
  final void Function(StoredSkiData) onStartClick;

  final DataRecorder viewModel;

  const StartTestRunWidget({
    super.key,
    required this.selectableSkis,
    required this.onStartClick,
    required this.viewModel,
  });

  @override
  State<StartTestRunWidget> createState() => _StartTestRunWidgetState();
}

class _StartTestRunWidgetState extends State<StartTestRunWidget> {
  StoredSkiData? selectedSki;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.all(
                    RunRecorderScreen.PADDING_FROM_EDGE,
                  ),
                  child: GpsAccuracyBanner(
                    accuracyGrade: widget.viewModel.accuracyGrade,
                  ),
                );
              },
            ),
            SizedBox(height: 48),
            Text("Välj skida för åket", style: theme.textTheme.titleMedium),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(
                  RunRecorderScreen.PADDING_FROM_EDGE,
                ),
                itemCount: widget.selectableSkis.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final currentSki = widget.selectableSkis[index];
                  return SimpleSkiListItem(
                    skiDetails: currentSki,
                    isSelected:
                        selectedSki != null && selectedSki!.id == currentSki.id,
                    isMarked: false,
                    onSelected: () {
                      setState(() {
                        selectedSki = currentSki;
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                RunRecorderScreen.PADDING_FROM_EDGE,
              ),
              child: BigButton(
                backgroundColor: theme.colorScheme.secondary,
                title: 'STARTA TEST',
                onPress: selectedSki == null
                    ? null
                    : () {
                        widget.onStartClick(selectedSki!);
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
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
