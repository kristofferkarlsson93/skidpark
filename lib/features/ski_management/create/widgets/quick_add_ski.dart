import 'package:flutter/material.dart';

class QuickAddSki extends StatelessWidget {
  const QuickAddSki({
    super.key,
    required this.isOpen,
    required this.isSaving,
    required this.nameController,
    required this.nameFocusNode,
    required this.nameError,
    required this.onNameChanged,
    required this.onOpen,
    required this.onCancel,
    required this.onSave,
    this.brandAndModelController,
    this.showBrandAndModel = true,
    this.nameHelperText,
    this.submitLabel = 'Lägg till',
  }) : assert(
         !showBrandAndModel || brandAndModelController != null,
         'A brandAndModelController is required when the field is shown.',
       );

  final bool isOpen;
  final bool isSaving;
  final TextEditingController nameController;
  final TextEditingController? brandAndModelController;
  final FocusNode nameFocusNode;
  final String? nameError;
  final bool showBrandAndModel;
  final String? nameHelperText;
  final String submitLabel;
  final VoidCallback onNameChanged;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: isOpen ? _buildFields() : _buildTrigger(),
    );
  }

  Widget _buildTrigger() {
    return InkWell(
      onTap: onOpen,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 10),
            Text(
              'Lägg till ny skida',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            identifier: 'ski-name-field',
            child: TextField(
              controller: nameController,
              focusNode: nameFocusNode,
              enabled: !isSaving,
              decoration: InputDecoration(
                labelText: 'Skidans namn',
                hintText: 'Till exempel SP1 eller Atomic Röd',
                helperText: nameHelperText,
                errorText: nameError,
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: showBrandAndModel
                  ? TextInputAction.next
                  : TextInputAction.done,
              onChanged: (_) => onNameChanged(),
              onSubmitted: (_) {
                if (!showBrandAndModel && !isSaving) onSave();
              },
            ),
          ),
          if (showBrandAndModel) ...[
            const SizedBox(height: 12),
            TextField(
              controller: brandAndModelController,
              enabled: !isSaving,
              decoration: const InputDecoration(
                labelText: 'Märke och modell (valfritt)',
                hintText: 'Till exempel Fischer Speedmax 3D',
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!isSaving) onSave();
              },
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: isSaving ? null : onCancel,
                child: const Text('Avbryt'),
              ),
              FilledButton(
                onPressed: isSaving ? null : onSave,
                child: Text(isSaving ? 'Lägger till…' : submitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
