import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/ski_repository.dart';
import '../../../../common/database/repository/test_run_repository.dart';
import '../../../ski_management/models/ski.dart';
import '../../models/glide_test_candidate.dart';
import '../../models/test_run_candidate.dart';
import '../../test_runs/models/raw_accelerometer_event.dart';
import '../../test_runs/models/raw_barometer_event.dart';

class DevImportDialog extends StatefulWidget {
  const DevImportDialog({super.key});

  @override
  State<DevImportDialog> createState() => _DevImportDialogState();
}

class _DevImportDialogState extends State<DevImportDialog> {
  bool _isLoading = false;

  Future<void> _pickAndImportFile() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isLoading = false);
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      if (!mounted) return;

      final skiRepo = context.read<SkiRepository>();
      final testRepo = context.read<GlideTestRepository>();
      final runRepo = context.read<TestRunRepository>();

      Map<int, int> skiIdMap = {};
      final List<dynamic> jsonSkis = jsonData['skis'] ?? [];

      for (var skiData in jsonSkis) {
        final oldId = skiData['id'] as int;

        final candidate = SkiCandidate(
          name: skiData['name'] ?? 'Okänd skida',
          brandAndModel: skiData['brandAndModel'],
          technicalData: skiData['technicalData'],
          notes: skiData['notes'],
        );

        final newSkiId = await skiRepo.save(candidate);
        skiIdMap[oldId] = newSkiId;
      }

      final testData = jsonData['glideTest'];
      final testCandidate = GlideTestCandidate(
        title: "${testData['title'] ?? 'Importerat test'} (Import)",
        notes: testData['notes'],
      );

      final newTestId = await testRepo.create(
        testCandidate,
      ); // Använder GlideTestRepository.create

      if (testData['useSensorFusion'] == true) {
        await testRepo.setUseSensorFusion(newTestId, true);
      }

      final List<dynamic> jsonRuns = jsonData['runs'] ?? [];

      for (var runData in jsonRuns) {
        final oldSkiId = runData['skiId'] as int;
        final targetSkiId = skiIdMap[oldSkiId] ?? skiIdMap.values.first;

        List<RawAccelerometerEvent> accelEvents = [];
        final String? accelBase64 = runData['accelerometerData'];
        if (accelBase64 != null && accelBase64.isNotEmpty) {
          final compressedBytes = base64Decode(accelBase64);
          final decompressedBytes = gzip.decode(compressedBytes);
          final accelJsonString = utf8.decode(decompressedBytes);
          final List<dynamic> accelJsonList = jsonDecode(accelJsonString);

          accelEvents = accelJsonList
              .map(
                (e) =>
                    RawAccelerometerEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }

        List<RawBarometerEvent> barometerEvents = [];
        final String? barometerBase64 = runData['barometerData'];
        if (barometerBase64 != null && barometerBase64.isNotEmpty) {
          final compressedBytes = base64Decode(barometerBase64);
          final decompressedBytes = gzip.decode(compressedBytes);
          final barometerJsonString = utf8.decode(decompressedBytes);
          final List<dynamic> barometerJsonList = jsonDecode(
            barometerJsonString,
          );

          barometerEvents = barometerJsonList
              .map((e) => RawBarometerEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        final List<dynamic> gpsJsonList = runData['gpsData'] ?? [];
        List<Position> gpsPositions = gpsJsonList
            .map((e) => Position.fromMap(e as Map<String, dynamic>))
            .toList();

        final runCandidate = TestRunCandidate(
          startedAt: DateTime.parse(runData['startedAt']),
          skiId: targetSkiId,
          glideTestId: newTestId,
          elapsedSeconds: runData['elapsedSeconds'] as int,
          gpsData: gpsPositions,
          accelerometerEvents: accelEvents,
          barometerEvents: barometerEvents,
        );

        await runRepo.storeTestRun(runCandidate);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testdata importerad! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fel vid import: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange),
          SizedBox(width: 8),
          Text("Dev Import"),
        ],
      ),
      content: const Text(
        "Select an exported JSON file to import it into your local database. (Only visible in Debug Mode).",
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _pickAndImportFile,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_upload),
          label: const Text("Select JSON"),
        ),
      ],
    );
  }
}
