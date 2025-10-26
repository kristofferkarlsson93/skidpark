import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skidpark/models/ski/ski.dart';
import 'package:skidpark/skimanagement/my_skis_component.dart';

import '../database/database.dart';
import '../database/repository/ski_repository.dart';
import '../skimanagement/add_ski_form.dart';

class SkiManagementScreen extends StatelessWidget {
  const SkiManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skiRepository = context.read<SkiRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Min skidpark')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
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
