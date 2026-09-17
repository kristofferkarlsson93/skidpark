import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/import/glide_test_import_service.dart';

void main() {
  test('preserves explicit run numbers from version 2 exports', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final testId = await GlideTestImportService(database).importJson(
      jsonEncode({
        'version': 2,
        'glideTest': {
          'title': 'Importerat test',
          'createdAt': '2026-09-15T12:00:00.000Z',
          'useSensorFusion': false,
        },
        'skis': [
          {'id': 10, 'name': 'SP1'},
        ],
        'runs': [
          {
            'id': 20,
            'runNumber': 2,
            'skiId': 10,
            'startedAt': '2026-09-15T12:01:00.000Z',
            'elapsedSeconds': 10,
            'gpsData': <Object>[],
          },
          {
            'id': 21,
            'runNumber': 4,
            'skiId': 10,
            'startedAt': '2026-09-15T12:02:00.000Z',
            'elapsedSeconds': 10,
            'gpsData': <Object>[],
          },
        ],
      }),
      asExample: false,
    );

    final runs = await TestRunRepository(database)
        .streamByGlideTest(testId)
        .first;
    expect(runs.map((run) => run.runNumber), [2, 4]);
  });
}
