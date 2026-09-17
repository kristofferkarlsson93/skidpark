import 'package:flutter/material.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';
import 'package:skidpark/features/ski_management/create/widgets/quick_add_ski.dart';
import 'package:skidpark/features/ski_management/models/ski.dart';

import '../../../../common/shared_widgets/simple_ski_list_item.dart';
import '../viewModel/run_recorder_view_model.dart';
import 'instructions_guide.dart';

class StartTestRunWidget extends StatefulWidget {
  final RunRecorderViewModel viewModel;

  const StartTestRunWidget({super.key, required this.viewModel});

  @override
  State<StartTestRunWidget> createState() => _StartTestRunWidgetState();
}

class _StartTestRunWidgetState extends State<StartTestRunWidget> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _quickAddKey = GlobalKey();
  final TextEditingController _newSkiNameController = TextEditingController();
  final FocusNode _newSkiNameFocusNode = FocusNode();
  static const double _itemHeight = 88.0;
  bool _isStarting = false;
  bool _isQuickAddOpen = false;
  bool _isAddingSki = false;
  String? _newSkiNameError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_scrollToCurrentIndex);
  }

  @override
  void dispose() {
    if (_isQuickAddOpen) widget.viewModel.resumeVolumeInput();
    widget.viewModel.removeListener(_scrollToCurrentIndex);
    _scrollController.dispose();
    _newSkiNameController.dispose();
    _newSkiNameFocusNode.dispose();
    super.dispose();
  }

  void _scrollToCurrentIndex() {
    final index = widget.viewModel.markedSkiIndex;

    if (index >= 0 && _scrollController.hasClients) {
      final targetOffset =
          (index * _itemHeight) - (MediaQuery.of(context).size.height / 4);

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleStart() async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      widget.viewModel.startRun();
      _isStarting = false;
    }
  }

  void _openQuickAdd() {
    widget.viewModel.suspendVolumeInput();
    setState(() {
      _isQuickAddOpen = true;
      _newSkiNameError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _newSkiNameFocusNode.requestFocus();
      _ensureQuickAddVisible();
    });
  }

  Future<void> _ensureQuickAddVisible() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || !_isQuickAddOpen) return;
    final quickAddContext = _quickAddKey.currentContext;
    if (quickAddContext == null || !quickAddContext.mounted) return;
    await Scrollable.ensureVisible(
      quickAddContext,
      alignment: 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _closeQuickAdd() {
    if (_isAddingSki) return;
    FocusScope.of(context).unfocus();
    widget.viewModel.resumeVolumeInput();
    setState(() {
      _isQuickAddOpen = false;
      _newSkiNameError = null;
      _newSkiNameController.clear();
    });
  }

  Future<void> _addNewSki() async {
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
      await widget.viewModel.createAndSelectSki(SkiCandidate(name: name));
      if (!mounted) return;

      FocusScope.of(context).unfocus();
      widget.viewModel.resumeVolumeInput();
      setState(() {
        _isQuickAddOpen = false;
        _isAddingSki = false;
        _newSkiNameController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAddingSki = false;
        _newSkiNameError = 'Kunde inte lägga till skidan. Försök igen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectableSkis = widget.viewModel.availableSkis;
    final markedIndex = widget.viewModel.markedSkiIndex;
    final showQuickAdd =
        widget.viewModel.isShowingOtherSkis ||
        !widget.viewModel.canChooseOtherSki;

    return PopScope(
      canPop: !_isQuickAddOpen && !_isAddingSki,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isQuickAddOpen && !_isAddingSki) _closeQuickAdd();
      },
      child: SafeArea(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: widget.viewModel.dataRecorder,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Center(
                    child: GpsAccuracyBanner(
                      accuracyGrade:
                          widget.viewModel.dataRecorder.accuracyGrade,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Text(
              widget.viewModel.isShowingOtherSkis
                  ? "Välj en annan skida"
                  : "Välj skida för åket",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                controller: _scrollController,
                children: [
                  if (selectableSkis.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Det finns inga fler skidor att välja.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  for (final (index, currentSki) in selectableSkis.indexed) ...[
                    SimpleSkiListItem(
                      height: _itemHeight,
                      skiDetails: currentSki,
                      isActive:
                          widget.viewModel.selectedSki?.id == currentSki.id ||
                          index == markedIndex,
                      isConfirmedStart:
                          (widget.viewModel.selectedSki?.id == currentSki.id ||
                              index == markedIndex) &&
                          (_isStarting ||
                              widget.viewModel.isHardwareStartTriggered),
                      onSelected: _isQuickAddOpen
                          ? null
                          : () => widget.viewModel.selectSki(currentSki),
                    ),
                    if (index < selectableSkis.length - 1 || showQuickAdd)
                      const SizedBox(height: 12),
                  ],
                  if (showQuickAdd)
                    KeyedSubtree(
                      key: _quickAddKey,
                      child: QuickAddSki(
                        isOpen: _isQuickAddOpen,
                        isSaving: _isAddingSki,
                        nameController: _newSkiNameController,
                        nameFocusNode: _newSkiNameFocusNode,
                        nameError: _newSkiNameError,
                        showBrandAndModel: false,
                        nameHelperText: 'Fler uppgifter kan läggas till senare i skidparken.',
                        submitLabel: 'Lägg till och välj',
                        onNameChanged: () {
                          if (_newSkiNameError != null) {
                            setState(() => _newSkiNameError = null);
                          }
                        },
                        onOpen: _openQuickAdd,
                        onCancel: _closeQuickAdd,
                        onSave: _addNewSki,
                      ),
                    ),
                ],
              ),
            ),

            if (!_isQuickAddOpen)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const InstructionGuide(
                      firstInstruction: InstructionItem(
                        icon: Icons.unfold_more,
                        primaryText: "Volym + / -",
                        secondaryText: "Välj skida",
                      ),
                      secondInstruction: InstructionItem(
                        icon: Icons.arrow_drop_down,
                        primaryText: "Håll in volym -",
                        secondaryText: "Starta test",
                      ),
                    ),
                    const SizedBox(height: 16),

                    BigButton(
                      backgroundColor:
                          (widget.viewModel.selectedSki != null ||
                              markedIndex >= 0)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      title: 'STARTA TEST',
                      onPress:
                          (widget.viewModel.selectedSki == null &&
                              markedIndex < 0)
                          ? null
                          : () async {
                              if (widget.viewModel.selectedSki == null &&
                                  markedIndex >= 0) {
                                await widget.viewModel.selectSki(
                                  selectableSkis[markedIndex],
                                );
                              }
                              await _handleStart();
                            },
                    ),

                    const SizedBox(height: 8),

                    if (widget.viewModel.canChooseOtherSki)
                      TextButton(
                        onPressed: widget.viewModel.showOtherSkis,
                        child: const Text('Välj annan skida'),
                      ),

                    if (widget.viewModel.canReturnToTestSkis)
                      TextButton(
                        onPressed: widget.viewModel.showTestSkis,
                        child: const Text('Tillbaka till testets skidor'),
                      ),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Avbryt",
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
