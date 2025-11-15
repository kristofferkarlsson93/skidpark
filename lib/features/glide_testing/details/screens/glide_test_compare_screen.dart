import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/details/widgets/compare_controls.dart';
import 'package:skidpark/features/glide_testing/details/widgets/compare_view.dart';
import 'package:skidpark/features/glide_testing/details/widgets/glide_test_more_menu.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../compare/compare_runs_view_model.dart';
import '../../test_runs/data_recorder.dart';
import '../../test_runs/screen/run_recording_screen.dart';

class GlideTestCompareScreen extends StatefulWidget {
  final int glideTestId;

  const GlideTestCompareScreen({super.key, required this.glideTestId});

  @override
  State<GlideTestCompareScreen> createState() => _GlideTestCompareScreenState();
}

class _GlideTestCompareScreenState extends State<GlideTestCompareScreen> {
  late final DataRecorder _dataRecorder;

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
          builder: (context) => RunRecorderScreen(glideTestId: widget.glideTestId, dataRecorder: _dataRecorder),
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
      stream: glideTestRepository.watchTestById(this.widget.glideTestId),
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
            ChangeNotifierProvider(
              create: (_) => _dataRecorder,
            ),
          ],
          child: Scaffold(
            extendBodyBehindAppBar: true,
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
                GlideTestMoreMenu(onSelectEdit: () {}, onSelectArchive: () {}),
              ],
            ),
            body: Stack(children: [CompareView(), CompareControls(glideTest: glideTest)]),
          ),
        );
      },
    );
  }
}
