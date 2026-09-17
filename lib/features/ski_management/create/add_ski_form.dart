import 'package:flutter/material.dart';

import '../../../common/database/database.dart';
import '../../../common/utils/text_utils.dart';
import '../models/ski.dart';

class AddSkiForm extends StatefulWidget {
  const AddSkiForm({super.key, this.skiToEdit});

  final StoredSkiData? skiToEdit;

  @override
  State<AddSkiForm> createState() => _AddSkiFormState();
}

class _AddSkiFormState extends State<AddSkiForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandAndModelController = TextEditingController();
  final _technicalDataController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isEditing => widget.skiToEdit != null;

  @override
  void initState() {
    super.initState();
    final ski = widget.skiToEdit;
    if (ski != null) {
      _nameController.text = ski.name;
      _brandAndModelController.text = ski.brandAndModel ?? '';
      _technicalDataController.text = ski.technicalData ?? '';
      _notesController.text = ski.notes ?? '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Redigera skida' : 'Lägg till skida'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Semantics(
              identifier: 'ski-name-field',
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Skidans namn',
                  hintText: 'Till exempel SP1 eller Atomic Röd',
                  helperText: 'Använd ett namn du själv känner igen i spåret.',
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Fyll i ett namn på skidan';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandAndModelController,
              decoration: const InputDecoration(
                labelText: 'Märke och modell (valfritt)',
                hintText: 'Till exempel Fischer Speedmax 3D',
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            Card(
              child: ExpansionTile(
                initiallyExpanded: _hasOptionalInformation,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text('Fler uppgifter'),
                subtitle: const Text('Valfritt'),
                children: [
                  TextFormField(
                    controller: _technicalDataController,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Teknisk data',
                      hintText:
                          'Spannvärden, tryckzoner eller annan stabil '
                          'information',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Anteckningar',
                      hintText: 'Sådant du vill minnas om skidparet',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: FilledButton(
          onPressed: _submitForm,
          child: Text(_isEditing ? 'Spara ändringar' : 'Spara skida'),
        ),
      ),
    );
  }

  bool get _hasOptionalInformation {
    return _technicalDataController.text.isNotEmpty ||
        _notesController.text.isNotEmpty;
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      SkiCandidate(
        name: _nameController.text.trim(),
        brandAndModel: emptyAsNull(_brandAndModelController.text.trim()),
        technicalData: emptyAsNull(_technicalDataController.text.trim()),
        notes: emptyAsNull(_notesController.text.trim()),
      ),
    );
  }
}
