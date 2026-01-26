import 'package:flutter/material.dart';

enum GlideTestMoreMenuOptions {
  editGlideTest,
  exportGlideText,
  archiveGlideTest,
} // todo

class GlideTestMoreMenu extends StatelessWidget {
  final VoidCallback onSelectEdit;
  final VoidCallback onSelectExport;

  final VoidCallback onSelectArchive;

  const GlideTestMoreMenu({
    super.key,
    required this.onSelectEdit,
    required this.onSelectExport,
    required this.onSelectArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<GlideTestMoreMenuOptions>(
      position: PopupMenuPosition.under,
      icon: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        foregroundColor: theme.colorScheme.onSurface,
        child: const Icon(Icons.more_vert),
      ),
      onSelected: (GlideTestMoreMenuOptions item) {
        if (item == GlideTestMoreMenuOptions.editGlideTest) {
          return onSelectEdit();
        } else if (item == GlideTestMoreMenuOptions.exportGlideText) {
          return onSelectExport();
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<GlideTestMoreMenuOptions>>[
            const PopupMenuItem<GlideTestMoreMenuOptions>(
              value: GlideTestMoreMenuOptions.editGlideTest,
              child: Text('Redigera testinfo'),
            ),
            const PopupMenuItem<GlideTestMoreMenuOptions>(
              value: GlideTestMoreMenuOptions.exportGlideText,
              child: Text('Exportera all data'),
            ),
            // Not impplemented yet. Hiding.
            // const PopupMenuItem<GlideTestMoreMenuOptions>(
            //   value: GlideTestMoreMenuOptions.archiveGlideTest,
            //   child: Text('Arkivera glidtestet'),
            // ),
          ],
    );
  }
}
