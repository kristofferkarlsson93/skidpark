import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/record_test_run.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/start_test_run.dart';

import '../../../../common/database/repository/ski_repository.dart';
import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/input/hands_free_controls_factory.dart';
import '../../../../common/input/hands_free_input.dart';
import '../../../../common/shared_widgets/hands_free_input_handler.dart';
import '../../../../common/services/recording_display.dart';
import '../viewModel/run_recorder_view_model.dart';
import '../widgets/recording_start_countdown.dart';

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
    final controls = context.read<HandsFreeControlsFactory>().controller;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RunRecorderViewModel(
            testRunRepository: testRunRepository,
            skiRepository: skiRepository,
            glideTestRepository: glideTestRepository,
            controls: controls,
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
  RecordingDisplay? _display;
  bool _didHandleSavedRun = false;
  bool _didShowCurrentSaveFailure = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _display = context.read<HandsFreeControlsFactory>().recordingDisplay;
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
    _setKeepAwake(false);
    _viewModel?.removeListener(_handleViewModelChange);
    super.dispose();
  }

  void _setKeepAwake(bool enabled) {
    unawaited(
      _display?.setKeepAwake(enabled).catchError((Object error) {
        log('Could not update recording display', error: error);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RunRecorderViewModel>(
      builder: (context, viewModel, child) {
        return HandsFreeInputHandler(
          controller: context.read<HandsFreeControlsFactory>().controller,
          stage: viewModel.viewState == RunViewState.selectSki
              ? HandsFreeStage.skiSelection
              : HandsFreeStage.recording,
          enabled: viewModel.inputEnabled,
          onAction: viewModel.handleHandsFreeAction,
          onError: viewModel.handleInputError,
          onGuidance: viewModel.updateInputGuidance,
          onVisibilityChanged: (visible) {
            viewModel.setRouteVisible(visible);
            _setKeepAwake(visible);
          },
          child: PopScope(
            canPop: !viewModel.isSaving,
            child: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Offstage(
                    offstage: viewModel.startCountdownSeconds > 0,
                    child: viewModel.viewState == RunViewState.selectSki
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
                  if (viewModel.startCountdownSeconds > 0)
                    Positioned.fill(
                      child: BlockSemantics(
                        child: RecordingStartCountdown(
                          seconds: viewModel.startCountdownSeconds,
                          skiName: viewModel.selectedSki!.name,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
