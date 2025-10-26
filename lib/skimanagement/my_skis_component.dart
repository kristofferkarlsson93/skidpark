import 'package:flutter/material.dart';
import 'package:skidpark/database/database.dart';

class MySkisComponent extends StatelessWidget {
  final List<StoredSkiData> skis;

  const MySkisComponent({
    super.key,
    required this.skis,
  });

  @override
  Widget build(BuildContext context) {
    if (skis.isEmpty) {
      final theme = Theme.of(context);

      return Container(
        child: Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Text(
              'Du har inga skidor än.\nKlicka på + för att lägga till.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: skis.length,
      itemBuilder: (context, index) {
        final ski = skis[index];

        return ListTile(
          leading: Icon(
            Icons.ac_unit,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(ski.name),
          subtitle: ski.brandAndModel != null
              ? Text(ski.brandAndModel!)
              : null,
          onTap: () {
          },
        );
      },
    );
  }
}