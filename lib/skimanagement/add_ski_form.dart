import 'package:flutter/material.dart';

import '../models/ski/ski.dart';

class AddSkiForm extends StatefulWidget {
  const AddSkiForm({super.key});

  @override
  State<AddSkiForm> createState() => _AddSkiFormState();
}

class _AddSkiFormState extends State<AddSkiForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandAndModelController = TextEditingController();
  final _technicalDataController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _brandAndModelController.dispose();
    _technicalDataController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _emptyAsNull(String text) {
    return text.isNotEmpty ? text : null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newSki = Ski(
        name: _nameController.text,
        brandAndModel: _emptyAsNull(_brandAndModelController.text),
        technicalData: _emptyAsNull(_technicalDataController.text),
        notes: _emptyAsNull(_notesController.text),
      );
      Navigator.pop(context, newSki);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    const double horizontalPadding = 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        16 + viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lägg till ny skida',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Skidans namn'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fyll i ett namn på skidan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandAndModelController,
                decoration: const InputDecoration(labelText: 'Märke och modell (valfritt)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _technicalDataController,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Teknisk data (valfritt)',
                  helperText: 'T.ex. höjder (hbw, fbw), tryckzonernas längd, etc.',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Övrig info (valfritt)',
                  helperText: 'T.ex. anteckningar om slipning, valla, känsla...',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Spara'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}