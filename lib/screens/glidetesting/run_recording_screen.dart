import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/database/database.dart';
import 'package:skidpark/database/repository/ski_repository.dart';
import 'package:skidpark/widgets/glidetesting/start_test_run.dart';

enum RunViewState { selectSki, recordRun }

class RunRecorderScreen extends StatefulWidget {
  static const double PADDING_FROM_EDGE = 16.0;
  final int glideTestId;

  const RunRecorderScreen({super.key, required this.glideTestId});

  @override
  State<RunRecorderScreen> createState() => _RunRecorderScreenState();
}

class _RunRecorderScreenState extends State<RunRecorderScreen> {
  StoredSkiData? selectedSki;
  RunViewState viewState = RunViewState.selectSki;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skiRepository = context.read<SkiRepository>();
    return Scaffold(
      // appBar: AppBar(),
      body: viewState == RunViewState.selectSki
          ? StreamBuilder(
              stream: skiRepository.watchSkis(),
              // TODO .watchSkisByTest(testId)
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Scaffold(
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }
                final skis = snapshot.data!;
                return StartTestRunWidget(
                  selectableSkis: skis,
                  onStartClick: (newSelectedSki) {
                    setState(() {
                      selectedSki = newSelectedSki;
                      viewState = RunViewState.recordRun;
                    });
                  },
                );
              },
            )
          : Container(child: Text(selectedSki!.name)),
    );
  }
}
