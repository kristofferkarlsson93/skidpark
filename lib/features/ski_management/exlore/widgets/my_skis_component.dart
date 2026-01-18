import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart'; // Om du vill ha ikon i empty state
import 'package:skidpark/features/ski_management/exlore/widgets/ski_card.dart';

import '../../../../common/database/database.dart';

class MySkisComponent extends StatelessWidget {
  final List<StoredSkiData> skis;

  const MySkisComponent({super.key, required this.skis});

  @override
  Widget build(BuildContext context) {
    if (skis.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemCount: skis.length,
      itemBuilder: (context, index) {
        return SkiCard(ski: skis[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.downhill_skiing,
                size: 48,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Din skidpark är tom",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Lägg till dina skidor här för att kunna välja dem när du utför glidtester.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
