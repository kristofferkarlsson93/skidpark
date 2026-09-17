import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/database/database.dart';
import '../../../common/database/repository/glide_test_repository.dart';
import '../../../common/database/repository/ski_repository.dart';
import '../../ski_management/create/widgets/quick_add_ski.dart';
import '../../ski_management/models/ski.dart';
import '../models/glide_test_candidate.dart';

class GlideTestForm extends StatefulWidget {
  const GlideTestForm({super.key, this.testToEdit});

  final StoredGlideTestData? testToEdit;

  @override
  State<GlideTestForm> createState() => _GlideTestFormState();
}

class _GlideTestFormState extends State<GlideTestForm> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _newSkiNameController = TextEditingController();
  final _newSkiBrandAndModelController = TextEditingController();
  final _newSkiNameFocusNode = FocusNode();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final String _defaultTitle;

  List<StoredSkiData> _skis = const [];
  Set<int> _selectedSkiIds = {};
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAddingSki = false;
  bool _isQuickAddOpen = false;
  bool _hasLoadedInitialSelection = false;
  bool _showSelectionError = false;
  String? _newSkiNameError;
  Object? _loadError;

  bool get _isEditing => widget.testToEdit != null;

  @override
  void initState() {
    super.initState();
    _defaultTitle = _generateDefaultTitle();
    _titleController = TextEditingController(
      text: widget.testToEdit?.title ?? _defaultTitle,
    );
    _notesController = TextEditingController(
      text: widget.testToEdit?.notes ?? '',
    );
    _loadSkis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newSkiNameController.dispose();
    _newSkiBrandAndModelController.dispose();
    _newSkiNameFocusNode.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSkis() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final skiRepository = context.read<SkiRepository>();
      final glideTestRepository = context.read<GlideTestRepository>();
      final skis = await skiRepository.getActiveSkis();
      final selectedIds = switch (widget.testToEdit) {
        final test? => await glideTestRepository.getSkiIdsForTest(test.id),
        null => skis.map((ski) => ski.id).toList(),
      };

      if (!mounted) return;
      setState(() {
        _skis = skis;
        if (!_hasLoadedInitialSelection) {
          _selectedSkiIds = selectedIds.toSet();
          _hasLoadedInitialSelection = true;
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  String _generateDefaultTitle() {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    return 'Glidtest ${now.day}/${now.month} $time';
  }

  List<StoredSkiData> get _visibleSkis {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _skis;
    return _skis.where((ski) {
      return ski.name.toLowerCase().contains(query) ||
          (ski.brandAndModel?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _selectLatestTest() async {
    final ids = await context
        .read<GlideTestRepository>()
        .getLatestRealTestSkiIds();
    if (!mounted) return;
    final activeIds = _skis.map((ski) => ski.id).toSet();
    final availableIds = ids.where(activeIds.contains).toSet();
    if (availableIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inget tidigare skidurval hittades.')),
      );
      return;
    }
    setState(() {
      _selectedSkiIds = availableIds;
      _showSelectionError = false;
    });
  }

  void _openQuickAdd() {
    setState(() {
      _isQuickAddOpen = true;
      _newSkiNameError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _newSkiNameFocusNode.requestFocus();
    });
  }

  void _closeQuickAdd() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isQuickAddOpen = false;
      _newSkiNameError = null;
      _newSkiNameController.clear();
      _newSkiBrandAndModelController.clear();
    });
  }

  Future<void> _addSki() async {
    final name = _newSkiNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _newSkiNameError = 'Fyll i ett namn på skidan');
      _newSkiNameFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isAddingSki = true;
      _newSkiNameError = null;
    });

    try {
      final skiRepository = context.read<SkiRepository>();
      final skiId = await skiRepository.save(
        SkiCandidate(
          name: name,
          brandAndModel: _emptyAsNull(
            _newSkiBrandAndModelController.text.trim(),
          ),
        ),
      );
      final skis = await skiRepository.getActiveSkis();
      if (!mounted) return;

      setState(() {
        _skis = skis;
        _selectedSkiIds.add(skiId);
        _showSelectionError = false;
        _isAddingSki = false;
        _newSkiNameController.clear();
        _newSkiBrandAndModelController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _newSkiNameFocusNode.requestFocus();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAddingSki = false;
        _newSkiNameError = 'Kunde inte lägga till skidan. Försök igen.';
      });
    }
  }

  String? _emptyAsNull(String value) => value.isEmpty ? null : value;

  void _submitForm() {
    setState(() => _showSelectionError = _selectedSkiIds.isEmpty);
    if (!_formKey.currentState!.validate() || _selectedSkiIds.isEmpty) return;

    setState(() => _isSaving = true);
    final orderedSkiIds = _skis
        .where((ski) => _selectedSkiIds.contains(ski.id))
        .map((ski) => ski.id)
        .toList();
    Navigator.pop(
      context,
      GlideTestCandidate(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        skiIds: orderedSkiIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Redigera test' : 'Nytt glidtest'),
      ),
      body: _buildBody(context),
      bottomNavigationBar: _isLoading || _loadError != null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: FilledButton(
                onPressed: _isSaving ? null : _submitForm,
                child: Text(_isEditing ? 'Spara ändringar' : 'Skapa test'),
              ),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kunde inte läsa skidparken.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadSkis,
                child: const Text('Försök igen'),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Semantics(
            identifier: 'glide-test-name-field',
            child: TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Testets namn'),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Testet måste ha ett namn'
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skidor i testet', style: theme.textTheme.titleMedium),
                    Text(
                      '${_selectedSkiIds.length} av ${_skis.length} valda',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showSelectionError) ...[
            const SizedBox(height: 8),
            Text(
              'Välj minst en skida till testet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SelectionAction(
                label: 'Alla',
                selected:
                    _skis.isNotEmpty && _selectedSkiIds.length == _skis.length,
                onPressed: () => setState(() {
                  _selectedSkiIds = _skis.map((ski) => ski.id).toSet();
                  _showSelectionError = false;
                }),
              ),
              _SelectionAction(
                label: 'Ingen',
                selected: _selectedSkiIds.isEmpty,
                onPressed: () => setState(() => _selectedSkiIds.clear()),
              ),
              if (!_isEditing)
                _SelectionAction(
                  label: 'Senaste testet',
                  icon: Icons.history,
                  onPressed: _selectLatestTest,
                ),
            ],
          ),
          if (_skis.length > 4) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Sök bland skidor',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_skis.isEmpty)
            const _EmptySkiPark()
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, ski) in _visibleSkis.indexed) ...[
                    CheckboxListTile(
                      value: _selectedSkiIds.contains(ski.id),
                      onChanged: (selected) => setState(() {
                        if (selected ?? false) {
                          _selectedSkiIds.add(ski.id);
                          _showSelectionError = false;
                        } else {
                          _selectedSkiIds.remove(ski.id);
                        }
                      }),
                      title: Text(ski.name),
                      subtitle: ski.brandAndModel == null
                          ? null
                          : Text(ski.brandAndModel!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (index < _visibleSkis.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          QuickAddSki(
            isOpen: _isQuickAddOpen,
            isSaving: _isAddingSki,
            nameController: _newSkiNameController,
            brandAndModelController: _newSkiBrandAndModelController,
            nameFocusNode: _newSkiNameFocusNode,
            nameError: _newSkiNameError,
            onNameChanged: () {
              if (_newSkiNameError != null) {
                setState(() => _newSkiNameError = null);
              }
            },
            onOpen: _openQuickAdd,
            onCancel: _closeQuickAdd,
            onSave: _addSki,
          ),
          const SizedBox(height: 24),
          Card(
            child: Semantics(
              identifier: 'glide-test-notes-section',
              child: ExpansionTile(
                initiallyExpanded: _notesController.text.isNotEmpty,
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text('Anteckningar'),
                subtitle: const Text('Valfritt'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Semantics(
                    identifier: 'glide-test-notes-field',
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText:
                            'Till exempel plats, snötyp eller förhållanden',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionAction extends StatelessWidget {
  const _SelectionAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      foregroundColor: selected
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onSurfaceVariant,
      backgroundColor: selected ? theme.colorScheme.primaryContainer : null,
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
    );

    if (icon == null) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _EmptySkiPark extends StatelessWidget {
  const _EmptySkiPark();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Din skidpark är tom. Lägg till dina skidor här så sparas de '
          'samtidigt i skidparken.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
