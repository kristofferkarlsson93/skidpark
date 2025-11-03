import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class GlideTestEditButtons extends StatelessWidget {
  const GlideTestEditButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.surfaceContainer,
                child: Icon(
                  Icons.edit_note_sharp,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text("Testinfo"),
            ],
          ),
        ),
        InkWell(
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.surfaceContainer,
                child: SvgPicture.asset(
                  'assets/icons/ski_icon.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                  semanticsLabel: 'Skis icon',
                ),
              ),
              SizedBox(height: 4),
              Text("Skidor"),
            ],
          ),
        ),
      ],
    );
  }
}
