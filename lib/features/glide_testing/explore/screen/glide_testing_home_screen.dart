import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/shared_widgets/app_brand_title.dart';
import '../../../../common/shared_widgets/compact_create_button.dart';
import '../../../../common/shared_widgets/load_error_view.dart';
import '../../create/glide_test_form.dart';
import '../../models/glide_test_candidate.dart';
import '../widgets/dev_import_dialog.dart';
import '../widgets/glide_testing_intro_card.dart';
import '../widgets/my_glide_tests_list.dart';

class GlideTestingHomeScreen extends StatefulWidget {
  const GlideTestingHomeScreen({super.key});

  @override
  State<GlideTestingHomeScreen> createState() => _GlideTestingHomeScreenState();
}

class _GlideTestingHomeScreenState extends State<GlideTestingHomeScreen> {
  late final GlideTestRepository _repository;
  late Stream<List<GlideTestSummary>> _summaryStream;

  @override
  void initState() {
    super.initState();
    _repository = context.read<GlideTestRepository>();
    _summaryStream = _repository.watchTestSummaries();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GlideTestSummary>>(
      stream: _summaryStream,
      builder: (context, snapshot) {
        final tests = snapshot.data ?? const <GlideTestSummary>[];
        final hasTests = tests.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const AppBrandTitle(),
            actions: hasTests
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CompactCreateButton(
                        onPressed: _createTest,
                        label: 'Nytt test',
                      ),
                    ),
                  ]
                : null,
          ),
          body: _buildBody(snapshot, tests),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<GlideTestSummary>> snapshot,
    List<GlideTestSummary> tests,
  ) {
    if (snapshot.hasError) {
      return LoadErrorView(
        title: 'Kunde inte läsa dina test',
        message: 'Försök igen. Dina sparade test påverkas inte.',
        onRetry: _retry,
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GlideTestingIntroCard(
            onCreateTest: _createTest,
            onLongPressGuide: kDebugMode ? _openDevImport : null,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Text(
            'Dina test',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(child: MyGlideTestsList(glideTests: tests)),
      ],
    );
  }

  Future<void> _createTest() async {
    final candidate = await showModalBottomSheet<GlideTestCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const GlideTestForm(),
    );

    if (candidate != null) {
      await _repository.create(candidate);
    }
  }

  void _retry() {
    setState(() {
      _summaryStream = _repository.watchTestSummaries();
    });
  }

  void _openDevImport() {
    showDialog<void>(
      context: context,
      builder: (context) => const DevImportDialog(),
    );
  }
}
