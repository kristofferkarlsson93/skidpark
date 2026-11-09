import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/common/services/volume_press_handler.dart';
import 'package:skidpark/common/input/hands_free_controls_factory.dart';
import 'package:skidpark/common/shared_widgets/hands_free_input_handler.dart';
import 'package:skidpark/features/glide_testing/compare/compare_runs_view_model.dart';
import 'package:skidpark/features/glide_testing/compare/models/analysis_page.dart';
import 'package:skidpark/features/glide_testing/compare/screens/glide_test_compare_screen.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/analysis_workspace.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_graph.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/test_info.dart';
import 'package:skidpark/features/glide_testing/ski_selection/test_ski_selection_screen.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gps_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/sensor_recording_metadata.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('ski selection actions remain reachable above a phone keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final repository = GlideTestRepository(fixture.database);
    await repository.replaceSkisForTest(fixture.testId, [1]);
    await fixture.open(tester);
    await Scrollable.ensureVisible(
      tester.element(find.text('Ändra skidor')),
      alignment: .5,
    );
    await _settleInput(tester);
    await tester.tap(find.text('Ändra skidor'));
    await _settleInput(tester);
    await tester.tap(find.text('Lägg till ny skida'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await _settleInput(tester);
    final save = find.widgetWithText(FilledButton, 'Spara skidurval');
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(440));
    expect(save.hitTestable(), findsOneWidget);
    final cancel = find.widgetWithText(TextButton, 'Avbryt');
    expect(cancel.hitTestable(), findsOneWidget);
    expect(find.text('Stäng'), findsOneWidget);
    await tester.tap(cancel);
    await _settleInput(tester);
    expect(find.byType(TestSkiSelectionScreen), findsNothing);
    expect(await repository.getSkiIdsForTest(fixture.testId), [1]);
    await _unmount(tester);
  });

  for (final runCount in [0, 2]) {
    testWidgets(
      'ski selection can cancel and save without altering $runCount existing runs',
      (tester) async {
        final fixture = await _Fixture.create(runCount: runCount);
        addTearDown(fixture.dispose);
        final repository = GlideTestRepository(fixture.database);
        final first = await fixture.database
            .select(fixture.database.storedSki)
            .getSingle();
        final secondId = await fixture.database
            .into(fixture.database.storedSki)
            .insert(StoredSkiCompanion.insert(name: 'SP2'));
        await repository.replaceSkisForTest(fixture.testId, [first.id]);
        await repository.updateDetails(
          fixture.testId,
          title: 'Test',
          notes: 'Svag vind',
        );
        await fixture.open(tester);
        if (runCount > 0) {
          await tester.tap(find.widgetWithText(Tab, 'Testet'));
          await _settleInput(tester);
        }
        Future<void> openSelection() async {
          await Scrollable.ensureVisible(
            tester.element(find.widgetWithText(TextButton, 'Ändra skidor')),
            alignment: .5,
          );
          await _settleInput(tester);
          await tester.tap(find.widgetWithText(TextButton, 'Ändra skidor'));
          await _settleInput(tester);
        }

        await openSelection();
        expect(find.byType(TestSkiSelectionScreen), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'SP1'),
              )
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'SP2'),
              )
              .value,
          isFalse,
        );
        fixture.volume.emitLong(VolumeButton.down);
        await tester.pump(const Duration(milliseconds: 350));
        expect(fixture.location.checkCount, 0);
        await tester.tap(find.text('SP2'));
        await tester.tap(find.widgetWithText(TextButton, 'Avbryt'));
        await _settleInput(tester);
        expect(await repository.getSkiIdsForTest(fixture.testId), [first.id]);

        await openSelection();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Ingen'));
        await tester.tap(find.text('Spara skidurval'));
        await _settleInput(tester);
        expect(find.text('Välj minst en skida till testet.'), findsOneWidget);
        await tester.tap(find.text('SP2'));
        await tester.tap(find.text('Spara skidurval'));
        await _settleInput(tester);
        expect(await repository.getSkiIdsForTest(fixture.testId), [secondId]);
        expect(_viewModel(tester).selectedSkis.map((ski) => ski.name), ['SP2']);
        expect(_viewModel(tester).testRuns.length, runCount);
        final saved = (await repository.getTestById(fixture.testId))!;
        expect(saved.title, 'Test');
        expect(saved.notes, 'Svag vind');
        await tester.tap(find.byTooltip('Fler alternativ'));
        await _settleInput(tester);
        expect(find.text('Redigera testinfo'), findsNothing);
        expect(find.text('Exportera all data'), findsOneWidget);
        Navigator.of(tester.element(find.byType(AnalysisWorkspace))).pop();
        await _settleInput(tester);
        fixture.volume.emitLong(VolumeButton.down);
        await tester.pump(const Duration(milliseconds: 350));
        await _settleInput(tester);
        expect(fixture.location.checkCount, 1);
        await _unmount(tester);
      },
    );
  }

  testWidgets('test details save without changing skis or analysis settings', (
    tester,
  ) async {
    final fixture = await _Fixture.create(runCount: 2);
    addTearDown(fixture.dispose);
    final ski = await fixture.database
        .select(fixture.database.storedSki)
        .getSingle();
    await fixture.database
        .into(fixture.database.glideTestSki)
        .insert(
          GlideTestSkiCompanion.insert(
            glideTestId: fixture.testId,
            skiId: ski.id,
            sortOrder: 0,
          ),
        );
    await GlideTestRepository(fixture.database)
        .setUseSensorFusion(fixture.testId, true);
    await fixture.open(tester);
    await tester.tap(find.widgetWithText(Tab, 'Testet'));
    await _settleInput(tester);
    expect(find.byType(TextFormField), findsNothing);
    expect(
      tester
          .widget<ExpansionTile>(
            find.widgetWithText(ExpansionTile, 'Så gör du ett glidtest'),
          )
          .initiallyExpanded,
      isFalse,
    );
    await tester.tap(find.byTooltip('Redigera testnamn'));
    await _settleInput(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Testnamn'),
      '  Kall nysnö  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Anteckningar om testet'),
      'SP1 kändes stabilare.',
    );
    await tester.tap(find.widgetWithText(Tab, 'Översikt'));
    await _settleInput(tester);
    expect(_viewModel(tester).hasUnsavedDetails, isTrue);
    expect(find.byType(TextFormField), findsNothing);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 350));
    expect(fixture.location.checkCount, 0);
    await tester.tap(find.widgetWithText(Tab, 'Testet'));
    await _settleInput(tester);
    expect(
      find.widgetWithText(TextFormField, 'SP1 kändes stabilare.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Spara'));
    await tester.tap(find.widgetWithText(FilledButton, 'Spara'));
    await _settleInput(tester);
    final saved = await GlideTestRepository(fixture.database)
        .getTestById(fixture.testId);
    expect(saved!.title, 'Kall nysnö');
    expect(saved.notes, 'SP1 kändes stabilare.');
    expect(saved.useSensorFusion, isTrue);
    expect(
      await fixture.database.select(fixture.database.glideTestSki).get(),
      hasLength(1),
    );
    expect(_viewModel(tester).testRuns, hasLength(2));
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('SP1 kändes stabilare.'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets(
    'ski selection preserves order, retries failed saves and protects unsaved choices',
    (tester) async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final repository = GlideTestRepository(fixture.database);
      final secondId = await fixture.database
          .into(fixture.database.storedSki)
          .insert(StoredSkiCompanion.insert(name: 'SP2'));
      await repository.replaceSkisForTest(fixture.testId, [secondId, 1]);
      await fixture.open(tester);
      Future<void> openSelection() async {
        await Scrollable.ensureVisible(
          tester.element(find.widgetWithText(TextButton, 'Ändra skidor')),
          alignment: .5,
        );
        await _settleInput(tester);
        await tester.tap(find.text('Ändra skidor'));
        await _settleInput(tester);
      }

      await openSelection();
      await tester.tap(find.text('Spara skidurval'));
      await _settleInput(tester);
      expect(await repository.getSkiIdsForTest(fixture.testId), [secondId, 1]);

      await openSelection();
      await tester.tap(find.text('SP1'));
      await fixture.database.customStatement(
        "CREATE TRIGGER fail_selection BEFORE DELETE ON glide_test_ski BEGIN SELECT RAISE(ABORT, 'save failure'); END;",
      );
      await tester.tap(find.text('Spara skidurval'));
      await _settleInput(tester);
      expect(
        find.text(
          'Kunde inte spara skidurvalet. Dina val finns kvar. Försök igen.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'SP1'),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'SP2'),
            )
            .value,
        isTrue,
      );
      expect(await repository.getSkiIdsForTest(fixture.testId), [secondId, 1]);
      await fixture.database.customStatement('DROP TRIGGER fail_selection;');
      await tester.tap(find.text('Spara skidurval'));
      await _settleInput(tester);
      expect(await repository.getSkiIdsForTest(fixture.testId), [secondId]);

      await openSelection();
      await tester.tap(find.text('SP1'));
      await _settleInput(tester);
      await tester.binding.handlePopRoute();
      await _settleInput(tester);
      expect(find.text('Lämna utan att spara?'), findsOneWidget);
      await tester.tap(find.text('Fortsätt välja'));
      await _settleInput(tester);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'SP1'),
            )
            .value,
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await _settleInput(tester);
      await tester.tap(find.text('Lämna'));
      await _settleInput(tester);
      expect(find.byType(TestSkiSelectionScreen), findsNothing);
      expect(await repository.getSkiIdsForTest(fixture.testId), [secondId]);
      await _unmount(tester);
    },
  );

  testWidgets(
    'empty test validates name, cancels notes and can clear saved notes',
    (tester) async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final repository = GlideTestRepository(fixture.database);
      await repository.updateDetails(
        fixture.testId,
        title: 'Test',
        notes: 'Befintlig anteckning',
      );
      await fixture.open(tester);
      await tester.tap(find.byTooltip('Redigera testnamn'));
      await _settleInput(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Testnamn'),
        '  ',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Spara'));
      await tester.tap(find.widgetWithText(FilledButton, 'Spara'));
      await _settleInput(tester);
      expect(find.text('Ange ett testnamn.'), findsOneWidget);
      expect((await repository.getTestById(fixture.testId))!.title, 'Test');
      await tester.tap(find.widgetWithText(TextButton, 'Avbryt'));
      await _settleInput(tester);
      expect(find.text('Befintlig anteckning'), findsOneWidget);
      await tester.drag(
        find.byKey(const PageStorageKey('empty-test-info')),
        const Offset(0, 500),
      );
      await _settleInput(tester);
      await tester.tap(find.byTooltip('Redigera testnamn'));
      await _settleInput(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Anteckningar om testet'),
        '',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Spara'));
      await tester.tap(find.widgetWithText(FilledButton, 'Spara'));
      await _settleInput(tester);
      expect((await repository.getTestById(fixture.testId))!.notes, isNull);
      expect(fixture.location.checkCount, 0);
      await _unmount(tester);
    },
  );

  testWidgets('failed detail save retains the draft for retry', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    await fixture.database.customStatement(
      "CREATE TRIGGER fail_details BEFORE UPDATE ON stored_glide_test BEGIN SELECT RAISE(ABORT, 'save failure'); END;",
    );
    await tester.tap(find.byTooltip('Redigera testnamn'));
    await _settleInput(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Anteckningar om testet'),
      'Spara den här texten',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Spara'));
    await tester.tap(find.widgetWithText(FilledButton, 'Spara'));
    await _settleInput(tester);
    expect(
      find.text('Kunde inte spara. Texten finns kvar. Försök igen.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Spara den här texten'),
      findsOneWidget,
    );
    await fixture.database.customStatement('DROP TRIGGER fail_details;');
    await tester.tap(find.widgetWithText(FilledButton, 'Spara'));
    await _settleInput(tester);
    expect(
      (await GlideTestRepository(fixture.database).getTestById(fixture.testId))!
          .notes,
      'Spara den här texten',
    );
    await _unmount(tester);
  });

  testWidgets('notes can be saved with the keyboard on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final fixture = await _Fixture.create(runCount: 1);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    await tester.tap(find.widgetWithText(Tab, 'Testet'));
    await _settleInput(tester);
    await tester.tap(find.text('Lägg till anteckning'));
    await _settleInput(tester);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .focusNode
          .hasFocus,
      isTrue,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Anteckningar om testet'),
      'Kall nysnö, svag vind.',
    );
    await _settleInput(tester);
    await tester.dragUntilVisible(
      find.widgetWithText(FilledButton, 'Spara'),
      find.byKey(const PageStorageKey('test-info')),
      const Offset(0, -100),
    );
    await _settleInput(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Spara'));
    await _settleInput(tester);
    expect(
      (await GlideTestRepository(fixture.database).getTestById(fixture.testId))!
          .notes,
      'Kall nysnö, svag vind.',
    );
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('leaving a dirty test asks before discarding', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.open(tester, pushed: true);
    await tester.tap(find.byTooltip('Redigera testnamn'));
    await _settleInput(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Anteckningar om testet'),
      'Utkast',
    );
    await tester.binding.handlePopRoute();
    await _settleInput(tester);
    expect(find.text('Lämna utan att spara?'), findsOneWidget);
    await tester.tap(find.text('Fortsätt skriva'));
    await _settleInput(tester);
    expect(_viewModel(tester).hasUnsavedDetails, isTrue);
    await tester.binding.handlePopRoute();
    await _settleInput(tester);
    await tester.tap(find.text('Lämna'));
    await _settleInput(tester);
    expect(find.byType(AnalysisWorkspace), findsNothing);
    expect(
      (await GlideTestRepository(fixture.database).getTestById(fixture.testId))!
          .notes,
      isNull,
    );
    await _unmount(tester);
  });

  testWidgets(
    'sensor fusion switch updates the overview graph and can restore GPS alone',
    (tester) async {
      final fixture = await _Fixture.create(
        runCount: 1,
        withAcceleration: true,
      );
      addTearDown(fixture.dispose);
      await fixture.open(tester);
      final original = tester
          .widget<CompareGraph>(find.byType(CompareGraph))
          .lines
          .single
          .positionData;
      await tester.tap(find.byTooltip('Filtrera'));
      await _settleInput(tester);
      await tester.tap(find.text('Sensorfusion'));
      await _settleInput(tester);
      expect(_viewModel(tester).useSensorFusion, isTrue);
      final fused = tester
          .widget<CompareGraph>(find.byType(CompareGraph))
          .lines
          .single
          .positionData;
      expect(
        fused.map((point) => point.speed),
        isNot(original.map((point) => point.speed)),
      );
      expect(
        fused.last.distanceTraveled,
        isNot(original.last.distanceTraveled),
      );
      await tester.tap(find.text('Sensorfusion'));
      await _settleInput(tester);
      expect(_viewModel(tester).useSensorFusion, isFalse);
      final restored = tester
          .widget<CompareGraph>(find.byType(CompareGraph))
          .lines
          .single
          .positionData;
      expect(
        restored.map((point) => point.speed),
        original.map((point) => point.speed),
      );
      Navigator.of(tester.element(find.byType(AnalysisWorkspace))).pop();
      await _settleInput(tester);
      await _unmount(tester);
    },
  );

  testWidgets('release point handles a saved run without GPS samples', (
    tester,
  ) async {
    final fixture = await _Fixture.create(runCount: 1, gpsSampleCount: 0);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    await tester.tap(find.widgetWithText(Tab, 'Släppunkt'));
    await _settleInput(tester);
    expect(_viewModel(tester).releasePoint, 0);
    expect(
      find.text('Åken saknar användbara hastighetspunkter.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Analysera från punkten'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });
  testWidgets('an empty test shows the guide and keeps new run available', (
    tester,
  ) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.open(tester);

    expect(find.byType(TestInfoEditor), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(CompareGraph), findsNothing);
    expect(find.text('Så gör du ett glidtest'), findsOneWidget);
    expect(find.text('Gör flera åk med varje skidpar'), findsOneWidget);
    expect(find.text('Nytt åk'), findsOneWidget);
    expect(find.text('Lägg till anteckning'), findsOneWidget);
    expect(find.text('Anteckningar om testet'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Skidor i testet')).dy,
      lessThan(tester.getTopLeft(find.text('Lägg till anteckning')).dy),
    );
    expect(fixture.location.checkCount, 0);
    await _unmount(tester);
  });

  for (final runCount in [0, 1]) {
    testWidgets(
      'long notes can expand and edit the complete text with $runCount runs',
      (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = await _Fixture.create(runCount: runCount);
        addTearDown(fixture.dispose);
        const notes =
            'Kall nysnö.\n'
            'Svag sidvind.\n'
            'SP1: blå valla.\n'
            'SP2: grövre struktur.\n'
            'Gör fler åk innan skillnaden bedöms.';
        final repository = GlideTestRepository(fixture.database);
        await repository.updateDetails(
          fixture.testId,
          title: 'Test',
          notes: notes,
        );
        await fixture.open(tester);
        if (runCount > 0) {
          await tester.tap(find.widgetWithText(Tab, 'Testet'));
          await _settleInput(tester);
        }

        Future<void> revealAndTap(Finder target) async {
          await Scrollable.ensureVisible(tester.element(target), alignment: .5);
          await _settleInput(tester);
          await tester.tap(target);
          await _settleInput(tester);
        }

        await revealAndTap(find.text('Visa hela anteckningen'));
        expect(find.text('Visa mindre'), findsOneWidget);
        expect(tester.widget<Text>(find.text(notes)).maxLines, isNull);
        expect((await repository.getTestById(fixture.testId))!.notes, notes);

        await revealAndTap(find.text('Visa mindre'));
        await revealAndTap(find.text('Redigera'));
        final field = find.widgetWithText(
          TextFormField,
          'Anteckningar om testet',
        );
        expect(tester.widget<TextFormField>(field).controller!.text, notes);
        await tester.enterText(field, 'Kort anteckning');
        await revealAndTap(find.widgetWithText(FilledButton, 'Spara'));
        expect(find.text('Kort anteckning'), findsOneWidget);
        expect(find.text('Visa hela anteckningen'), findsNothing);
        expect(
          (await repository.getTestById(fixture.testId))!.notes,
          'Kort anteckning',
        );
        expect(fixture.location.checkCount, 0);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      },
    );
  }

  testWidgets('an empty example keeps its recording and edit restrictions', (
    tester,
  ) async {
    final fixture = await _Fixture.create(isExample: true);
    addTearDown(fixture.dispose);
    await fixture.open(tester);

    expect(find.byType(TestInfoEditor), findsOneWidget);
    expect(find.text('Nytt åk'), findsNothing);
    expect(find.byTooltip('Redigera testnamn'), findsNothing);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    await tester.tap(find.byTooltip('Fler alternativ'));
    await _settleInput(tester);
    expect(find.text('Redigera testinfo'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('tabs preserve selection and keep the graph at sixty percent', (
    tester,
  ) async {
    final fixture = await _Fixture.create(runCount: 2);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    final viewModel = _viewModel(tester);
    final workspace = tester.getRect(find.byType(AnalysisWorkspace));
    final graph = tester.getRect(find.byType(CompareGraph).first);
    expect(graph.top, workspace.top);
    expect(graph.height, closeTo(workspace.height * .6, .01));
    expect(find.text('2 av 2 åk · Enskilda åk'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtrera'));
    await _settleInput(tester);
    await tester.tap(find.text('Avmarkera alla'));
    await _settleInput(tester);
    Navigator.of(tester.element(find.byType(AnalysisWorkspace))).pop();
    await _settleInput(tester);

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TestInfoEditor), findsNothing);
    expect(
      find.text('Välj ett eller flera åk i kontrollpanelen'),
      findsOneWidget,
    );
    expect(find.text('0 av 2 åk · Enskilda åk'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Släppunkt'));
    await _settleInput(tester);
    expect(viewModel.activeAnalysisPage, AnalysisPage.releasePoint);
    expect(viewModel.currentSelectedTestRuns, isEmpty);
    expect(find.text('Ingen data vald'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Testet'));
    await _settleInput(tester);
    expect(find.text('Så gör du ett glidtest'), findsOneWidget);
    expect(viewModel.currentSelectedTestRuns, isEmpty);
    await tester.tap(find.widgetWithText(Tab, 'Översikt'));
    await _settleInput(tester);
    expect(find.text('0 av 2 åk · Enskilda åk'), findsOneWidget);
    expect(fixture.location.checkCount, 0);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      AnalysisPage.overview.index,
    );
    await _unmount(tester);
  });

  testWidgets('guide expansion and scrolling survive tab changes on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = await _Fixture.create(runCount: 1);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    await tester.tap(find.widgetWithText(Tab, 'Testet'));
    await _settleInput(tester);
    await tester.tap(find.text('Så gör du ett glidtest'));
    await _settleInput(tester);
    final details = find.byKey(const PageStorageKey('test-guide'));
    await tester.dragUntilVisible(
      find.text('Jämför åken'),
      details,
      const Offset(0, -150),
    );
    await _settleInput(tester);
    await tester.tap(find.text('Jämför åken'));
    await _settleInput(tester);
    await tester.drag(details, const Offset(0, -150));
    await _settleInput(tester);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: details, matching: find.byType(Scrollable)).first,
    );
    final offset = scrollable.position.pixels;
    expect(offset, greaterThan(0));
    _viewModel(tester).setCurrentAnalysisPage(AnalysisPage.overview);
    await _settleInput(tester);
    await tester.drag(find.byType(CompareGraph).first, const Offset(-200, 0));
    await _settleInput(tester);
    expect(_viewModel(tester).activeAnalysisPage, AnalysisPage.overview);
    await tester.tap(find.widgetWithText(Tab, 'Testet'));
    await _settleInput(tester);
    final restoredScrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('test-guide')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(restoredScrollable.position.pixels, closeTo(offset, 1));
    expect(find.text('Bedöm variationen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('drawer has settings without a guide link or method heading', (
    tester,
  ) async {
    final fixture = await _Fixture.create(runCount: 2);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    expect(find.text('GPS + sensorer'), findsNothing);
    expect(find.text('GPS'), findsNothing);
    await tester.tap(find.byTooltip('Filtrera'));
    await _settleInput(tester);
    expect(find.text('Hjälp med test och analys'), findsNothing);
    expect(find.text('Sensorfusion'), findsOneWidget);
    Navigator.of(tester.element(find.byType(AnalysisWorkspace))).pop();
    await _settleInput(tester);
    await _unmount(tester);
  });

  testWidgets('lower controls scroll with runs while graph stays fixed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = await _Fixture.create(runCount: 8);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    final graph = tester.getRect(find.byType(CompareGraph).first);
    final tabs = tester.getTopLeft(find.byType(TabBar));
    final panel = find.byType(NestedScrollView);
    await tester.drag(panel, const Offset(0, -220));
    await _settleInput(tester);
    expect(find.byType(TabBar), findsNothing);
    expect(tester.getRect(find.byType(CompareGraph).first), graph);
    await tester.drag(panel, const Offset(0, 500));
    await _settleInput(tester);
    expect(tester.getTopLeft(find.byType(TabBar)).dy, closeTo(tabs.dy, 1));
    await tester.tap(find.widgetWithText(Tab, 'Släppunkt'));
    await _settleInput(tester);
    expect(_viewModel(tester).activeAnalysisPage, AnalysisPage.releasePoint);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('volume only opens new run from the current unobstructed test', (
    tester,
  ) async {
    final fixture = await _Fixture.create(runCount: 1);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    final routeContext = tester.element(find.byType(AnalysisWorkspace));
    fixture.volume.emitShort(VolumeButton.down);
    fixture.volume.emitLong(VolumeButton.up);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);

    await tester.tap(find.byTooltip('Filtrera'));
    await _settleInput(tester);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    Navigator.of(routeContext).pop();
    await _settleInput(tester);

    await tester.tap(find.byTooltip('Fler alternativ'));
    await _settleInput(tester);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    await tester.tap(find.text('Radera glidtestet'));
    await _settleInput(tester);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    await tester.tap(find.text('Avbryt'));
    await _settleInput(tester);

    unawaited(
      Navigator.of(routeContext).push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      ),
    );
    await _settleInput(tester);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    Navigator.of(routeContext).pop();
    await _settleInput(tester);

    await tester.tap(find.widgetWithText(Tab, 'Testet'));
    await _settleInput(tester);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    await _settleInput(tester);
    expect(fixture.location.checkCount, 1);
    await _unmount(tester);
  });
}

CompareRunsViewModel _viewModel(WidgetTester tester) =>
    tester.element(find.byType(AnalysisWorkspace)).read<CompareRunsViewModel>();

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

class _Fixture {
  final AppDatabase database;
  final int testId;
  final _VolumeInput volume = _VolumeInput();
  final _LocationPlatform location = _LocationPlatform();
  late final GeolocatorPlatform previousLocationPlatform;

  _Fixture(this.database, this.testId) {
    previousLocationPlatform = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = location;
  }

  static Future<_Fixture> create({
    int runCount = 0,
    bool isExample = false,
    int gpsSampleCount = 7,
    bool withAcceleration = false,
  }) async {
    final database = AppDatabase(NativeDatabase.memory());
    final testId = await database
        .into(database.storedGlideTest)
        .insert(
          StoredGlideTestCompanion.insert(
            title: 'Test',
            isExample: drift.Value(isExample),
          ),
        );
    final skiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final startedAt = DateTime.utc(2026, 1, 1);
    for (var index = 0; index < runCount; index++) {
      await TestRunRepository(database).storeTestRun(
        TestRunCandidate(
          startedAt: startedAt,
          skiId: skiId,
          glideTestId: testId,
          elapsedSeconds: 5,
          gpsEvents: List.generate(
            gpsSampleCount,
            (second) => RawGpsEvent.fromPosition(
              Position(
                longitude: 18.06860 + second * .0001,
                latitude: 59.32930,
                timestamp: startedAt.add(Duration(seconds: second)),
                accuracy: 3,
                altitude: 0,
                altitudeAccuracy: 1,
                heading: 0,
                headingAccuracy: 1,
                speed: second == 0 || second == 6 ? 0 : 2,
                speedAccuracy: withAcceleration ? .01 : .1,
              ),
            ),
          ),
          accelerometerEvents: withAcceleration
              ? List.generate(
                  301,
                  (sample) => RawAccelerometerEvent(
                    x: 0,
                    y: .8,
                    z: 0,
                    timestamp: startedAt.add(
                      Duration(milliseconds: sample * 20),
                    ),
                  ),
                )
              : const [],
          gyroscopeEvents: const [],
          barometerEvents: const [],
          rotationVectorEvents: const [],
          sensorMetadata: const SensorRecordingMetadata(streams: {}),
        ),
      );
    }
    return _Fixture(database, testId);
  }

  Future<void> open(WidgetTester tester, {bool pushed = false}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GlideTestRepository>.value(
            value: GlideTestRepository(database),
          ),
          Provider<SkiRepository>.value(value: SkiRepository(database)),
          Provider<TestRunRepository>.value(value: TestRunRepository(database)),
          Provider<VolumeButtonInput>.value(value: volume),
          Provider<HandsFreeControlsFactory>(
            create: (_) => HandsFreeControlsFactory(
              platform: TargetPlatform.android,
              volumeInput: volume,
            ),
            dispose: (_, factory) => factory.dispose(),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [handsFreeRouteObserver],
          theme: AppTheme.darkTheme,
          home: pushed
              ? const Scaffold(body: Text('Testlista'))
              : GlideTestCompareScreen(glideTestId: testId),
        ),
      ),
    );
    await _settleInput(tester);
    if (pushed) {
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(
              MaterialPageRoute<void>(
                builder: (_) => GlideTestCompareScreen(glideTestId: testId),
              ),
            ),
      );
      await _settleInput(tester);
    }
  }

  Future<void> dispose() async {
    GeolocatorPlatform.instance = previousLocationPlatform;
    volume.dispose();
    await database.close();
  }
}

class _LocationPlatform extends GeolocatorPlatform {
  int checkCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async {
    checkCount++;
    return false;
  }
}

class _VolumeInput implements VolumeButtonInput {
  final _short = StreamController<VolumeButton>.broadcast(sync: true);
  final _long = StreamController<VolumeButton>.broadcast(sync: true);

  @override
  bool get supportsVolumeInput => true;
  @override
  Stream<VolumeButton> get shortPressStream => _short.stream;
  @override
  Stream<VolumeButton> get longPressStream => _long.stream;

  void emitShort(VolumeButton button) => _short.add(button);
  void emitLong(VolumeButton button) => _long.add(button);

  @override
  void dispose() {
    _short.close();
    _long.close();
  }
}

// Native input cancellation and activation finish asynchronously, outside the
// fake animation clock used by pumpAndSettle.
Future<void> _settleInput(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
