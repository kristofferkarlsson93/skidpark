import 'package:flutter/material.dart';

enum GlideTestMoreMenuOptions { editGlideTest, archiveGlideTest } // todo

class GlideTestMoreMenu extends StatelessWidget {
  final VoidCallback onSelectEdit;

  final VoidCallback onSelectArchive;

  const GlideTestMoreMenu({
    super.key,
    required this.onSelectEdit,
    required this.onSelectArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<GlideTestMoreMenuOptions>(
      position: PopupMenuPosition.under,
      icon: CircleAvatar(
        backgroundColor: theme.colorScheme.onPrimary, // The circular background color
        foregroundColor: theme.colorScheme.onSurface, // The icon color
        child: const Icon(Icons.more_vert),
      ),
      onSelected: (GlideTestMoreMenuOptions item) {},
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<GlideTestMoreMenuOptions>>[
            const PopupMenuItem<GlideTestMoreMenuOptions>(
              value: GlideTestMoreMenuOptions.editGlideTest,
              child: Text('Redigera testinfo'),
            ),
            const PopupMenuItem<GlideTestMoreMenuOptions>(
              value: GlideTestMoreMenuOptions.archiveGlideTest,
              child: Text('Arkivera glidtestet'),
            ),
          ],
    );
  }
}
