import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/common/services/volume_press_handler.dart';
import 'package:skidpark/features/glide_testing/explore/screen/glide_testing_home_screen.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('first-time journey creates a ski and opens an empty test', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final volumePressHandler = VolumePressHandler();
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
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const GlideTestingHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skapa mitt första test'));
    await tester.pumpAndSettle();
    expect(find.text('Nytt glidtest'), findsOneWidget);

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
    expect(await database.select(database.storedGlideTest).get(), hasLength(1));
    expect(await database.select(database.glideTestSki).get(), hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
