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
  late final String _defaultTitle;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.testToEdit?.title ?? '');
    _notesController = TextEditingController(text: widget.testToEdit?.notes ?? '');
    _defaultTitle = _generateDefaultTitle();
  }

  String _generateDefaultTitle() {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return "Glidtest ${now.day}/${now.month} $timeStr";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.testToEdit != null;
      String titleToUse;

      if (isEditing) {
        titleToUse = _titleController.text.trim();
      } else {
        titleToUse = _titleController.text.trim().isEmpty
            ? _defaultTitle
            : _titleController.text.trim();
      }

      final glideTestCandidate = GlideTestCandidate(
        title: titleToUse,
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
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: isEditing ? "Namnge testet" : "Namnge testet (Valfritt)",
                  hintText: isEditing ? "Ange ett namn" : _defaultTitle,
                  helperText: isEditing
                      ? null
                      : "Förslag: '${_defaultTitle}' - Du kan ändra namn senare",
                  floatingLabelBehavior: isEditing
                      ? FloatingLabelBehavior.auto
                      : FloatingLabelBehavior.always,
                ),
                validator: (value) {
                  if (isEditing) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Testet måste ha ett namn';
                    }
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
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
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