import 'package:flutter/material.dart';
import 'package:skidpark/database/database.dart';

class SimpleSkiListItem extends StatelessWidget {
  final StoredSkiData skiDetails;

  final bool isSelected;
  final bool isMarked;
  final VoidCallback onSelected;

  const SimpleSkiListItem({
    super.key,
    required this.skiDetails,
    required this.isSelected,
    required this.isMarked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var borderColor = theme.colorScheme.outline;
    var cardColor = theme.cardTheme.color;
    if (isMarked || isSelected) {
      borderColor = theme.colorScheme.secondary;
    }
    if (isSelected) {
      cardColor = theme.colorScheme.secondary.withValues(alpha: 0.2);
    }

    return InkWell(
      onTap: () {
        onSelected();
      },
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(skiDetails.name, style: theme.textTheme.headlineMedium),
              Text(
                skiDetails.brandAndModel ?? "",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
