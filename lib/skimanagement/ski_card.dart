import 'package:flutter/material.dart';

import '../database/database.dart';
import '../screens/ski_details_screen.dart';

class SkiCard extends StatelessWidget {
  const SkiCard({super.key, required this.ski});

  final StoredSkiData ski;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SkiDetailScreen(skiId: ski.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 36, color: theme.colorScheme.primary),

                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ski.name,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ski.brandAndModel != null)
                          Text(
                            ski.brandAndModel!,
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (ski.technicalData != null)
                Text(
                  ski.technicalData!,
                  style: textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
