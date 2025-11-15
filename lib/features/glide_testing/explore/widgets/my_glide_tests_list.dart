import 'package:flutter/material.dart';

import '../../../../common/database/database.dart';
import '../../compare/screens/glide_test_compare_screen.dart';
import '../../test_runs/data_recorder.dart';
import 'glide_test_list_card.dart';

class MyGlideTestsList extends StatelessWidget {
  final List<StoredGlideTestData> glideTests;

  const MyGlideTestsList({super.key, required this.glideTests});

  @override
  Widget build(BuildContext context) {
    if (glideTests.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: glideTests.length,
            itemBuilder: (context, index) {
              return GlideTestListCard(
                glideTest: glideTests[index],
                onTestCardClicked: () async {
                  // should ideally be propagated to parent
                  final hasPermissions =
                      await DataRecorder.handleLocationPermissions(context);
                  if (!hasPermissions) return;
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GlideTestCompareScreen(
                          glideTestId: glideTests[index].id,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      );
    } else {
      return SizedBox(height: 16);
    }
  }
}
