import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/database/repository/glide_test_repository.dart';
import 'package:skidpark/models/glide_test/glide_test_candidate.dart';

import '../../widgets/glidetesting/add_glide_test_form.dart';
import '../../widgets/glidetesting/my_glide_tests_list.dart';

class GlideTestingHomeScreen extends StatelessWidget {
  const GlideTestingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glideTestRepository = context.read<GlideTestRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('GlidLabbet')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-glide-test-fab',
        child: const Icon(Icons.add),
        onPressed: () async {
          final newTestCandiate =
              await showModalBottomSheet<GlideTestCandidate>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => const AddGlideTestForm(),
              );

          if (newTestCandiate != null) {
            await glideTestRepository.create(newTestCandiate);
          }
        },
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          buildIntroText(),
          StreamBuilder(
            stream: glideTestRepository.watchTests(),
            builder: (context, snapshot) {
              return MyGlideTestsList(glideTests: snapshot.data ?? []);
            },
          ),
        ],
      ),
    );
  }

  Row buildIntroText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "Här kan du skapa och titta på glidtester \nKlicka på + för att skapa ett nytt test",
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
