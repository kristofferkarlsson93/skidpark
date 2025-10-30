import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../database/database.dart';
import '../../screens/ski/ski_details_screen.dart';

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
              Center(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  child: SvgPicture.asset(
                    'assets/icons/ski_icon.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onPrimary,
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'Skis icon',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  ski.name,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ski.brandAndModel != null)
                Center(
                  child: Text(
                    ski.brandAndModel!,
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ski.technicalData != null)
                      Text(
                        ski.technicalData!,
                        style: textTheme.bodySmall,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
