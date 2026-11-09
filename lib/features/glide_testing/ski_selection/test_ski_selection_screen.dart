import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/database/repository/glide_test_repository.dart';
import 'widgets/test_ski_selection_form.dart';

class TestSkiSelectionScreen extends StatelessWidget {
  const TestSkiSelectionScreen({super.key, required this.glideTestId});

  final int glideTestId;

  @override
  Widget build(BuildContext context) => TestSkiSelectionForm(
    title: 'Skidor i testet',
    submitLabel: 'Spara skidurval',
    glideTestId: glideTestId,
    onSave: (skiIds) async {
      await context.read<GlideTestRepository>().replaceSkisForTest(
        glideTestId,
        skiIds,
      );
      if (context.mounted) Navigator.pop(context);
    },
  );
}
