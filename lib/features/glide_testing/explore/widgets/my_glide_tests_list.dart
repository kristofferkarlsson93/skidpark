import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/test_overview/screen/glide_test_screen.dart';

import '../../../../common/database/database.dart';
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
                onTestCardClicked: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GlideTestScreen(glideTestId: glideTests[index].id),
                    ),
                  );
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
