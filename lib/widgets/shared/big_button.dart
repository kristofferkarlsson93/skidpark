import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  final Color backgroundColor;

  final VoidCallback? onPress;

  final String title;

  const BigButton({super.key, required this.backgroundColor, required this.title, this.onPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          textStyle: theme.textTheme.titleLarge,
          backgroundColor: backgroundColor,
        ),
        onPressed: onPress == null
            ? null
            : () {
                onPress!();
              },
        child: Text(title),
      ),
    );
  }
}
