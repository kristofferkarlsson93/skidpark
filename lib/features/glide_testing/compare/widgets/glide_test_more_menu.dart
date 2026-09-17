import 'package:flutter/material.dart';

enum GlideTestMoreMenuOptions {
  editGlideTest,
  exportGlideText,
  deleteGlideTest,
}

class GlideTestMoreMenu extends StatelessWidget {
  final VoidCallback? onSelectEdit;
  final VoidCallback onSelectExport;

  final VoidCallback onSelectDelete;

  const GlideTestMoreMenu({
    super.key,
    this.onSelectEdit,
    required this.onSelectExport,
    required this.onSelectDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<GlideTestMoreMenuOptions>(
      position: PopupMenuPosition.under,
      tooltip: 'Fler alternativ',
      icon: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        foregroundColor: theme.colorScheme.onSurface,
        child: const Icon(Icons.more_vert),
      ),
      onSelected: (GlideTestMoreMenuOptions item) {
        if (item == GlideTestMoreMenuOptions.editGlideTest) {
          onSelectEdit?.call();
        } else if (item == GlideTestMoreMenuOptions.exportGlideText) {
          onSelectExport();
        } else if (item == GlideTestMoreMenuOptions.deleteGlideTest) {
          onSelectDelete();
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<GlideTestMoreMenuOptions>>[
            if (onSelectEdit != null)
              const PopupMenuItem<GlideTestMoreMenuOptions>(
                value: GlideTestMoreMenuOptions.editGlideTest,
                child: Text('Redigera testinfo'),
              ),
            const PopupMenuItem<GlideTestMoreMenuOptions>(
              value: GlideTestMoreMenuOptions.exportGlideText,
              child: Text('Exportera all data'),
            ),
            const PopupMenuItem<GlideTestMoreMenuOptions>(
              value: GlideTestMoreMenuOptions.deleteGlideTest,
              child: Text('Radera glidtestet'),
            ),
          ],
    );
  }
}
