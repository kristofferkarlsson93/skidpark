import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/record_test_run.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/start_test_run.dart';

import '../../../../common/database/database.dart';
import '../../../../common/database/repository/ski_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';

enum RunViewState { selectSki, recordRun }

class RunRecorderScreen extends StatefulWidget {
  static const double paddingFromEdge = 16.0;
  final int glideTestId;
  final DataRecorder dataRecorder;

  const RunRecorderScreen({
    super.key,
    required this.glideTestId,
    required this.dataRecorder,
  });

  @override
  State<RunRecorderScreen> createState() => _RunRecorderScreenState();
}

class _RunRecorderScreenState extends State<RunRecorderScreen> {
  StoredSkiData? selectedSki;
  DateTime? startedAt;
  RunViewState viewState = RunViewState.selectSki;

  Future<void> saveTestRun(
    TestRunRepository testRunRepository,
    List<Position> positions,
    int elapsedSeconds,
  ) {
    final candidate = TestRunCandidate(
      startedAt: startedAt!,
      skiId: selectedSki!.id,
      glideTestId: widget.glideTestId,
      elapsedSeconds: elapsedSeconds,
      gpsData: positions,
    );
    return testRunRepository.storeTestRun(candidate);
  }

  @override
  Widget build(BuildContext context) {
    final skiRepository = context.read<SkiRepository>();
    final testRunRepository = context.read<TestRunRepository>();
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
                  viewModel: widget.dataRecorder,
                  onStartClick: (newSelectedSki) {
                    setState(() {
                      startedAt = DateTime.now();
                      selectedSki = newSelectedSki;
                      viewState = RunViewState.recordRun;
                    });
                  },
                );
              },
            )
          : RecordTestRun(
            testSki: selectedSki!,
            dataRecorder: widget.dataRecorder,
            onStopAndSave: (positions, elapsedSeconds) {
              saveTestRun(testRunRepository, positions, elapsedSeconds);
              Navigator.pop(context);
            },
            onAbort: () {
              Navigator.pop(context);
            },
          ),
    );
  }
}
