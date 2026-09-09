import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/features/ski_management/create/add_ski_form.dart';
import 'package:skidpark/features/ski_management/exlore/widgets/my_skis_component.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('ski park search matches own name and model', (tester) async {
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);
    var query = '';
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MySkisComponent(
                skis: [
                  _ski(1, 'Atomic Röd', 'Redster S9'),
                  _ski(2, 'SP1 Kallföre', 'Fischer Speedmax'),
                ],
                searchController: searchController,
                searchQuery: query,
                onSearchChanged: (value) {
                  rebuild(() => query = value);
                },
                onAddSki: () {},
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'fischer');
    await tester.pump();

    expect(find.text('SP1 Kallföre'), findsOneWidget);
    expect(find.text('Atomic Röd'), findsNothing);
  });

  testWidgets('ski form progressively discloses optional fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const AddSkiForm()),
    );

    expect(find.text('Skidans namn'), findsOneWidget);
    expect(find.text('Märke och modell (valfritt)'), findsOneWidget);
    expect(find.text('Teknisk data'), findsNothing);

    await tester.tap(find.text('Fler uppgifter'));
    await tester.pumpAndSettle();

    expect(find.text('Teknisk data'), findsOneWidget);
    expect(find.text('Anteckningar'), findsOneWidget);
  });

  testWidgets('six skis and long names fit the compact list layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: MySkisComponent(
            skis: List.generate(
              6,
              (index) => _ski(
                index,
                index == 0
                    ? 'Ett mycket långt beskrivande skidnamn för kallföre'
                    : 'SP${index + 1}',
                'Fischer Speedmax ${index + 1}',
              ),
            ),
            searchController: searchController,
            searchQuery: '',
            onSearchChanged: (_) {},
            onAddSki: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('6 par'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

StoredSkiData _ski(int id, String name, String model) {
  return StoredSkiData(
    id: id,
    createdAt: DateTime(2026),
    name: name,
    brandAndModel: model,
    technicalData: null,
    notes: null,
    archivedAt: null,
  );
}
