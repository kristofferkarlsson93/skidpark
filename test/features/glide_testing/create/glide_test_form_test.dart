import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/features/glide_testing/create/glide_test_form.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('selects all skis by default and rejects an empty selection', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    for (var index = 1; index <= 6; index++) {
      await database
          .into(database.storedSki)
          .insert(StoredSkiCompanion.insert(name: 'SP$index'));
    }
    GlideTestCandidate? result;

    await tester.pumpWidget(
      _TestApp(database: database, onResult: (candidate) => result = candidate),
    );
    await tester.tap(find.text('Öppna formulär'));
    await tester.pumpAndSettle();

    expect(find.text('6 av 6 valda'), findsOneWidget);
    expect(find.text('Sök bland skidor'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Alla'))
          .child,
      isA<Text>(),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ingen'));
    await tester.tap(find.widgetWithText(FilledButton, 'Skapa test'));
    await tester.pump();
    expect(find.text('Välj minst en skida till testet.'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Alla'));
    await tester.tap(find.widgetWithText(FilledButton, 'Skapa test'));
    await tester.pumpAndSettle();
    expect(result?.skiIds, [1, 2, 3, 4, 5, 6]);
  });

  testWidgets('adds multiple real skis without leaving the test form', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'Inte vald'));
    GlideTestCandidate? result;

    await tester.pumpWidget(
      _TestApp(database: database, onResult: (candidate) => result = candidate),
    );
    await tester.tap(find.text('Öppna formulär'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Ingen'));

    await tester.ensureVisible(find.text('Lägg till ny skida'));
    await tester.tap(find.text('Lägg till ny skida'));
    await tester.pumpAndSettle();

    for (final (index, name) in ['SP1', 'SP2'].indexed) {
      await tester.enterText(
        find.widgetWithText(TextField, 'Skidans namn'),
        name,
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Lägg till'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lägg till'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Skidans namn'))
            .controller
            ?.text,
        isEmpty,
      );
      expect(
        await SkiRepository(database).getActiveSkis(),
        hasLength(index + 2),
      );
    }

    final skis = await SkiRepository(database).getActiveSkis();
    expect(skis.map((ski) => ski.name), ['Inte vald', 'SP1', 'SP2']);

    await tester.tap(find.widgetWithText(TextButton, 'Avbryt'));
    await tester.tap(find.widgetWithText(FilledButton, 'Skapa test'));
    await tester.pumpAndSettle();
    expect(result?.skiIds, [2, 3]);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.database, required this.onResult});

  final AppDatabase database;
  final ValueChanged<GlideTestCandidate?> onResult;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SkiRepository>.value(value: SkiRepository(database)),
        Provider<GlideTestRepository>.value(
          value: GlideTestRepository(database),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  final result = await Navigator.push<GlideTestCandidate>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GlideTestForm(),
                    ),
                  );
                  onResult(result);
                },
                child: const Text('Öppna formulär'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
