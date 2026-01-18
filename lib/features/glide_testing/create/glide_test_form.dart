import 'package:flutter/material.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';

class GlideTestForm extends StatefulWidget {
  final StoredGlideTestData? testToEdit;

  const GlideTestForm({super.key, this.testToEdit});

  @override
  State<GlideTestForm> createState() => _GlideTestFormState();
}

class _GlideTestFormState extends State<GlideTestForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.testToEdit?.title ?? '');
    _notesController = TextEditingController(text: widget.testToEdit?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final glideTestCandidate = GlideTestCandidate(
        title: _titleController.text,
        notes: _notesController.text,
      );

      Navigator.pop(context, glideTestCandidate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isEditing = widget.testToEdit != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? "Redigera glidtest" : "Skapa nytt glidtest",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Namnge testet",
                  helperText: "T.ex. Inför Vasan 25",
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ge testet ett namn så du känner igen det senare';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,
                controller: _notesController,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Anteckningar (valfritt)',
                  helperText: 'T.ex snötyp, plats osv.',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(isEditing ? 'Spara ändringar' : 'Skapa'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}