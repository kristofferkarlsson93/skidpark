import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/shared_widgets/volume_input_handler.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/glide_test_more_menu.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/services/volume_press_handler.dart';
import '../../compare/compare_runs_view_model.dart';
import '../../create/glide_test_form.dart';
import '../../models/glide_test_candidate.dart';
import '../../test_runs/data_recorder.dart';
import '../../test_runs/screen/run_recording_screen.dart';
import '../models/analysis_page.dart';
import '../widgets/analysis_workspace.dart';
import '../widgets/compare_controls.dart';

class GlideTestCompareScreen extends StatefulWidget {
  final int glideTestId;

  const GlideTestCompareScreen({super.key, required this.glideTestId});

  @override
  State<GlideTestCompareScreen> createState() => _GlideTestCompareScreenState();
}

class _GlideTestCompareScreenState extends State<GlideTestCompareScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _activateVolumeKeys = true;
  bool _isDrawerOpen = false;
  bool _indicateNewRunMarked = false;
  bool _isStartingRecordingFlow = false;

  Future<void> _openRunRecorder(BuildContext context) async {
    if (_isStartingRecordingFlow ||
        _isDrawerOpen ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _isStartingRecordingFlow = true;

    DataRecorder? dataRecorder;
    try {
      final test = await context.read<GlideTestRepository>().getTestById(
        widget.glideTestId,
      );
      if (test == null || test.isExample || !context.mounted) return;

      final hasPermissions = await DataRecorder.handleLocationPermissions(
        context,
      );
      if (!hasPermissions || !context.mounted) return;

      final activeRecorder = DataRecorder();
      dataRecorder = activeRecorder;
      activeRecorder.startGPSSubscription(GpsMode.passive);
      setState(() => _activateVolumeKeys = false);

      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => RunRecorderScreen(
            glideTestId: widget.glideTestId,
            dataRecorder: activeRecorder,
          ),
        ),
      );
    } finally {
      await dataRecorder?.close();
      dataRecorder?.dispose();
      _isStartingRecordingFlow = false;
      if (mounted) {
        setState(() {
          _indicateNewRunMarked = false;
          _activateVolumeKeys = true;
        });
      }
    }
  }

  void _editTestInfo(
    BuildContext context,
    CompareRunsViewModel viewModel,
  ) async {
    final updatedTest = await Navigator.push<GlideTestCandidate>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => GlideTestForm(testToEdit: viewModel.glideTest),
      ),
    );

    if (updatedTest == null) return;
    await viewModel.updateGlideTestInfo(updatedTest);
  }

  void _deleteGlideTest(
    BuildContext context,
    CompareRunsViewModel viewModel,
  ) async {
    bool didConfirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Radera "${viewModel.testTitle}"?'),
            content: Text(
              'Är du säker på att du vill radera "${viewModel.testTitle}"? All testdata i detta test kommer gå förlorad.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Avbryt'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Radera'),
              ),
            ],
          ),
        ) ??
        false; // in case of discard (click outside) return false.

    if (didConfirm && context.mounted) {
      await viewModel.deleteCurrentGlideTest();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Testet raderat')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glideTestRepository = context.read<GlideTestRepository>();
    final testRunRepository = context.read<TestRunRepository>();
    final theme = Theme.of(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CompareRunsViewModel(
            testRunRepository: testRunRepository,
            glideTestRepository: glideTestRepository,
            glideTestId: widget.glideTestId,
          ),
        ),
      ],
      child: SafeArea(
        bottom: false,
        child: VolumeInputHandler(
          shouldPublishEvents: _activateVolumeKeys && !_isDrawerOpen,
          onLongPress: (button) async {
            if (button == VolumeButton.down &&
                !_isDrawerOpen &&
                ModalRoute.of(context)?.isCurrent == true) {
              log("Go to record page via volume down");
              setState(() {
                _indicateNewRunMarked = true;
              });
              await Future.delayed(const Duration(milliseconds: 250));
              if (context.mounted) {
                _openRunRecorder(context);
              }
            }
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              actions: [
                Consumer<CompareRunsViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.glideTest?.isExample ?? false) {
                      return const SizedBox.shrink();
                    }
                    return FilledButton.icon(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          _indicateNewRunMarked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerLowest,
                        ),
                      ),
                      onPressed: () => _openRunRecorder(context),
                      label: Text(
                        'Nytt åk',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      icon: Icon(
                        Icons.play_circle_outline,
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  },
                ),
                Consumer<CompareRunsViewModel>(
                  builder: (context, viewModel, _) {
                    return GlideTestMoreMenu(
                      onSelectEdit: viewModel.glideTest?.isExample ?? false
                          ? null
                          : () => _editTestInfo(context, viewModel),
                      onSelectExport: () {
                        viewModel.exportAllGlideTestData();
                      },
                      onSelectDelete: () {
                        _deleteGlideTest(context, viewModel);
                      },
                    );
                  },
                ),
              ],
            ),
            onEndDrawerChanged: (isOpen) {
              setState(() => _isDrawerOpen = isOpen);
            },
            endDrawer: Drawer(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              child: const CompareControls(),
            ),
            body: Consumer<CompareRunsViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final isGuide =
                    viewModel.testRuns.isEmpty ||
                    viewModel.activeAnalysisPage == AnalysisPage.guide;
                return Stack(
                  children: [
                    AnalysisWorkspace(
                      onOpenControls: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                    if (!isGuide)
                      Positioned(
                        top: kToolbarHeight,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerLowest,
                          child: IconButton(
                            icon: const Icon(Icons.tune),
                            color: theme.colorScheme.onSurface,
                            tooltip: 'Filtrera',
                            onPressed: () =>
                                _scaffoldKey.currentState?.openEndDrawer(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
