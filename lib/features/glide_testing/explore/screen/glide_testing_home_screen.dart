import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';
import '../../../../common/database/repository/glide_test_repository.dart';
import '../../create/glide_test_form.dart';
import '../widgets/my_glide_tests_list.dart';
import '../widgets/glide_testing_intro_card.dart';

class GlideTestingHomeScreen extends StatelessWidget {
  const GlideTestingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glideTestRepository = context.read<GlideTestRepository>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('GlidLabbet')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-glide-test-fab',
        icon: const Icon(Icons.add),
        label: const Text('Skapa nytt test'),
        onPressed: () async {
          final newTestCandidate =
              await showModalBottomSheet<GlideTestCandidate>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => const GlideTestForm(),
              );

          if (newTestCandidate != null) {
            await glideTestRepository.create(newTestCandidate);
          }
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlideTestingIntroCard(theme: theme),
            StreamBuilder(
              stream: glideTestRepository.watchTests(),
              builder: (context, snapshot) {
                return MyGlideTestsList(glideTests: snapshot.data ?? []);
              },
            ),
          ],
        ),
      ),
    );
  }
}
