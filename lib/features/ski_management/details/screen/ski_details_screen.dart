import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/database/database.dart';
import '../../../../common/database/repository/ski_repository.dart';
import '../../create/add_ski_form.dart';
import '../../models/ski.dart';

class SkiDetailScreen extends StatelessWidget {
  const SkiDetailScreen({super.key, required this.skiId});

  final int skiId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<SkiRepository>();

    return StreamBuilder<StoredSkiData>(
      stream: repository.watchSkiById(skiId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Kunde inte läsa skidan.')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final ski = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(ski.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Redigera skida',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editSki(context, repository, ski),
              ),
              PopupMenuButton<_SkiAction>(
                tooltip: 'Fler val',
                onSelected: (action) {
                  if (action == _SkiAction.archive) {
                    _confirmArchive(context, repository, ski);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _SkiAction.archive,
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined),
                        SizedBox(width: 12),
                        Text('Arkivera skida'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _InfoCard(
                rows: [
                  _InfoRow(label: 'Märke och modell', value: ski.brandAndModel),
                  _InfoRow(label: 'Teknisk data', value: ski.technicalData),
                  _InfoRow(label: 'Anteckningar', value: ski.notes),
                  _InfoRow(
                    label: 'Tillagd',
                    value: DateFormat('d/M yyyy, HH:mm').format(ski.createdAt),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editSki(
    BuildContext context,
    SkiRepository repository,
    StoredSkiData ski,
  ) async {
    final candidate = await Navigator.push<SkiCandidate>(
      context,
      MaterialPageRoute(builder: (context) => AddSkiForm(skiToEdit: ski)),
    );

    if (candidate != null) {
      await repository.updateSki(ski, candidate);
    }
  }

  Future<void> _confirmArchive(
    BuildContext context,
    SkiRepository repository,
    StoredSkiData ski,
  ) async {
    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arkivera skida?'),
        content: Text(
          '”${ski.name}” finns kvar i tidigare glidtest men går inte att välja '
          'i nya test.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arkivera'),
          ),
        ],
      ),
    );

    if (didConfirm != true) return;

    await repository.archiveSki(ski);
    if (context.mounted) Navigator.pop(context);
  }
}

enum _SkiAction { archive }

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.where((row) => row.hasValue).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < visibleRows.length; index++) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(),
                ),
              Text(
                visibleRows[index].label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(visibleRows[index].value!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  bool get hasValue => value != null && value!.trim().isNotEmpty;
}
