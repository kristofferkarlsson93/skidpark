import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:geolocator/geolocator.dart';

import '../../../common/database/database.dart';
import '../../../common/database/repository/test_run_repository.dart';
import '../test_runs/models/raw_accelerometer_event.dart';

class GlideTestImportService {
  GlideTestImportService(this._database);

  final AppDatabase _database;

  Future<int> importJson(
    String source, {
    required bool asExample,
    String titleSuffix = '',
    Future<void> Function()? beforeInsert,
    Future<void> Function(int testId)? afterInsert,
  }) async {
    final importedTest = _ImportedGlideTest.parse(source);

    return _database.transaction(() async {
      await beforeInsert?.call();

      final newSkiIdsByOldId = <int, int>{};
      for (final ski in importedTest.skis) {
        final newId = await _database
            .into(_database.storedSki)
            .insert(
              StoredSkiCompanion.insert(
                createdAt: drift.Value(importedTest.createdAt),
                name: ski.name,
                brandAndModel: drift.Value(ski.brandAndModel),
                technicalData: drift.Value(ski.technicalData),
                notes: drift.Value(ski.notes),
                isExample: drift.Value(asExample),
              ),
            );
        newSkiIdsByOldId[ski.oldId] = newId;
      }

      final testId = await _database
          .into(_database.storedGlideTest)
          .insert(
            StoredGlideTestCompanion.insert(
              createdAt: drift.Value(importedTest.createdAt),
              title: '${importedTest.title}$titleSuffix',
              notes: drift.Value(importedTest.notes),
              useSensorFusion: drift.Value(importedTest.useSensorFusion),
              isExample: drift.Value(asExample),
            ),
          );

      await _database.batch((batch) {
        batch.insertAll(_database.glideTestSki, [
          for (final (index, ski) in importedTest.skis.indexed)
            GlideTestSkiCompanion.insert(
              glideTestId: testId,
              skiId: newSkiIdsByOldId[ski.oldId]!,
              sortOrder: index,
            ),
        ]);

        batch.insertAll(_database.testRun, [
          for (final run in importedTest.runs)
            TestRunCompanion.insert(
              glideTestId: testId,
              skiId: newSkiIdsByOldId[run.oldSkiId]!,
              runNumber: drift.Value(run.runNumber),
              startedAt: run.startedAt,
              elapsedSeconds: run.elapsedSeconds,
              gpsData: TestRunRepository.encodeGpsPositions(run.gpsData),
              accelerometerData: TestRunRepository.encodeAccelEvents(
                run.accelerometerEvents,
              ),
            ),
        ]);
      });

      await afterInsert?.call(testId);
      return testId;
    });
  }
}

class _ImportedGlideTest {
  const _ImportedGlideTest({
    required this.title,
    required this.notes,
    required this.createdAt,
    required this.useSensorFusion,
    required this.skis,
    required this.runs,
  });

  final String title;
  final String? notes;
  final DateTime createdAt;
  final bool useSensorFusion;
  final List<_ImportedSki> skis;
  final List<_ImportedRun> runs;

  factory _ImportedGlideTest.parse(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, dynamic>) {
      throw const FormatException('Importfilen måste innehålla ett objekt.');
    }
    final testJson = root['glideTest'];
    final skisJson = root['skis'];
    final runsJson = root['runs'];
    if (testJson is! Map<String, dynamic> ||
        skisJson is! List<dynamic> ||
        runsJson is! List<dynamic>) {
      throw const FormatException('Importfilen saknar test, skidor eller åk.');
    }

