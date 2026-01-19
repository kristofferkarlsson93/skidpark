import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../common/database/database.dart';

class GlideTestListCard extends StatelessWidget {
  final StoredGlideTestData glideTest;

  final VoidCallback onTestCardClicked;

  const GlideTestListCard({
    super.key,
    required this.glideTest,
    required this.onTestCardClicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTestCardClicked,

        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.science_outlined,
            color: theme.colorScheme.primaryContainer,
            size: 24,
          ),
        ),
        title: Text(glideTest.title),
        subtitle: Text(
          DateFormat("yyyy-MM-dd HH:mm").format(glideTest.createdAt),
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}
