import 'package:flutter/material.dart';

import '../../../../common/database/database.dart';
import 'ski_card.dart';

class MySkisComponent extends StatelessWidget {
  const MySkisComponent({
    super.key,
    required this.skis,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddSki,
  });

  final List<StoredSkiData> skis;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddSki;

  @override
  Widget build(BuildContext context) {
    if (skis.isEmpty) {
      return _EmptySkiPark(onAddSki: onAddSki);
    }

    final normalizedQuery = searchQuery.trim().toLowerCase();
    final filteredSkis = skis.where((ski) {
      final searchableText = '${ski.name} ${ski.brandAndModel ?? ''}'
          .toLowerCase();
      return searchableText.contains(normalizedQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Sök i skidparken',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Rensa sökning',
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Dina skidor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${skis.length} par',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredSkis.isEmpty
              ? _NoSearchResults(query: searchQuery)
              : ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 9),
                  itemCount: filteredSkis.length,
                  itemBuilder: (context, index) =>
                      SkiCard(ski: filteredSkis[index]),
                ),
        ),
      ],
    );
  }
}

class _EmptySkiPark extends StatelessWidget {
  const _EmptySkiPark({required this.onAddSki});

  final VoidCallback onAddSki;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.downhill_skiing_rounded,
                color: theme.colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Din skidpark är tom',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Ge skidorna de namn du själv känner igen i spåret.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddSki,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Lägg till din första skida'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Ingen skida matchar ”${query.trim()}”.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
