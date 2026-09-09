import 'package:flutter/material.dart';

/// A compact, filled app-bar action that remains usable with large text.
class CompactCreateButton extends StatelessWidget {
  const CompactCreateButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(13) / 13;
    final useIconOnly = mediaQuery.size.width < 360 || textScale >= 1.3;

    if (useIconOnly) {
      return IconButton.filled(
        onPressed: onPressed,
        tooltip: label,
        icon: const Icon(Icons.add_rounded),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
      );
    }

    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
