import 'package:flutter/material.dart';
import '../database/database.dart';

class SimpleSkiListItem extends StatelessWidget {
  final StoredSkiData skiDetails;
  final bool isActive;
  final bool isConfirmedStart; // NY PARAMETER
  final VoidCallback onSelected;
  final double height;

  const SimpleSkiListItem({
    super.key,
    required this.skiDetails,
    required this.isActive,
    this.isConfirmedStart = false,
    required this.onSelected,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isConfirmedStart) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      borderColor = theme.colorScheme.primary;
    } else if (isActive) {
      backgroundColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
      borderColor = theme.colorScheme.primaryContainer;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerLow;
      textColor = theme.colorScheme.onSurface;
      borderColor = theme.colorScheme.outlineVariant.withOpacity(0.3);
    }

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: (isActive || isConfirmedStart) ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              skiDetails.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (skiDetails.brandAndModel != null)
              Text(
                skiDetails.brandAndModel!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
