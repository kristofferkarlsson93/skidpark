import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../common/database/repository/glide_test_repository.dart';

class GlideTestListCard extends StatelessWidget {
  const GlideTestListCard({
    super.key,
    required this.summary,
    required this.onTestCardClicked,
  });

  final GlideTestSummary summary;
  final VoidCallback onTestCardClicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTestCardClicked,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.test.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activityLabel(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: _buildFacts()),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFacts() {
    final facts = <Widget>[
      if (summary.test.isExample) const _FactPill(label: 'Exempel'),
    ];
    if (summary.runCount == 0) {
      return [...facts, const _FactPill(label: 'Inga åk ännu')];
    }

    final skiLabel = summary.testedSkiCount == 1
        ? '1 skida'
        : '${summary.testedSkiCount} skidor';
    final runLabel = summary.runCount == 1 ? '1 åk' : '${summary.runCount} åk';

    return [...facts, _FactPill(label: skiLabel), _FactPill(label: runLabel)];
  }

  String _activityLabel() {
    if (summary.test.isExample) {
      return 'Utforska kurvor och datakvalitet';
    }
    final activityAt = summary.latestActivityAt;
    final prefix = summary.runCount == 0 ? 'Skapad' : 'Senast';
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, activityAt)) {
      return '$prefix idag ${DateFormat('HH:mm').format(activityAt)}';
    }

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (DateUtils.isSameDay(yesterday, activityAt)) {
      return '$prefix igår ${DateFormat('HH:mm').format(activityAt)}';
    }

    return '$prefix ${DateFormat('d/M yyyy').format(activityAt)}';
  }
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.bodySmall),
    );
  }
}
