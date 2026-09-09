import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/navigation/bottom_navigation.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('starts on Tester with the agreed navigation order', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GlideTestRepository>.value(
            value: GlideTestRepository(database),
          ),
          Provider<SkiRepository>.value(value: SkiRepository(database)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const BottomNavigator(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 0);
    expect(find.text('Tester'), findsOneWidget);
    expect(find.text('Skidor'), findsOneWidget);
    expect(find.text('Mer'), findsOneWidget);
    expect(find.text('Bättre underlag för dagens skidval.'), findsOneWidget);

    await tester.tap(find.text('Skidor'));
    await tester.pumpAndSettle();

    expect(find.text('Din skidpark är tom'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('filled test header fits a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final glideTestRepository = GlideTestRepository(database);
    await database
        .into(database.storedGlideTest)
        .insert(
          StoredGlideTestCompanion.insert(
            title: 'Ett testnamn som är långt nog för en smal skärm',
          ),
        );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GlideTestRepository>.value(value: glideTestRepository),
          Provider<SkiRepository>.value(value: SkiRepository(database)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const BottomNavigator(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Nytt test'), findsOneWidget);
    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: exception is FlutterError ? exception.toStringDeep() : null,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
