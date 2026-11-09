import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/database/database.dart';
import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/database/repository/ski_repository.dart';
import '../../../ski_management/create/widgets/quick_add_ski.dart';
import '../../../ski_management/models/ski.dart';

class TestSkiSelectionForm extends StatefulWidget {
  const TestSkiSelectionForm({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSave,
    this.glideTestId,
    this.header,
    this.validate,
  });

  final String title;
  final String submitLabel;
  final Future<void> Function(List<int> skiIds) onSave;
  final int? glideTestId;
  final Widget? header;
  final bool Function()? validate;

  @override
  State<TestSkiSelectionForm> createState() => _TestSkiSelectionFormState();
}

class _TestSkiSelectionFormState extends State<TestSkiSelectionForm> {
  final _searchController = TextEditingController();
  final _newSkiNameController = TextEditingController();
  final _newSkiBrandAndModelController = TextEditingController();
  final _newSkiNameFocusNode = FocusNode();
  List<StoredSkiData> _skis = const [];
  Set<int> _selectedSkiIds = {};
  List<int> _initialSelectedIds = const [];
  String? _saveError;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAddingSki = false;
  bool _isQuickAddOpen = false;
  bool _hasLoadedInitialSelection = false;
  bool _showSelectionError = false;
  String? _newSkiNameError;
  Object? _loadError;

  bool get _isEditing => widget.glideTestId != null;
  bool get _hasChanges =>
      !setEquals(_selectedSkiIds, _initialSelectedIds.toSet());

  List<int> get _orderedSelectedIds => [
    ..._initialSelectedIds.where(_selectedSkiIds.contains),
    for (final ski in _skis)
      if (_selectedSkiIds.contains(ski.id) &&
          !_initialSelectedIds.contains(ski.id))
        ski.id,
  ];

  @override
  void initState() {
    super.initState();
    _loadSkis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newSkiNameController.dispose();
    _newSkiBrandAndModelController.dispose();
    _newSkiNameFocusNode.dispose();
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
      final selectedIds = switch (widget.glideTestId) {
        final id? => await glideTestRepository.getSkiIdsForTest(id),
        null => skis.map((ski) => ski.id).toList(),
      };

      if (!mounted) return;
      setState(() {
        _skis = skis;
        if (!_hasLoadedInitialSelection) {
          final activeIds = skis.map((ski) => ski.id).toSet();
          _initialSelectedIds = selectedIds.where(activeIds.contains).toList();
          _selectedSkiIds = _initialSelectedIds.toSet();
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

  Future<void> _submitForm() async {
    setState(() => _showSelectionError = _selectedSkiIds.isEmpty);
    final isValid = widget.validate?.call() ?? true;
    if (_selectedSkiIds.isEmpty || !isValid) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(_orderedSelectedIds);
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError =
              'Kunde inte spara skidurvalet. Dina val finns kvar. Försök igen.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDiscard() async {
    if (_isSaving) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lämna utan att spara?'),
        content: const Text('Dina ändringar i skidurvalet sparas inte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fortsätt välja'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lämna'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving && !(_isEditing && _hasChanges),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSaving) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: AbsorbPointer(absorbing: _isSaving, child: _buildBody(context)),
        bottomNavigationBar: _isLoading || _loadError != null
            ? null
            : Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_saveError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _saveError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          if (_isEditing) ...[
                            TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('Avbryt'),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: FilledButton(
                              onPressed: _isSaving || _isAddingSki
                                  ? null
                                  : _submitForm,
                              child: Text(
                                _isSaving ? 'Sparar…' : widget.submitLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 24),
        ],
        if (_isEditing) ...[
          const Text(
            'Välj vilka skidor som föreslås för nya åk. Tidigare åk finns kvar.',
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing)
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
                  if (index < _visibleSkis.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        QuickAddSki(
          cancelLabel: _isEditing ? 'Stäng' : 'Avbryt',
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
      ],
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
