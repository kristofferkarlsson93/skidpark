import 'package:flutter/material.dart';

import '../models/glide_test_candidate.dart';
import '../ski_selection/widgets/test_ski_selection_form.dart';

class GlideTestForm extends StatefulWidget {
  const GlideTestForm({super.key});

  @override
  State<GlideTestForm> createState() => _GlideTestFormState();
}

class _GlideTestFormState extends State<GlideTestForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _title.text = 'Glidtest ${now.day}/${now.month} $time';
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: TestSkiSelectionForm(
      title: 'Nytt glidtest',
      submitLabel: 'Skapa test',
      validate: () => _formKey.currentState!.validate(),
      onSave: (skiIds) async => Navigator.pop(
        context,
        GlideTestCandidate(title: _title.text.trim(), skiIds: skiIds),
      ),
      header: Semantics(
        identifier: 'glide-test-name-field',
        child: TextFormField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Testets namn'),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Testet måste ha ett namn'
              : null,
        ),
      ),
    ),
  );
}
