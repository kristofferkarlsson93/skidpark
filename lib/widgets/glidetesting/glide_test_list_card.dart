import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skidpark/database/database.dart';

class GlideTestListCard extends StatelessWidget {
  final StoredGlideTestData glideTest;

  final VoidCallback onTestCardClicked;

  const GlideTestListCard({super.key, required this.glideTest, required this.onTestCardClicked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      tileColor: theme.colorScheme.surfaceContainer,
      leading: Icon(Icons.science_outlined, color: theme.colorScheme.secondary),
      title: Text(glideTest.title),
      subtitle: Text(
        DateFormat("yyyy-MM-dd HH:mm").format(glideTest.createdAt),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(label: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text("0 åk"),
          ), backgroundColor: theme.colorScheme.error),
          SizedBox(width: 8),
          Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTestCardClicked,
    );
  }
}
