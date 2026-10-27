import 'package:flutter/material.dart';

import '../database/database.dart';

class SimpleSkiListItem extends StatelessWidget {
  static const _unselectedBorderColor = Color(0xFF666979);

  final StoredSkiData skiDetails;
  final bool isActive;
  final bool isConfirmedStart;
  final VoidCallback? onSelected;
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
    final isSelected = isActive || isConfirmedStart;

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
      borderColor = theme.colorScheme.primary;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerLow;
      textColor = theme.colorScheme.onSurface;
      borderColor = _unselectedBorderColor;
    }

    return Semantics(
      selected: isSelected,
      child: InkWell(
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
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
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
                          color: textColor.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                child: isSelected
                    ? Icon(Icons.check_rounded, color: textColor)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
