import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/record_test_run.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/start_test_run.dart';

import '../../../../common/database/repository/ski_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../viewModel/run_recorder_view_model.dart';

class RunRecorderScreen extends StatelessWidget {
  static const double paddingFromEdge = 16.0;
  final int glideTestId;
  final DataRecorder dataRecorder;

  const RunRecorderScreen({
    super.key,
    required this.glideTestId,
    required this.dataRecorder,
  });

  @override
  Widget build(BuildContext context) {
    final skiRepository = context.read<SkiRepository>();
    final testRunRepository = context.read<TestRunRepository>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RunRecorderViewModel(
            testRunRepository: testRunRepository,
            dataRecorder: dataRecorder,
            glideTestId: glideTestId,
          ),
        ),
        ChangeNotifierProvider.value(value: dataRecorder),
      ],
      child: Scaffold(
        body: Consumer<RunRecorderViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.viewState == RunViewState.selectSki) {
              return StreamBuilder(
                stream: skiRepository.watchSkis(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final skis = snapshot.data!;
                  return StartTestRunWidget(
                    selectableSkis: skis,
                    viewModel: viewModel,
                  );
                },
              );
            } else {
              return RecordTestRun(
                viewModel: viewModel,
                onStopAndSave: () async {
                  await viewModel.stopAndSaveRun();
                  if (context.mounted) Navigator.pop(context);
                },
                onAbort: () {
                  viewModel.abortRun();
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }
          },
        ),
      ),
    );
  }
}
