import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/test_runs/screen/run_recording_screen.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/compare/compare_runs.dart';
import 'package:skidpark/features/glide_testing/test_overview/widgets/glide_test_edit_buttons.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../compare/compare_runs_view_model.dart';
import '../../models/decoded_test_run.dart';

class GlideTestScreen extends StatelessWidget {
  final int glideTestId;

  const GlideTestScreen({super.key, required this.glideTestId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glideTestRepository = context.read<GlideTestRepository>();
    final testRunRepository = context.read<TestRunRepository>();
    return StreamBuilder(
      stream: glideTestRepository.watchTestById(this.glideTestId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final glideTest = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: Text(glideTest.title)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final hasPermission =
                  await DataRecorder.handleLocationPermissions(context);
              if (!hasPermission) return;
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) =>
                        RunRecorderScreen(glideTestId: glideTestId),
                  ),
                );
              }
            },
            icon: Icon(Icons.play_circle_outline),
            label: Text("Spela in teståk"),
          ),
          body: Column(
            children: [
              // Center(child: GlideTestEditButtons()),
              SizedBox(height: 16),
              ChangeNotifierProvider(
                create: (_) => CompareRunsViewModel(
                  testRunRepository: testRunRepository,
                  glideTest: glideTest,
                ),
                child: Expanded(child: CompareRuns()),
              ),
            ],
          ),
        );
      },
    );
  }
}
