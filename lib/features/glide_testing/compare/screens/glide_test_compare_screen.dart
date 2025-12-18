import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/shared_widgets/volume_input_handler.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_container.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/glide_test_more_menu.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../../common/services/volume_press_handler.dart';
import '../../compare/compare_runs_view_model.dart';
import '../../test_runs/data_recorder.dart';
import '../../test_runs/screen/run_recording_screen.dart';
import '../widgets/compare_controls.dart';

class GlideTestCompareScreen extends StatefulWidget {
  final int glideTestId;

  const GlideTestCompareScreen({super.key, required this.glideTestId});

  @override
  State<GlideTestCompareScreen> createState() => _GlideTestCompareScreenState();
}

class _GlideTestCompareScreenState extends State<GlideTestCompareScreen> {
  late final DataRecorder _dataRecorder;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
                GlideTestMoreMenu(onSelectEdit: () {}, onSelectArchive: () {}),
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
                    CompareContainer(),
                    Positioned(
                      top: kToolbarHeight,
                      right: 8, // 16.0 from the right edge
                      child: CircleAvatar(
                        backgroundColor: Colors.black,
                        child: IconButton(
                          icon: const Icon(Icons.tune),
                          color: Colors.white,
                          tooltip: 'Filter runs',
                          onPressed: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
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
