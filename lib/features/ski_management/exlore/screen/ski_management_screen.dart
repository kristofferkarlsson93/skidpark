import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/database/database.dart';
import '../../../../common/database/repository/ski_repository.dart';
import '../../../../common/shared_widgets/app_brand_title.dart';
import '../../../../common/shared_widgets/compact_create_button.dart';
import '../../../../common/shared_widgets/load_error_view.dart';
import '../../create/add_ski_form.dart';
import '../../models/ski.dart';
import '../widgets/my_skis_component.dart';

class SkiManagementScreen extends StatefulWidget {
  const SkiManagementScreen({super.key});

  @override
  State<SkiManagementScreen> createState() => _SkiManagementScreenState();
}

class _SkiManagementScreenState extends State<SkiManagementScreen> {
  final _searchController = TextEditingController();
  late final SkiRepository _repository;
  late Stream<List<StoredSkiData>> _skiStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = context.read<SkiRepository>();
    _skiStream = _repository.watchActiveSkis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StoredSkiData>>(
      stream: _skiStream,
      builder: (context, snapshot) {
        final skis = snapshot.data ?? const <StoredSkiData>[];
        final hasSkis = skis.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const AppBrandTitle(),
            actions: hasSkis
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CompactCreateButton(
                        onPressed: _addSki,
                        label: 'Lägg till',
                      ),
                    ),
                  ]
                : null,
          ),
          body: _buildBody(snapshot, skis),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<StoredSkiData>> snapshot,
    List<StoredSkiData> skis,
  ) {
    if (snapshot.hasError) {
      return LoadErrorView(
        title: 'Kunde inte läsa skidparken',
        message: 'Försök igen. Dina sparade skidor påverkas inte.',
        onRetry: _retry,
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    return MySkisComponent(
      skis: skis,
      searchController: _searchController,
      searchQuery: _searchQuery,
      onSearchChanged: (query) => setState(() => _searchQuery = query),
      onAddSki: _addSki,
    );
  }

  Future<void> _addSki() async {
    final candidate = await Navigator.push<SkiCandidate>(
      context,
      MaterialPageRoute(builder: (context) => const AddSkiForm()),
    );

    if (candidate != null) {
      await _repository.save(candidate);
    }
  }

  void _retry() {
    setState(() {
      _skiStream = _repository.watchActiveSkis();
    });
  }
}
