import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/record_test_run.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/start_test_run.dart';

import '../../../../common/database/repository/ski_repository.dart';
import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/services/volume_press_handler.dart';
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
    final glideTestRepository = context.read<GlideTestRepository>();
    final testRunRepository = context.read<TestRunRepository>();
    final volumeButtonInput = context.read<VolumeButtonInput>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RunRecorderViewModel(
            testRunRepository: testRunRepository,
            skiRepository: skiRepository,
            glideTestRepository: glideTestRepository,
            volumeButtonInput: volumeButtonInput,
            dataRecorder: dataRecorder,
            glideTestId: glideTestId,
          ),
        ),
        ChangeNotifierProvider.value(value: dataRecorder),
      ],
      child: const _RunRecorderContent(),
    );
  }
}

class _RunRecorderContent extends StatefulWidget {
  const _RunRecorderContent();

  @override
  State<_RunRecorderContent> createState() => _RunRecorderContentState();
}

class _RunRecorderContentState extends State<_RunRecorderContent> {
  RunRecorderViewModel? _viewModel;
  bool _didHandleSavedRun = false;
  bool _didShowCurrentSaveFailure = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<RunRecorderViewModel>();
    if (identical(_viewModel, viewModel)) return;

    _viewModel?.removeListener(_handleViewModelChange);
    _viewModel = viewModel;
    viewModel.addListener(_handleViewModelChange);
  }

  void _handleViewModelChange() {
    final viewModel = _viewModel;
    if (viewModel == null) return;

    switch (viewModel.saveState) {
      case RunSaveState.idle:
        return;
      case RunSaveState.saving:
        _didShowCurrentSaveFailure = false;
        return;
      case RunSaveState.saved:
        if (_didHandleSavedRun) return;
        _didHandleSavedRun = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
        return;
      case RunSaveState.failed:
        if (_didShowCurrentSaveFailure) return;
        _didShowCurrentSaveFailure = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Åket kunde inte sparas. Försök igen.'),
            ),
          );
        });
        return;
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleViewModelChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RunRecorderViewModel>(
      builder: (context, viewModel, child) {
        return PopScope(
          canPop: !viewModel.isSaving,
          child: Scaffold(
            body: viewModel.viewState == RunViewState.selectSki
                ? StartTestRunWidget(viewModel: viewModel)
                : RecordTestRun(
                    viewModel: viewModel,
                    onStopAndSave: viewModel.stopAndSaveRun,
                    onAbort: () {
                      viewModel.abortRun();
                      Navigator.pop(context);
                    },
                  ),
          ),
        );
      },
    );
  }
}
