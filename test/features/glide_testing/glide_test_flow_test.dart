import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/common/services/volume_press_handler.dart';
import 'package:skidpark/common/input/hands_free_controls_factory.dart';
import 'package:skidpark/common/shared_widgets/hands_free_input_handler.dart';
import 'package:skidpark/features/glide_testing/explore/screen/glide_testing_home_screen.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('first-time journey creates a ski and opens an empty test', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final volumePressHandler = UnsupportedVolumeButtonInput();
    addTearDown(database.close);
    addTearDown(volumePressHandler.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GlideTestRepository>.value(
            value: GlideTestRepository(database),
          ),
          Provider<SkiRepository>.value(value: SkiRepository(database)),
          Provider<TestRunRepository>.value(value: TestRunRepository(database)),
          Provider<VolumeButtonInput>.value(value: volumePressHandler),
          Provider<HandsFreeControlsFactory>(
            create: (_) => HandsFreeControlsFactory(
              platform: TargetPlatform.android,
              volumeInput: volumePressHandler,
            ),
            dispose: (_, factory) => factory.dispose(),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [handsFreeRouteObserver],
          theme: AppTheme.darkTheme,
          home: const GlideTestingHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skapa mitt första test'));
    await tester.pumpAndSettle();
    expect(find.text('Nytt glidtest'), findsOneWidget);
    expect(find.text('Anteckningar'), findsNothing);

    await tester.ensureVisible(find.text('Lägg till ny skida'));
    await tester.tap(find.text('Lägg till ny skida'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Skidans namn'),
      'SP1',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Lägg till'));
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lägg till'));
    await tester.pumpAndSettle();

    expect(await database.select(database.storedSki).get(), hasLength(1));
    await tester.tap(find.widgetWithText(FilledButton, 'Skapa test'));
    await tester.pumpAndSettle();

    expect(find.text('Nytt åk'), findsOneWidget);
    expect(find.textContaining('volym ner'), findsNothing);
    expect(await database.select(database.storedGlideTest).get(), hasLength(1));
    expect(await database.select(database.glideTestSki).get(), hasLength(1));

    final createdTest = await database
        .select(database.storedGlideTest)
        .getSingle();
    expect(createdTest.notes, isNull);
    await tester.tap(find.text('Lägg till anteckning'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Anteckningar om testet'),
      'Kall nysnö',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Spara'));
    await tester.tap(find.widgetWithText(FilledButton, 'Spara'));
    await tester.pumpAndSettle();
    final updatedTest = await database
        .select(database.storedGlideTest)
        .getSingle();
    expect(updatedTest.notes, 'Kall nysnö');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
