import 'package:flutter/material.dart';
import 'package:skidpark/database/database.dart';
import 'package:skidpark/widgets/shared/big_button.dart';

import '../../screens/glidetesting/run_recording_screen.dart';
import '../skimanagement/simple_ski_list_item.dart';

class StartTestRunWidget extends StatefulWidget {
  final List<StoredSkiData> selectableSkis;
  final void Function(StoredSkiData) onStartClick;

  const StartTestRunWidget({
    super.key,
    required this.selectableSkis,
    required this.onStartClick,
  });

  @override
  State<StartTestRunWidget> createState() => _StartTestRunWidgetState();
}

class _StartTestRunWidgetState extends State<StartTestRunWidget> {
  StoredSkiData? selectedSki;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          SizedBox(height: 64),
          Text("Välj skida för åket", style: theme.textTheme.titleMedium),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(
                RunRecorderScreen.PADDING_FROM_EDGE,
              ),
              itemCount: widget.selectableSkis.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final currentSki = widget.selectableSkis[index];
                return SimpleSkiListItem(
                  skiDetails: currentSki,
                  isSelected:
                      selectedSki != null && selectedSki!.id == currentSki.id,
                  isMarked: false,
                  onSelected: () {
                    setState(() {
                      selectedSki = currentSki;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(RunRecorderScreen.PADDING_FROM_EDGE),
            child: BigButton(
              backgroundColor: theme.colorScheme.secondary,
              title: 'STARTA TEST',
              onPress: selectedSki == null
                  ? null
                  : () {
                      widget.onStartClick(selectedSki!);
                    },
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: SizedBox(
              child: Text(
                "Avbryt",
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
