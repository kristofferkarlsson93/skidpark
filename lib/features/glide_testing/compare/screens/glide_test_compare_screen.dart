import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/shared_widgets/volume_input_handler.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/overview_container.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/glide_test_more_menu.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/release_point_analysis/release_point_container.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/services/volume_press_handler.dart';
import '../../compare/compare_runs_view_model.dart';
import '../../create/glide_test_form.dart';
import '../../models/glide_test_candidate.dart';
import '../../test_runs/data_recorder.dart';
import '../../test_runs/screen/run_recording_screen.dart';
import '../widgets/compare_controls.dart';

enum AnalysisPage { overview, deepAnalysis }

class GlideTestCompareScreen extends StatefulWidget {
  final int glideTestId;

  const GlideTestCompareScreen({super.key, required this.glideTestId});

  @override
  State<GlideTestCompareScreen> createState() => _GlideTestCompareScreenState();
}

class _GlideTestCompareScreenState extends State<GlideTestCompareScreen> {
  late final DataRecorder _dataRecorder;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  bool _activateVolumeKeys = true;
  bool _indicateNewRunMarked = false;

  @override
  void initState() {
    super.initState();
    _dataRecorder = DataRecorder();
    _dataRecorder.startGPSSubscription(GpsMode.passive); // warm up GPS
  }

  @override
  void dispose() {
    _dataRecorder.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void goToRecordPage(BuildContext context) async {
    if (context.mounted) {
      // We use volume keys on the RunRecorderScreen. Need to disable them here.
      setState(() {
        _activateVolumeKeys = false;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => RunRecorderScreen(
            glideTestId: widget.glideTestId,
            dataRecorder: _dataRecorder,
          ),
        ),
      );
      // The await above makes it so that we run this code when we return here.
      setState(() {
        _indicateNewRunMarked = false;
        _activateVolumeKeys = true;
      });
    }
  }

  void _animateToPage(AnalysisPage page) {
    _pageController.animateToPage(
      page.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _editTestInfo(
    BuildContext context,
    CompareRunsViewModel viewModel,
  ) async {
    final updatedTest = await showModalBottomSheet<GlideTestCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => GlideTestForm(testToEdit: viewModel.glideTest),
    );

    if (updatedTest != null) {
      viewModel.updateGlideTestInfo(updatedTest);
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
        ChangeNotifierProvider(create: (_) => _dataRecorder),
      ],
      child: SafeArea(
        bottom: false,
        child: VolumeInputHandler(
          shouldPublishEvents: _activateVolumeKeys,
          onLongPress: (button) async {
            if (button == VolumeButton.down) {
              log("Go to record page via volume down");
              setState(() {
                _indicateNewRunMarked = true;
              });
              await Future.delayed(const Duration(milliseconds: 250));
              if (context.mounted) {
                goToRecordPage(context);
              }
            }
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              actions: [
                FilledButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      _indicateNewRunMarked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
                  onPressed: () {
                    goToRecordPage(context);
                  },
                  label: Text(
                    'Nytt åk',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  icon: Icon(
                    Icons.play_circle_outline,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Consumer<CompareRunsViewModel>(
                  builder: (context, viewModel, _) {
                    return GlideTestMoreMenu(
                      onSelectEdit: () {
                        _editTestInfo(context, viewModel);
                      },
                      onSelectArchive: () {},
                    );
                  },
                ),
              ],
            ),
            endDrawer: Drawer(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: CompareControls(),
            ),
            body: Consumer<CompareRunsViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  children: [
                    PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        // todo rename to overview container.
                        OverviewContainer(),
                        ReleasePointContainer(),
                      ],
                    ),
                    Positioned(
                      top: kToolbarHeight,
                      right: 8, // 16.0 from the right edge
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.black,
                            child: IconButton(
                              icon: const Icon(Icons.tune),
                              color: Colors.white,
                              tooltip: 'Filtrera',
                              onPressed: () {
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                            ),
                          ),
                          SizedBox(height: 8),
                          Theme(
                            data: Theme.of(context).copyWith(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Material(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                              child: ToggleButtons(
                                direction: Axis.vertical,
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                renderBorder: false,
                                fillColor: theme.colorScheme.primary.withAlpha(
                                  155,
                                ),
                                selectedColor: Colors.white,
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                  minWidth: 40,
                                ),
                                isSelected: [
                                  viewModel.activeAnalysisPage ==
                                      AnalysisPage.overview,
                                  viewModel.activeAnalysisPage ==
                                      AnalysisPage.deepAnalysis,
                                ],

                                onPressed: (index) {
                                  final newPage = index == 0
                                      ? AnalysisPage.overview
                                      : AnalysisPage.deepAnalysis;

                                  if (viewModel.activeAnalysisPage != newPage) {
                                    viewModel.setCurrentAnalysisPage(newPage);
                                    _animateToPage(newPage);
                                  }
                                },

                                children: const [
                                  Icon(Icons.home_outlined, size: 20),
                                  Icon(Icons.compare_arrows, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
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
