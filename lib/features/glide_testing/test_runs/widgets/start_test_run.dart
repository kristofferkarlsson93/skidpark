import 'package:flutter/material.dart';
import 'package:skidpark/common/shared_widgets/big_button.dart';
import 'package:skidpark/features/glide_testing/test_runs/widgets/gps_accuracy_banner.dart';

import '../../../../common/shared_widgets/simple_ski_list_item.dart';
import '../viewModel/run_recorder_view_model.dart';

class StartTestRunWidget extends StatefulWidget {
  final RunRecorderViewModel viewModel;

  const StartTestRunWidget({super.key, required this.viewModel});

  @override
  State<StartTestRunWidget> createState() => _StartTestRunWidgetState();
}

class _StartTestRunWidgetState extends State<StartTestRunWidget> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 88.0;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_scrollToCurrentIndex);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_scrollToCurrentIndex);
    _scrollController.dispose();
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

  void _handleStart() async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectableSkis = widget.viewModel.availableSkis;
    final markedIndex = widget.viewModel.markedSkiIndex;

    return SafeArea(
      child: Column(
        children: [
          ListenableBuilder(
            listenable: widget.viewModel.dataRecorder,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Center(
                  child: GpsAccuracyBanner(
                    accuracyGrade: widget.viewModel.dataRecorder.accuracyGrade,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Text("Välj skida för åket", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: selectableSkis.length,
              controller: _scrollController,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final currentSki = selectableSkis[index];
                final isSelectedViaTouch =
                    widget.viewModel.selectedSki?.id == currentSki.id;
                final isMarkedViaKeys = index == markedIndex;
                final isActive = isSelectedViaTouch || isMarkedViaKeys;
                final isConfirmedStart =
                    (isActive && _isStarting) ||
                    (isActive && widget.viewModel.isHardwareStartTriggered);

                return SimpleSkiListItem(
                  height: _itemHeight,
                  skiDetails: currentSki,
                  isActive: isActive,
                  isConfirmedStart: isConfirmedStart,
                  onSelected: () {
                    widget.viewModel.selectSki(currentSki);
                  },
                );
              },
            ),
          ),

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
                _buildVolumeKeyGuide(theme),
                const SizedBox(height: 16),

                BigButton(
                  backgroundColor:
                      (widget.viewModel.selectedSki != null || markedIndex >= 0)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  title: 'STARTA TEST',
                  onPress:
                      (widget.viewModel.selectedSki == null && markedIndex < 0)
                      ? null
                      : () {
                          if (widget.viewModel.selectedSki == null &&
                              markedIndex >= 0) {
                            widget.viewModel.selectSki(
                              selectableSkis[markedIndex],
                            );
                          }
                          _handleStart();
                        },
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Avbryt",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeKeyGuide(ThemeData theme) {
    Widget instructionItem(IconData icon, String action, String input) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                input.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                action,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        instructionItem(Icons.unfold_more, "Välj skida", "Volym + / -"),
        Container(
          width: 1,
          height: 30,
          color: theme.colorScheme.outlineVariant,
        ),
        instructionItem(Icons.touch_app, "Starta test", "Håll in"),
      ],
    );
  }
}