    final skis = skisJson.map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('En skida har fel format.');
      }
      return _ImportedSki.fromJson(value);
    }).toList();
    if (skis.isEmpty) {
      throw const FormatException('Importfilen måste innehålla skidor.');
    }
    final knownSkiIds = skis.map((ski) => ski.oldId).toSet();

    final runs = runsJson.indexed.map((entry) {
      final (index, value) = entry;
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Ett åk har fel format.');
      }
      final run = _ImportedRun.fromJson(value, fallbackRunNumber: index + 1);
      if (!knownSkiIds.contains(run.oldSkiId)) {
        throw const FormatException('Ett åk hänvisar till en okänd skida.');
      }
      return run;
    }).toList();
    final runNumbers = runs.map((run) => run.runNumber).toSet();
    if (runNumbers.length != runs.length) {
      throw const FormatException('Åknummer måste vara unika inom testet.');
    }

    return _ImportedGlideTest(
      title: _requiredString(testJson, 'title'),
      notes: testJson['notes'] as String?,
      createdAt: DateTime.parse(_requiredString(testJson, 'createdAt')),
      useSensorFusion: testJson['useSensorFusion'] == true,
      skis: skis,
      runs: runs,
    );
  }
}

class _ImportedSki {
  const _ImportedSki({
    required this.oldId,
    required this.name,
    required this.brandAndModel,
    required this.technicalData,
    required this.notes,
  });

  final int oldId;
  final String name;
  final String? brandAndModel;
  final String? technicalData;
  final String? notes;

  factory _ImportedSki.fromJson(Map<String, dynamic> json) {
    return _ImportedSki(
      oldId: _requiredInt(json, 'id'),
      name: _requiredString(json, 'name'),
      brandAndModel: json['brandAndModel'] as String?,
      technicalData: json['technicalData'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class _ImportedRun {
  const _ImportedRun({
    required this.oldSkiId,
    required this.runNumber,
    required this.startedAt,
    required this.elapsedSeconds,
    required this.gpsData,
    required this.accelerometerEvents,
  });

  final int oldSkiId;
  final int runNumber;
  final DateTime startedAt;
  final int elapsedSeconds;
  final List<Position> gpsData;
  final List<RawAccelerometerEvent> accelerometerEvents;

  factory _ImportedRun.fromJson(
    Map<String, dynamic> json, {
    required int fallbackRunNumber,
  }) {
    final gpsJson = json['gpsData'];
    if (gpsJson is! List<dynamic>) {
      throw const FormatException('Ett åk saknar GPS-data.');
    }

    final accelerometerEvents = <RawAccelerometerEvent>[];
    final encodedAccelerometerData = json['accelerometerData'];
    if (encodedAccelerometerData is String &&
        encodedAccelerometerData.isNotEmpty) {
      final compressedBytes = base64Decode(encodedAccelerometerData);
      final decompressedBytes = GZipDecoder().decodeBytes(compressedBytes);
      final decoded = jsonDecode(utf8.decode(decompressedBytes));
      if (decoded is! List<dynamic>) {
        throw const FormatException('Accelerometerdata har fel format.');
      }
      accelerometerEvents.addAll(
        decoded.map((value) {
          if (value is! Map<String, dynamic>) {
            throw const FormatException(
              'En accelerometerpunkt har fel format.',
            );
          }
          return RawAccelerometerEvent.fromJson(value);
        }),
      );
    }

    return _ImportedRun(
      oldSkiId: _requiredInt(json, 'skiId'),
      runNumber: _optionalPositiveInt(
        json,
        'runNumber',
        fallback: fallbackRunNumber,
      ),
      startedAt: DateTime.parse(_requiredString(json, 'startedAt')),
      elapsedSeconds: _requiredInt(json, 'elapsedSeconds'),
      gpsData: gpsJson.map((value) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException('En GPS-punkt har fel format.');
        }
        return Position.fromMap(value);
      }).toList(),
      accelerometerEvents: accelerometerEvents,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Fältet $key saknas eller har fel format.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Fältet $key saknas eller har fel format.');
  }
  return value.toInt();
}

int _optionalPositiveInt(
  Map<String, dynamic> json,
  String key, {
  required int fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! num || value.toInt() != value || value <= 0) {
    throw FormatException('Fältet $key måste vara ett positivt heltal.');
  }
  return value.toInt();
}
