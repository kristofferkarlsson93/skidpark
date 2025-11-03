import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/models/ski/ski.dart';

import '../../database/database.dart';
import '../../database/repository/ski_repository.dart';
import '../../widgets/skimanagement/add_ski_form.dart';
import '../../widgets/skimanagement/my_skis_component.dart';

class SkiManagementScreen extends StatelessWidget {
  const SkiManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skiRepository = context.read<SkiRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Min skidpark')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-ski-fab',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text('Lägg till skida'),
        onPressed: () async {
          final newSkiCandidate = await showModalBottomSheet<SkiCandidate>(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => const AddSkiForm(),
          );

          if (newSkiCandidate != null) {
            await skiRepository.save(newSkiCandidate);
          }
        },
      ),
      body: StreamBuilder<List<StoredSkiData>>(
        stream: skiRepository.watchSkis(),
        builder: (context, snapshot) {
          final skis = snapshot.data ?? [];
          return MySkisComponent(skis: skis);
        },
      ),
    );
  }
}
