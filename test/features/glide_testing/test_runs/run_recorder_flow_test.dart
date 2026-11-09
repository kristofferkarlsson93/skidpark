import 'dart:async';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/common/services/volume_press_handler.dart';
import 'package:skidpark/common/input/hands_free_controls_factory.dart';
import 'package:skidpark/common/input/hands_free_input.dart';
import 'package:skidpark/common/input/hands_free_controller.dart';
import 'package:skidpark/common/input/android/android_volume_hands_free_input.dart';
import 'package:skidpark/common/shared_widgets/hands_free_input_handler.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/data_recorder.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/screen/run_recording_screen.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/start_test_run.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/recording_start_countdown.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/record_test_run.dart';
import 'package:skidpark/features/glide_testing/test_runs/viewModel/run_recorder_view_model.dart';

void main() {
  test(
    'unsupported volume input reports no support and emits no events',
    () async {
      final volumeInput = UnsupportedVolumeButtonInput();

      expect(volumeInput.supportsVolumeInput, isFalse);
      expect(await volumeInput.shortPressStream.isEmpty, isTrue);
      expect(await volumeInput.longPressStream.isEmpty, isTrue);
      volumeInput.dispose();
    },
  );

  test('navigation commands select, start, and save exactly one run', () async {
    final saveCompleter = Completer<int>();
    final fixture = await _RecorderFixture.create(
      onStore: (_) => saveCompleter.future,
    );
    addTearDown(fixture.dispose);

    fixture.viewModel.handleHandsFreeAction(HandsFreeAction.previous);
    expect(fixture.viewModel.markedSkiIndex, 1);

    fixture.viewModel.handleHandsFreeAction(HandsFreeAction.next);
    expect(fixture.viewModel.markedSkiIndex, 0);

    fixture.viewModel.handleHandsFreeAction(HandsFreeAction.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 550));

    expect(fixture.viewModel.viewState, RunViewState.recordRun);
    expect(fixture.viewModel.selectedSki?.name, 'SP1');
    expect(fixture.dataRecorder.startCount, 1);

    fixture.viewModel.handleHandsFreeAction(HandsFreeAction.stopAndSave);
    fixture.viewModel.handleHandsFreeAction(HandsFreeAction.stopAndSave);

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
    'unsupported volume input keeps ski selection and recording screen controls usable',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final skiRepository = SkiRepository(database);
      final glideTestRepository = GlideTestRepository(database);
      final testRunRepository = TestRunRepository(database);
      final volumeInput = UnsupportedVolumeButtonInput();
      final dataRecorder = _FakeDataRecorder();
      addTearDown(() async {
        volumeInput.dispose();
        dataRecorder.dispose();
        await database.close();
      });

      final skiId = await database
          .into(database.storedSki)
          .insert(StoredSkiCompanion.insert(name: 'SP1'));
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
            Provider<HandsFreeControlsFactory>(
              create: (_) => HandsFreeControlsFactory(
                platform: TargetPlatform.android,
                volumeInput: volumeInput,
              ),
              dispose: (_, factory) => factory.dispose(),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [handsFreeRouteObserver],
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
      await _settleInput(tester);
      expect(find.text('Välj skida för åket'), findsOneWidget);
      expect(find.textContaining('VOLYM'), findsNothing);

      await tester.tap(find.text('SP1'));
      await tester.pump();
      await tester.tap(find.text('STARTA TEST'));
      await tester.pump(const Duration(milliseconds: 350));
      await _settleInput(tester);

      expect(find.text('Samlar in data...'), findsOneWidget);
      expect(find.textContaining('VOLYM'), findsNothing);
      expect(find.text('SPARA'), findsOneWidget);
      expect(dataRecorder.startCount, 1);

      await tester.tap(find.text('SPARA'));
      await _settleInput(tester);

      expect(find.text('Öppna inspelning'), findsOneWidget);
      expect(await database.select(database.testRun).get(), hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

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
            Provider<HandsFreeControlsFactory>(
              create: (_) => HandsFreeControlsFactory(
                platform: TargetPlatform.android,
                volumeInput: volumeInput,
              ),
              dispose: (_, factory) => factory.dispose(),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [handsFreeRouteObserver],
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
      await _settleInput(tester);
      expect(find.text('Välj skida för åket'), findsOneWidget);

      await tester.tap(find.text('Välj annan skida'));
      await _settleInput(tester);
      expect(find.text('Lägg till ny skida'), findsOneWidget);
      await tester.tap(find.text('Lägg till ny skida'));
      await _settleInput(tester);
      expect(find.text('Skidans namn'), findsOneWidget);
      expect(find.text('STARTA TEST'), findsNothing);

      await tester.tap(find.text('Reserv'));
      await tester.pump();
      expect(find.text('Skidans namn'), findsOneWidget);
      expect(find.text('Välj en annan skida'), findsOneWidget);

      volumeInput.emitShort(VolumeButton.down);
      volumeInput.emitLong(VolumeButton.down);
      await _settleInput(tester);
      await tester.pump(const Duration(milliseconds: 550));
      await _settleInput(tester);
      expect(find.text('Skidans namn'), findsOneWidget);
      expect(dataRecorder.startCount, 0);

      await tester.binding.handlePopRoute();
      await _settleInput(tester);
      expect(find.text('Lägg till ny skida'), findsOneWidget);
      expect(find.text('STARTA TEST'), findsOneWidget);
      expect(await skiRepository.getActiveSkis(), hasLength(2));

      volumeInput.emitShort(VolumeButton.down);
      await tester.pump();

      await tester.tap(find.text('Lägg till ny skida'));
      await _settleInput(tester);
      await tester.tap(find.text('Avbryt'));
      await _settleInput(tester);
      expect(await skiRepository.getActiveSkis(), hasLength(2));

      await tester.tap(find.text('Lägg till ny skida'));
      await _settleInput(tester);
      await tester.enterText(find.byType(TextField), 'SP2');
      await tester.tap(find.text('Lägg till och välj'));
      await _settleInput(tester);

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
      await _settleInput(tester);
      expect(find.text('Öppna inspelning'), findsOneWidget);

      await tester.tap(find.text('Öppna inspelning'));
      await _settleInput(tester);
      volumeInput.emitShort(VolumeButton.down);
      await tester.pump();
      volumeInput.emitLong(VolumeButton.down);
      await _settleInput(tester);
      await tester.pump(const Duration(milliseconds: 550));
      await _settleInput(tester);
      expect(find.text('Samlar in data...'), findsOneWidget);

      volumeInput.emitShort(VolumeButton.down);
      await _settleInput(tester);

      expect(find.text('Öppna inspelning'), findsOneWidget);
      expect(await database.select(database.testRun).get(), hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
  testWidgets(
    'iPhone gestures start the chosen ski once after countdown with motion stopped',
    (tester) async {
      final fixture = await _IosRecordingFixture.create();
      addTearDown(() => fixture.dispose(tester));
      await fixture.open(tester);
      expect(fixture.model(tester).availableSkis.first.name, 'SP2');
      expect(fixture.model(tester).markedSkiIndex, 0);
      await fixture.hold(600);
      await fixture.flick();
      await _settleInput(tester);
      expect(fixture.model(tester).markedSkiIndex, 1);
      await fixture.shake();
      await _settleInput(tester);
      expect(fixture.model(tester).selectedSki?.name, 'SP1');
      expect(fixture.model(tester).isStarting, isTrue);
      expect(find.byType(RecordingStartCountdown), findsOneWidget);
      expect(
        tester.getSize(find.byType(RecordingStartCountdown)),
        tester.getSize(find.byType(Scaffold).last),
      );
      expect(fixture.listening, isFalse);
      fixture.model(tester).handleHandsFreeAction(HandsFreeAction.next);
      await tester.pump(const Duration(seconds: 1));
      expect(fixture.dataRecorder.startCount, 0);
      await tester.pump(const Duration(seconds: 1));
      await _settleInput(tester);
      expect(fixture.dataRecorder.startCount, 1);
      expect(find.byType(RecordingStartCountdown), findsNothing);
      expect(fixture.listening, isFalse);
      expect(fixture.model(tester).selectedSki?.name, 'SP1');
      await tester.runAsync(() => fixture.model(tester).stopAndSaveRun());

      await _settleInput(tester);
      final runs = await tester.runAsync(
        () => fixture.database.select(fixture.database.testRun).get(),
      );
      expect(runs, hasLength(1));
      expect(runs!.single.skiId, fixture.firstSkiId);
      expect(find.text('Öppna inspelning'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settleInput(tester);
      await fixture.dispose(tester);
    },
  );

  testWidgets(
    'iPhone manual start is immediate and keeps the screen awake only on the recording route',
    (tester) async {
      final fixture = await _IosRecordingFixture.create();
      addTearDown(() => fixture.dispose(tester));
      await fixture.open(tester);
      expect(fixture.keepAwake, isTrue);
      await tester.tap(find.text('STARTA TEST'));
      await _settleInput(tester);
      expect(fixture.dataRecorder.startCount, 1);
      expect(find.byType(RecordingStartCountdown), findsNothing);
      expect(fixture.keepAwake, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _settleInput(tester);
      expect(fixture.keepAwake, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _settleInput(tester);
      expect(fixture.keepAwake, isTrue);
      await tester.binding.handlePopRoute();
      await _settleInput(tester);
      expect(fixture.keepAwake, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settleInput(tester);
      await fixture.dispose(tester);
    },
  );

  testWidgets(
    'iPhone overview accepts the first shake after aborting and saving a run',
    (tester) async {
      final fixture = await _IosRecordingFixture.create();
      addTearDown(() => fixture.dispose(tester));
      await fixture.open(tester, overviewInput: true);
      // Open by shake, then abort selection and return to the same owner.
      await tester.binding.handlePopRoute();
      await _settleInput(tester);
      await fixture.hold(600);
      await fixture.shake();
      await _settleInput(tester);
      expect(find.byType(StartTestRunWidget), findsOneWidget);
      await fixture.hold(260);
      await fixture.flick();
      await _settleInput(tester);
      expect(fixture.model(tester).markedSkiIndex, 1);
      await tester.binding.handlePopRoute();
      await _settleInput(tester);
      fixture.time += 5;
      await fixture.shake();
      await _settleInput(tester);
      expect(find.byType(StartTestRunWidget), findsOneWidget);
      await fixture.hold(1400);
      await fixture.shake();
      await _settleInput(tester);
      await tester.pump(const Duration(seconds: 2));
      await _settleInput(tester);
      expect(fixture.dataRecorder.startCount, 1);
      fixture.time += 30;
      await tester.runAsync(() => fixture.model(tester).stopAndSaveRun());
      await _settleInput(tester);
      expect(find.byType(StartTestRunWidget), findsNothing);
      expect(fixture.listening, isTrue);
      expect(fixture.keepAwake, isFalse);
      await fixture.shake();
      await _settleInput(tester);
      expect(find.byType(StartTestRunWidget), findsOneWidget);
      expect(fixture.keepAwake, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settleInput(tester);
      await fixture.dispose(tester);
    },
  );

  testWidgets(
    'iPhone countdown cancels on lock and back without auto-starting',
    (tester) async {
      final fixture = await _IosRecordingFixture.create();
      addTearDown(() => fixture.dispose(tester));
      await fixture.open(tester);
      await fixture.hold(600);
      await fixture.shake();
      await _settleInput(tester);
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 3));
      expect(fixture.dataRecorder.startCount, 0);
      expect(fixture.model(tester).isStarting, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _settleInput(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(fixture.dataRecorder.startCount, 0);
      await fixture.hold(1400);
      await fixture.shake();
      await _settleInput(tester);
      expect(fixture.model(tester).isStarting, isTrue);
      await tester.binding.handlePopRoute();
      await _settleInput(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(fixture.dataRecorder.startCount, 0);
      expect(fixture.listening, isFalse);
      expect(
        await fixture.database.select(fixture.database.testRun).get(),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _settleInput(tester);
      await fixture.dispose(tester);
    },
  );
}

class _RecorderFixture {
  final AppDatabase database;
  final _TestRunRepository repository;
  final _FakeVolumeButtonInput volumeInput;
  final _FakeDataRecorder dataRecorder;
  final RunRecorderViewModel viewModel;
  final HandsFreeController controls;
  final List<StoredSkiData> skis;

  _RecorderFixture({
    required this.database,
    required this.repository,
    required this.volumeInput,
    required this.dataRecorder,
    required this.viewModel,
    required this.controls,
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
    final controls = HandsFreeController(
      input: AndroidVolumeHandsFreeInput(volumeInput),
      feedback: _SilentFeedback(),
    );
    final viewModel = RunRecorderViewModel(
      testRunRepository: repository,
      skiRepository: skiRepository,
      glideTestRepository: glideTestRepository,
      controls: controls,
      dataRecorder: dataRecorder,
      glideTestId: testId,
    );

    viewModel.setRouteVisible(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(viewModel.availableSkis, hasLength(2));

    return _RecorderFixture(
      database: database,
      repository: repository,
      volumeInput: volumeInput,
      dataRecorder: dataRecorder,
      viewModel: viewModel,
      controls: controls,
      skis: skis,
    );
  }

  Future<void> dispose() async {
    viewModel.dispose();
    await controls.dispose();
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
  bool get supportsVolumeInput => true;

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

class _SilentFeedback implements HandsFreeFeedback {
  @override
  Future<void> announce(String message) async {}
  @override
  Future<void> stop() async {}
}

// Native input cancellation and activation finish asynchronously, outside the
// fake animation clock used by pumpAndSettle.
Future<void> _settleInput(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

class _IosRecordingFixture {
  _IosRecordingFixture(this.database, this.testId, this.firstSkiId)
    : controls = HandsFreeControlsFactory(
        platform: TargetPlatform.iOS,
        volumeInput: UnsupportedVolumeButtonInput(),
      );
  final AppDatabase database;
  final int testId;
  final int firstSkiId;
  final HandsFreeControlsFactory controls;
  final dataRecorder = _FakeDataRecorder();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  bool listening = false;
  bool keepAwake = false;
  bool _disposed = false;
  double time = 0;
  static const motionChannel = 'com.skidpark.app/ios_hands_free_motion';
  static const feedbackChannel = 'com.skidpark.app/ios_hands_free_feedback';
  static const displayChannel = 'com.skidpark.app/ios_recording_display';

  static Future<_IosRecordingFixture> create() async {
    final database = AppDatabase(NativeDatabase.memory());
    final first = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final second = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP2'));
    final test = await database
        .into(database.storedGlideTest)
        .insert(StoredGlideTestCompanion.insert(title: 'Test'));
    await GlideTestRepository(database)
        .replaceSkisForTest(test, [second, first]);
    return _IosRecordingFixture(database, test, first);
  }

  RunRecorderViewModel model(WidgetTester tester) =>
      Provider.of<RunRecorderViewModel>(
        tester.element(
          find
                  .byType(StartTestRunWidget, skipOffstage: false)
                  .evaluate()
                  .isNotEmpty
              ? find.byType(StartTestRunWidget, skipOffstage: false)
              : find.byType(RecordTestRun),
        ),
        listen: false,
      );

  Future<void> open(WidgetTester tester, {bool overviewInput = false}) async {
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(const MethodChannel(motionChannel), (
      call,
    ) async {
      if (call.method == 'listen') listening = true;
      if (call.method == 'cancel') listening = false;
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel(feedbackChannel),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(const MethodChannel(displayChannel), (
      call,
    ) async {
      keepAwake = call.arguments as bool;
      return null;
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SkiRepository>.value(value: SkiRepository(database)),
          Provider<GlideTestRepository>.value(
            value: GlideTestRepository(database),
          ),
          Provider<TestRunRepository>.value(value: TestRunRepository(database)),
          Provider<HandsFreeControlsFactory>.value(value: controls),
        ],
        child: MaterialApp(
          navigatorObservers: [handsFreeRouteObserver],
          home: Builder(
            builder: (context) {
              void openRecording() => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => RunRecorderScreen(
                    glideTestId: testId,
                    dataRecorder: dataRecorder,
                  ),
                ),
              );
              return HandsFreeInputHandler(
                controller: controls.controller,
                stage: HandsFreeStage.overview,
                enabled: overviewInput,
                onAction: (action) {
                  if (action == HandsFreeAction.confirm) openRecording();
                },
                onError: fail,
                child: Scaffold(
                  body: FilledButton(
                    onPressed: openRecording,
                    child: const Text('Öppna inspelning'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öppna inspelning'));
    await _settleInput(tester);
  }

  Future<void> hold(
    int milliseconds, {
    double degrees = 0,
    double acceleration = 0,
    double rotationRate = 0,
  }) async {
    for (var tick = 0; tick < milliseconds; tick += 20) {
      time += 0.02;
      if (!listening) continue;
      await messenger.handlePlatformMessage(
        motionChannel,
        const StandardMethodCodec().encodeSuccessEnvelope([
          time,
          math.sin(degrees * math.pi / 180),
          acceleration,
          0.0,
          0.0,
          rotationRate,
        ]),
        (_) {},
      );
    }
  }

  Future<void> flick() async {
    for (final degrees in [4.5, 9.0, 13.5, 18.0, 13.5, 9.0, 4.5, 0.0]) {
      await hold(20, degrees: degrees, rotationRate: 3.9, acceleration: 0.15);
    }
    await hold(40);
  }

  Future<void> shake() async {
    for (final direction in [1.0, -1.0]) {
      await hold(80, acceleration: direction);
    }
    // The third impulse confirms and closes the Dart event stream. Do not
    // inject further fake native messages while cancellation is being awaited.
    await hold(20, acceleration: 1);
  }

  Future<void> dispose(WidgetTester tester) async {
    if (_disposed) return;
    _disposed = true;
    final stopped = controls.dispose();
    await _settleInput(tester);
    await stopped;
    dataRecorder.dispose();
    await database.close();
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel(motionChannel),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel(feedbackChannel),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel(displayChannel),
      null,
    );
  }
}
