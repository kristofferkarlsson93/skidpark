import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/database/database.dart';
import 'package:skidpark/database/repository/ski_repository.dart';
import 'package:skidpark/models/ski/ski.dart';
import 'package:intl/intl.dart';

import '../../widgets/skimanagement/add_ski_form.dart';

class SkiDetailScreen extends StatelessWidget {
  final int skiId;

  const SkiDetailScreen({super.key, required this.skiId});
  @override
  Widget build(BuildContext context) {
    final skiRepository = context.read<SkiRepository>();

    return StreamBuilder<StoredSkiData>(
      stream: skiRepository.watchSkiById(skiId),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final ski = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(ski.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, skiRepository, ski),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editSki(context, skiRepository, ski),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              _buildInfoTile(
                context,
                icon: Icons.label_outline,
                label: 'Märke & Modell',
                value: ski.brandAndModel,
              ),
              _buildInfoTile(
                context,
                icon: Icons.description_outlined,
                label: 'Teknisk data',
                value: ski.technicalData,
              ),
              _buildInfoTile(
                context,
                icon: Icons.notes_outlined,
                label: 'Anteckningar',
                value: ski.notes,
              ),
              _buildInfoTile(
                context,
                icon: Icons.calendar_today_outlined,
                label: 'Tillagd',
                value: DateFormat('yyyy-MM-dd, HH:mm').format(ski.createdAt),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String? value,
      }) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary, // Använd din lila accentfärg
      ),
      title: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant, // Muted-färg
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _editSki(
      BuildContext context,
      SkiRepository skiRepository,
      StoredSkiData ski,
      ) async {
    final updatedCandidate = await showModalBottomSheet<SkiCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddSkiForm(skiToEdit: ski), // ★★★ Skicka med skidan
    );

    if (updatedCandidate != null) {
      await skiRepository.updateSki(ski, updatedCandidate);
    }
  }

  void _confirmDelete(
      BuildContext context,
      SkiRepository skiRepository,
      StoredSkiData ski,
      ) async {
    final bool? didConfirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Radera skida?'),
        content: Text('Är du säker på att du vill radera "${ski.name}"?'),
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
            child: const Text('Radera'),
          ),
        ],
      ),
    );

    if (didConfirm == true) {
      await skiRepository.deleteSki(ski);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}