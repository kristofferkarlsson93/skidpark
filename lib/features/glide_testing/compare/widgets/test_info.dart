import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../compare_runs_view_model.dart';
import 'glide_test_guide.dart';
import 'test_skis_section.dart';

class TestInfo extends StatelessWidget {
  const TestInfo({super.key});

  @override
  Widget build(BuildContext context) => const TestInfoEditor();
}

class TestInfoEditor extends StatefulWidget {
  const TestInfoEditor({super.key});

  @override
  State<TestInfoEditor> createState() => _TestInfoEditorState();
}

class _TestInfoEditorState extends State<TestInfoEditor> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _titleFocus = FocusNode();
  final _notesFocus = FocusNode();
  String? _saveError;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _titleFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _edit(CompareRunsViewModel model, {bool notesFirst = false}) {
    _title.text = model.testTitle;
    _notes.text = model.glideTest?.notes ?? '';
    setState(() => _saveError = null);
    model.beginEditingDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (notesFirst ? _notesFocus : _titleFocus).requestFocus();
    });
  }

  void _changed(CompareRunsViewModel model) {
    model.setDetailsChanged(
      _title.text != model.testTitle ||
          _notes.text != (model.glideTest?.notes ?? ''),
    );
  }

  Future<void> _save(CompareRunsViewModel model) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saveError = null);
    try {
      await model.saveDetails(title: _title.text, notes: _notes.text);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _saveError = 'Kunde inte spara. Texten finns kvar. Försök igen.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CompareRunsViewModel>();
    final theme = Theme.of(context);
    final isExample = model.glideTest?.isExample ?? true;
    if (model.isEditingDetails) {
      return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              identifier: 'test-info-name-field',
              child: TextFormField(
                controller: _title,
                focusNode: _titleFocus,
                enabled: !model.isSavingDetails,
                decoration: const InputDecoration(labelText: 'Testnamn'),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ange ett testnamn.'
                    : null,
                onChanged: (_) => _changed(model),
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              identifier: 'test-info-notes-field',
              child: TextFormField(
                controller: _notes,
                focusNode: _notesFocus,
                enabled: !model.isSavingDetails,
                decoration: const InputDecoration(
                  labelText: 'Anteckningar om testet',
                  hintText: 'Till exempel snöförhållanden, preparering eller sådant du vill komma ihåg.',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => _changed(model),
              ),
            ),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _saveError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: model.isSavingDetails ? null : () => _save(model),
                  child: Text(model.isSavingDetails ? 'Sparar…' : 'Spara'),
                ),
                TextButton(
                  onPressed: model.isSavingDetails
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          model.cancelEditingDetails();
                        },
                  child: const Text('Avbryt'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TestSkisSection(),
          ],
        ),
      );
    }
    final notes = model.glideTest?.notes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                header: true,
                child: Text(
                  model.testTitle,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            if (!isExample)
              IconButton(
                tooltip: 'Redigera testnamn',
                onPressed: () => _edit(model),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        if (isExample)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Exempeltest · kan inte redigeras'),
          ),
        const SizedBox(height: 12),
        const TestSkisSection(),
        const SizedBox(height: 12),
        if (notes != null && notes.isNotEmpty)
          _TestNotesPreview(
            key: ValueKey(notes),
            notes: notes,
            onEdit: isExample ? null : () => _edit(model, notesFirst: true),
          )
        else if (!isExample)
          Semantics(
            identifier: 'test-info-edit-notes',
            child: TextButton.icon(
              onPressed: () => _edit(model, notesFirst: true),
              icon: const Icon(Icons.add),
              label: const Text('Lägg till anteckning'),
            ),
          )
        else
          const Text('Inga anteckningar.'),
      ],
    );
  }
}

class _TestNotesPreview extends StatefulWidget {
  final String notes;
  final VoidCallback? onEdit;

  const _TestNotesPreview({super.key, required this.notes, this.onEdit});

  @override
  State<_TestNotesPreview> createState() => _TestNotesPreviewState();
}

class _TestNotesPreviewState extends State<_TestNotesPreview> {
  static const _previewLines = 3;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Anteckningar', style: theme.textTheme.titleMedium),
              ),
            ),
            if (widget.onEdit != null)
              Semantics(
                identifier: 'test-info-edit-notes',
                label: 'Redigera anteckningar om testet',
                child: TextButton(
                  onPressed: widget.onEdit,
                  child: const Text('Redigera'),
                ),
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final textStyle = theme.textTheme.bodyMedium;
            final painter = TextPainter(
              text: TextSpan(text: widget.notes, style: textStyle),
              maxLines: _previewLines,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth);
            final needsExpansion = painter.didExceedMaxLines;
            painter.dispose();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.notes,
                  style: textStyle,
                  maxLines: _isExpanded ? null : _previewLines,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (needsExpansion)
                  TextButton(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      _isExpanded ? 'Visa mindre' : 'Visa hela anteckningen',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class TestGuide extends StatelessWidget {
  final bool initiallyExpanded;
  const TestGuide({super.key, this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey('test-guide-$initiallyExpanded'),
    initiallyExpanded: initiallyExpanded,
    title: const Text('Så gör du ett glidtest'),
    childrenPadding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
    children: const [GuideInstructions(), GuideDetails()],
  );
}
