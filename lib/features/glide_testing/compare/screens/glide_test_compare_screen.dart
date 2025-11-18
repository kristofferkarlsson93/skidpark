import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_container.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/glide_test_more_menu.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
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
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => RunRecorderScreen(
            glideTestId: widget.glideTestId,
            dataRecorder: _dataRecorder,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final glideTestRepository = context.read<GlideTestRepository>();
    final testRunRepository = context.read<TestRunRepository>();
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: glideTestRepository.watchTestById(widget.glideTestId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final glideTest = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => CompareRunsViewModel(
                testRunRepository: testRunRepository,
                glideTest: glideTest,
              ),
            ),
            ChangeNotifierProvider(create: (_) => _dataRecorder),
          ],
          child: SafeArea(
            bottom: false,
            child: Scaffold(
              extendBodyBehindAppBar: true,
              key: _scaffoldKey,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                actions: [
                  FilledButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        theme.colorScheme.onPrimary,
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
                  GlideTestMoreMenu(
                    onSelectEdit: () {},
                    onSelectArchive: () {},
                  ),
                ],
              ),
              endDrawer: Drawer(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: CompareControls(glideTest: glideTest)
              ),
              body: Stack(children: [
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
              ]),
            ),
          ),
        );
      },
    );
  }
}
