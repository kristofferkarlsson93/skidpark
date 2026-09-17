import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/database/repository/glide_test_repository.dart';
import '../../../../common/shared_widgets/app_brand_title.dart';
import '../../../../common/shared_widgets/compact_create_button.dart';
import '../../../../common/shared_widgets/load_error_view.dart';
import '../../create/glide_test_form.dart';
import '../../compare/screens/glide_test_compare_screen.dart';
import '../../example_data/example_data_installer.dart';
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
    _installExampleData();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GlideTestSummary>>(
      stream: _summaryStream,
      builder: (context, snapshot) {
        final tests = snapshot.data ?? const <GlideTestSummary>[];
        final hasOwnTests = tests.any((summary) => !summary.test.isExample);

        return Scaffold(
          appBar: AppBar(
            title: const AppBrandTitle(),
            actions: hasOwnTests
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

    final ownTests = tests.where((summary) => !summary.test.isExample).toList();
    final exampleTests = tests
        .where((summary) => summary.test.isExample)
        .toList();

    if (ownTests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GlideTestingIntroCard(
            onCreateTest: _createTest,
            onLongPressGuide: kDebugMode ? _openDevImport : null,
          ),
          if (exampleTests.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Utforska ett exempel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            MyGlideTestsList(
              glideTests: exampleTests,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Text(
            'Dina test',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        MyGlideTestsList(
          glideTests: ownTests,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        if (exampleTests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
            child: Text(
              'Exempel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          MyGlideTestsList(
            glideTests: exampleTests,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        ],
      ],
    );
  }

  Future<void> _installExampleData() async {
    try {
      await context.read<ExampleDataInstaller?>()?.ensureInstalled();
    } catch (error) {
      debugPrint('Could not install example data: $error');
    }
  }

  Future<void> _createTest() async {
    final candidate = await Navigator.push<GlideTestCandidate>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const GlideTestForm(),
      ),
    );

    if (candidate == null || !mounted) return;
    final testId = await _repository.create(candidate);
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => GlideTestCompareScreen(glideTestId: testId),
      ),
    );
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
