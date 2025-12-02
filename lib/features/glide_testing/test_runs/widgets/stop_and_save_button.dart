import 'package:flutter/material.dart';
import '../../../../common/shared_widgets/big_button.dart';

class StopAndSaveButton extends StatelessWidget {
  final int countdownSeconds;
  final VoidCallback onStopAndSave;

  const StopAndSaveButton({
    super.key,
    required this.countdownSeconds,
    required this.onStopAndSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countdown = countdownSeconds;

    final buttonTitle = countdown > 0 ? 'Autospar om $countdown...' : 'SPARA';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: BigButton(
        key: ValueKey<String>(buttonTitle),
        backgroundColor: theme.colorScheme.error,
        title: buttonTitle,
        onPress: onStopAndSave,
      ),
    );
  }
}
