import 'dart:async';

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
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/screen/run_recording_screen.dart';
import 'package:skidpark/features/glide_testing/test_runs/viewModel/run_recorder_view_model.dart';

void main() {
  test('volume buttons navigate, start, and save exactly one run', () async {
    final saveCompleter = Completer<int>();
    final fixture = await _RecorderFixture.create(
      onStore: (_) => saveCompleter.future,
    );
    addTearDown(fixture.dispose);

    fixture.volumeInput.emitShort(VolumeButton.up);
    expect(fixture.viewModel.markedSkiIndex, 1);

    fixture.volumeInput.emitShort(VolumeButton.down);
    expect(fixture.viewModel.markedSkiIndex, 0);

    fixture.volumeInput.emitLong(VolumeButton.down);
    await Future<void>.delayed(const Duration(milliseconds: 550));

    expect(fixture.viewModel.viewState, RunViewState.recordRun);
    expect(fixture.viewModel.selectedSki?.name, 'SP1');
    expect(fixture.dataRecorder.startCount, 1);

    fixture.volumeInput.emitShort(VolumeButton.down);
    fixture.volumeInput.emitShort(VolumeButton.down);

    expect(fixture.repository.storeCallCount, 1);
    expect(fixture.viewModel.saveState, RunSaveState.saving);

    saveCompleter.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(fixture.viewModel.saveState, RunSaveState.saved);
    expect(fixture.dataRecorder.resetCount, 1);
  });

  test('failed save retains the run and can be retried', () async {
    var shouldFail = true;
    final fixture = await _RecorderFixture.create(
      onStore: (_) async {
        if (shouldFail) throw StateError('Database unavailable');
        return 1;
      },
    );
    addTearDown(fixture.dispose);

    await fixture.viewModel.selectSki(fixture.skis.first);
    fixture.viewModel.startRun();
    await fixture.viewModel.stopAndSaveRun();

    expect(fixture.viewModel.saveState, RunSaveState.failed);
    expect(fixture.dataRecorder.hasRunData, isTrue);
    expect(fixture.dataRecorder.resetCount, 0);

    shouldFail = false;
    await fixture.viewModel.stopAndSaveRun();

    expect(fixture.viewModel.saveState, RunSaveState.saved);
    expect(fixture.repository.storeCallCount, 2);
    expect(fixture.dataRecorder.resetCount, 1);
  });

  testWidgets(
    'new ski can be added before cancel and volume-save still closes route',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final skiRepository = SkiRepository(database);
      final glideTestRepository = GlideTestRepository(database);
      final testRunRepository = TestRunRepository(database);
      final volumeInput = _FakeVolumeButtonInput();
      final dataRecorder = _FakeDataRecorder();
      addTearDown(() async {
        volumeInput.dispose();
        dataRecorder.dispose();
        await database.close();
      });

      final skiId = await database
          .into(database.storedSki)
          .insert(StoredSkiCompanion.insert(name: 'SP1'));
      await database
          .into(database.storedSki)
          .insert(StoredSkiCompanion.insert(name: 'Reserv'));
      final testId = await database
          .into(database.storedGlideTest)
          .insert(StoredGlideTestCompanion.insert(title: 'Test'));
      await glideTestRepository.addSkiToTest(testId, skiId);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SkiRepository>.value(value: skiRepository),
            Provider<GlideTestRepository>.value(value: glideTestRepository),
            Provider<TestRunRepository>.value(value: testRunRepository),
            Provider<VolumeButtonInput>.value(value: volumeInput),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RunRecorderScreen(
                        glideTestId: testId,
                        dataRecorder: dataRecorder,
                      ),
                    ),
                  ),
                  child: const Text('Öppna inspelning'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Öppna inspelning'));
      await tester.pumpAndSettle();
      expect(find.text('Välj skida för åket'), findsOneWidget);

      await tester.tap(find.text('Välj annan skida'));
      await tester.pumpAndSettle();
      expect(find.text('Lägg till ny skida'), findsOneWidget);
      await tester.tap(find.text('Lägg till ny skida'));
      await tester.pumpAndSettle();
      expect(find.text('Skidans namn'), findsOneWidget);
      expect(find.text('STARTA TEST'), findsNothing);

      await tester.tap(find.text('Reserv'));
      await tester.pump();
      expect(find.text('Skidans namn'), findsOneWidget);
      expect(find.text('Välj en annan skida'), findsOneWidget);

      volumeInput.emitShort(VolumeButton.down);
      volumeInput.emitLong(VolumeButton.down);
      await tester.pump(const Duration(milliseconds: 550));
      expect(find.text('Skidans namn'), findsOneWidget);
      expect(dataRecorder.startCount, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Lägg till ny skida'), findsOneWidget);
      expect(find.text('STARTA TEST'), findsOneWidget);
      expect(await skiRepository.getActiveSkis(), hasLength(2));

      volumeInput.emitShort(VolumeButton.down);
      await tester.pump();

      await tester.tap(find.text('Lägg till ny skida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avbryt'));
      await tester.pumpAndSettle();
      expect(await skiRepository.getActiveSkis(), hasLength(2));

      await tester.tap(find.text('Lägg till ny skida'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'SP2');
      await tester.tap(find.text('Lägg till och välj'));
      await tester.pumpAndSettle();

      final recorderViewModel = Provider.of<RunRecorderViewModel>(
        tester.element(find.text('Välj skida för åket')),
        listen: false,
      );
      expect(recorderViewModel.selectedSki?.name, 'SP2');
      expect(await skiRepository.getActiveSkis(), hasLength(3));
      expect(await glideTestRepository.getSkiIdsForTest(testId), hasLength(2));

      volumeInput.emitShort(VolumeButton.down);
      await tester.pump();
      expect(recorderViewModel.selectedSki, isNull);
      expect(recorderViewModel.markedSkiIndex, 0);

      await tester.tap(find.text('Avbryt'));
      await tester.pumpAndSettle();
      expect(find.text('Öppna inspelning'), findsOneWidget);

      await tester.tap(find.text('Öppna inspelning'));
      await tester.pumpAndSettle();
      volumeInput.emitShort(VolumeButton.down);
      await tester.pump();
      volumeInput.emitLong(VolumeButton.down);
      await tester.pump(const Duration(milliseconds: 550));
      expect(find.text('Samlar in data...'), findsOneWidget);

      volumeInput.emitShort(VolumeButton.down);
      await tester.pumpAndSettle();

      expect(find.text('Öppna inspelning'), findsOneWidget);
      expect(await database.select(database.testRun).get(), hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}

class _RecorderFixture {
  final AppDatabase database;
  final _TestRunRepository repository;
  final _FakeVolumeButtonInput volumeInput;
  final _FakeDataRecorder dataRecorder;
  final RunRecorderViewModel viewModel;
  final List<StoredSkiData> skis;

  _RecorderFixture({
    required this.database,
    required this.repository,
    required this.volumeInput,
    required this.dataRecorder,
    required this.viewModel,
    required this.skis,
  });

  static Future<_RecorderFixture> create({
    required Future<int> Function(TestRunCandidate candidate) onStore,
  }) async {
    final database = AppDatabase(NativeDatabase.memory());
    final skiRepository = SkiRepository(database);
    final glideTestRepository = GlideTestRepository(database);
    final testId = await database
        .into(database.storedGlideTest)
        .insert(StoredGlideTestCompanion.insert(title: 'Test'));
    final skiIds = <int>[];
    for (final name in ['SP1', 'SP2']) {
      skiIds.add(
        await database
            .into(database.storedSki)
            .insert(StoredSkiCompanion.insert(name: name)),
      );
    }
    await glideTestRepository.replaceSkisForTest(testId, skiIds);
    final skis = await skiRepository.getActiveSkis();
    final repository = _TestRunRepository(database, onStore);
    final volumeInput = _FakeVolumeButtonInput();
    final dataRecorder = _FakeDataRecorder();
    final viewModel = RunRecorderViewModel(
      testRunRepository: repository,
      skiRepository: skiRepository,
      glideTestRepository: glideTestRepository,
      volumeButtonInput: volumeInput,
      dataRecorder: dataRecorder,
      glideTestId: testId,
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(viewModel.availableSkis, hasLength(2));

    return _RecorderFixture(
      database: database,
      repository: repository,
      volumeInput: volumeInput,
      dataRecorder: dataRecorder,
      viewModel: viewModel,
      skis: skis,
    );
  }

  Future<void> dispose() async {
    viewModel.dispose();
    volumeInput.dispose();
    dataRecorder.dispose();
    await database.close();
  }
}

class _TestRunRepository extends TestRunRepository {
  final Future<int> Function(TestRunCandidate candidate) _onStore;
  int storeCallCount = 0;

  _TestRunRepository(super.database, this._onStore);

  @override
  Future<int> storeTestRun(TestRunCandidate testRunCandidate) {
    storeCallCount++;
    return _onStore(testRunCandidate);
  }
}

class _FakeVolumeButtonInput implements VolumeButtonInput {
  final _shortPressController = StreamController<VolumeButton>.broadcast(
    sync: true,
  );
  final _longPressController = StreamController<VolumeButton>.broadcast(
    sync: true,
  );

  @override
  Stream<VolumeButton> get shortPressStream => _shortPressController.stream;

  @override
  Stream<VolumeButton> get longPressStream => _longPressController.stream;

  void emitShort(VolumeButton button) => _shortPressController.add(button);

  void emitLong(VolumeButton button) => _longPressController.add(button);

  @override
  void dispose() {
    _shortPressController.close();
    _longPressController.close();
  }
}

class _FakeDataRecorder extends DataRecorder {
  bool hasRunData = false;
  int startCount = 0;
  int resetCount = 0;

  @override
  List<Position> get recordedPositions => const [];

  @override
  List<RawAccelerometerEvent> get recordedAccelerometerEvents => const [];

  @override
  int get elapsedSeconds => 4;

  @override
  void startRecording() {
    startCount++;
    hasRunData = true;
  }

  @override
  void stopRecording() {}

  @override
  void resetForNewRun() {
    resetCount++;
    hasRunData = false;
  }

  @override
  Future<void> close() async {}
}
