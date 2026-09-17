import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../import/glide_test_import_service.dart';

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
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty || files.single.path == null) return;

      final source = await File(files.single.path!).readAsString();
      if (!mounted) return;
      await context.read<GlideTestImportService>().importJson(
        source,
        asExample: false,
        titleSuffix: ' (Import)',
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Testdata importerad.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fel vid import: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange),
          SizedBox(width: 8),
          Text('Dev Import'),
        ],
      ),
      content: const Text(
        'Importera en exporterad JSON-fil till den lokala databasen. '
        'Funktionen visas bara i debug-läge.',
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _pickAndImportFile,
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_upload),
          label: const Text('Välj JSON'),
        ),
      ],
    );
  }
}
