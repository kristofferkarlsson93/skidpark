import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';

class AddGlideTestForm extends StatefulWidget {
  const AddGlideTestForm({super.key});

  @override
  State<AddGlideTestForm> createState() => _AddGlideTestFormState();
}

class _AddGlideTestFormState extends State<AddGlideTestForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

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
    final viewInsets = MediaQuery
        .of(context)
        .viewInsets; // keyboards etc

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Skapa nytt glidtest"),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Namnge testet",
                  helperText: "T.ex.  Inför Vasan 25",
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
                  labelText: 'Antekningar (valfritt)',
                  helperText: 'T.ex snötyp, plats osv.',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Skapa'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
