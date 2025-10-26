import 'package:flutter/material.dart';
import 'package:skidpark/database/database.dart';
import 'package:skidpark/models/ski/ski.dart';
import 'package:skidpark/skimanagement/ski_card.dart';

class MySkisComponent extends StatelessWidget {
  final List<StoredSkiData> skis;

  const MySkisComponent({super.key, required this.skis});

  @override
  Widget build(BuildContext context) {
    if (skis.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),

      itemCount: skis.length,

      itemBuilder: (context, index) {
        final ski = skis[index];
        return SkiCard(ski: ski);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Du har inga skidor än.\nKlicka på + för att lägga till.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
