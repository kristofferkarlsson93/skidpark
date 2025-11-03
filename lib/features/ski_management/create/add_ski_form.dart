import 'package:flutter/material.dart';

import '../../../common/database/database.dart';
import '../../../common/utils/text_utils.dart';
import '../models/ski.dart';

class AddSkiForm extends StatefulWidget {

  final StoredSkiData? skiToEdit;

  const AddSkiForm({super.key, this.skiToEdit});

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
  void initState() {
    super.initState();
    if (widget.skiToEdit != null) {
      _nameController.text = widget.skiToEdit!.name;
      _brandAndModelController.text = widget.skiToEdit!.brandAndModel ?? '';
      _technicalDataController.text = widget.skiToEdit!.technicalData ?? '';
      _notesController.text = widget.skiToEdit!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandAndModelController.dispose();
    _technicalDataController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final skiCandidate = SkiCandidate(
        name: _nameController.text,
        brandAndModel: emptyAsNull(_brandAndModelController.text),
        technicalData: emptyAsNull(_technicalDataController.text),
        notes: emptyAsNull(_notesController.text),
      );
      Navigator.pop(context, skiCandidate);
    }
  }
  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    const double horizontalPadding = 16.0;

    final isEditing = widget.skiToEdit != null;
    final title = isEditing ? 'Redigera skida' : 'Lägg till ny skida';
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
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Skidans namn'),
                textCapitalization: TextCapitalization.words,
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
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,
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
                textCapitalization: TextCapitalization.sentences,
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