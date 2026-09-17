import 'package:flutter/services.dart';

import '../../../common/database/database.dart';
import '../import/glide_test_import_service.dart';

class ExampleDataInstaller {
  ExampleDataInstaller(
    this._database,
    this._importService, {
    Future<String> Function()? loadAsset,
  }) : _loadAsset =
           loadAsset ??
           (() => rootBundle.loadString('assets/example_data/glide_test.json'));

  static const settingKey = 'example_data_v1_installed';

  final AppDatabase _database;
  final GlideTestImportService _importService;
  final Future<String> Function() _loadAsset;
  Future<void> _operationQueue = Future<void>.value();

  Future<void> ensureInstalled() {
    return _enqueue(_ensureInstalled);
  }

  Future<void> _ensureInstalled() async {
    final setting = await (_database.select(
      _database.appSetting,
    )..where((row) => row.key.equals(settingKey))).getSingleOrNull();
    if (setting?.value == 'true') return;

    final source = await _loadAsset();
    await _importService.importJson(
      source,
      asExample: true,
      afterInsert: (_) => _markInstalled(),
    );
  }

  Future<void> reset() {
    return _enqueue(_reset);
  }

  Future<void> _reset() async {
    final source = await _loadAsset();
    await _importService.importJson(
      source,
      asExample: true,
      beforeInsert: _deleteExistingExampleData,
      afterInsert: (_) => _markInstalled(),
    );
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _deleteExistingExampleData() async {
    await (_database.delete(
      _database.storedGlideTest,
    )..where((test) => test.isExample.equals(true))).go();
    await (_database.delete(
      _database.storedSki,
    )..where((ski) => ski.isExample.equals(true))).go();
  }

  Future<void> _markInstalled() async {
    await _database
        .into(_database.appSetting)
        .insertOnConflictUpdate(
          AppSettingCompanion.insert(key: settingKey, value: 'true'),
        );
  }
}
