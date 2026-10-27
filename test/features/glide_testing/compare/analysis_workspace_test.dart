import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/common/services/volume_press_handler.dart';
import 'package:skidpark/features/glide_testing/compare/compare_runs_view_model.dart';
import 'package:skidpark/features/glide_testing/compare/models/analysis_page.dart';
import 'package:skidpark/features/glide_testing/compare/screens/glide_test_compare_screen.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/analysis_workspace.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/compare_graph.dart';
import 'package:skidpark/features/glide_testing/compare/widgets/glide_test_guide.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gps_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/sensor_recording_metadata.dart';
import 'package:skidpark/theme/app_theme.dart';

void main() {
  testWidgets('release point handles a saved run without GPS samples', (
    tester,
  ) async {
    final fixture = await _Fixture.create(runCount: 1, gpsSampleCount: 0);
    addTearDown(fixture.dispose);
    await fixture.open(tester);
    await tester.tap(find.widgetWithText(Tab, 'Släppunkt'));
    await tester.pumpAndSettle();
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

    expect(find.byType(GlideTestGuide), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(CompareGraph), findsNothing);
    expect(find.text('Så gör du ett glidtest'), findsOneWidget);
    expect(find.text('Gör flera åk med varje skidpar'), findsOneWidget);
    expect(find.text('Nytt åk'), findsOneWidget);
    expect(fixture.location.checkCount, 0);
    await _unmount(tester);
  });

  testWidgets('an empty example keeps its recording and edit restrictions', (
    tester,
  ) async {
    final fixture = await _Fixture.create(isExample: true);
    addTearDown(fixture.dispose);
    await fixture.open(tester);

    expect(find.byType(GlideTestGuide), findsOneWidget);
    expect(find.text('Nytt åk'), findsNothing);
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    await tester.tap(find.byTooltip('Fler alternativ'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avmarkera alla'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AnalysisWorkspace))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(GlideTestGuide), findsNothing);
    expect(
      find.text('Välj ett eller flera åk i kontrollpanelen'),
      findsOneWidget,
    );
    expect(find.text('0 av 2 åk · Enskilda åk'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Släppunkt'));
    await tester.pumpAndSettle();
    expect(viewModel.activeAnalysisPage, AnalysisPage.releasePoint);
    expect(viewModel.currentSelectedTestRuns, isEmpty);
    expect(find.text('Ingen data vald'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Guide'));
    await tester.pumpAndSettle();
    expect(find.text('Så gör du ett glidtest'), findsOneWidget);
    expect(viewModel.currentSelectedTestRuns, isEmpty);
    await tester.tap(find.widgetWithText(Tab, 'Översikt'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.widgetWithText(Tab, 'Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jämför åken'));
    await tester.pumpAndSettle();
    final details = find.byKey(const PageStorageKey('guide-details'));
    await tester.drag(details, const Offset(0, -150));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: details, matching: find.byType(Scrollable)).first,
    );
    final offset = scrollable.position.pixels;
    expect(offset, greaterThan(0));
    _viewModel(tester).setCurrentAnalysisPage(AnalysisPage.overview);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CompareGraph).first, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(_viewModel(tester).activeAnalysisPage, AnalysisPage.overview);
    await tester.tap(find.widgetWithText(Tab, 'Guide'));
    await tester.pumpAndSettle();
    final restoredScrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('guide-details')),
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
    await tester.pumpAndSettle();
    expect(find.text('Hjälp med test och analys'), findsNothing);
    expect(find.text('Sensorfusion'), findsOneWidget);
    Navigator.of(tester.element(find.byType(AnalysisWorkspace))).pop();
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    expect(tester.getRect(find.byType(CompareGraph).first), graph);
    await tester.drag(panel, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(TabBar)).dy, closeTo(tabs.dy, 1));
    await tester.tap(find.widgetWithText(Tab, 'Släppunkt'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    Navigator.of(routeContext).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fler alternativ'));
    await tester.pumpAndSettle();
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    await tester.tap(find.text('Radera glidtestet'));
    await tester.pumpAndSettle();
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    await tester.tap(find.text('Avbryt'));
    await tester.pumpAndSettle();

    unawaited(
      Navigator.of(routeContext).push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fixture.location.checkCount, 0);
    Navigator.of(routeContext).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'Guide'));
    await tester.pumpAndSettle();
    fixture.volume.emitLong(VolumeButton.down);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
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
                speedAccuracy: .1,
              ),
            ),
          ),
          accelerometerEvents: const [],
          gyroscopeEvents: const [],
          barometerEvents: const [],
          rotationVectorEvents: const [],
          sensorMetadata: const SensorRecordingMetadata(streams: {}),
        ),
      );
    }
    return _Fixture(database, testId);
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GlideTestRepository>.value(
            value: GlideTestRepository(database),
          ),
          Provider<TestRunRepository>.value(value: TestRunRepository(database)),
          Provider<VolumeButtonInput>.value(value: volume),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: GlideTestCompareScreen(glideTestId: testId),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
