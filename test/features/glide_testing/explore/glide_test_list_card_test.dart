import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/features/glide_testing/explore/widgets/glide_test_list_card.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('empty tests do not fabricate a ski count', (tester) async {
    final createdAt = DateTime.now();
    final summary = GlideTestSummary(
      test: StoredGlideTestData(
        id: 1,
        createdAt: createdAt,
        title: 'Tomt test',
        notes: null,
        useSensorFusion: false,
      ),
      runCount: 0,
      testedSkiCount: 0,
      latestActivityAt: createdAt,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: GlideTestListCard(summary: summary, onTestCardClicked: () {}),
        ),
      ),
    );

    expect(find.text('Inga åk ännu'), findsOneWidget);
    expect(find.text('0 skidor'), findsNothing);
    expect(find.textContaining('Skapad idag'), findsOneWidget);
    expect(find.textContaining('Senast idag'), findsNothing);
  });
}
