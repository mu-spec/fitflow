import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_filter_sheet.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Exercise Library with instant search, filters, quick filters, live count.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key, this.exercisesForTest});

  /// Optional override for testing empty-catalog handling.
  /// When null, uses [ExerciseCatalog.all] filtered to active exercises.
  final List<Exercise>? exercisesForTest;

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  late final TextEditingController _searchController;
  ExerciseLibraryFilter _filter = const ExerciseLibraryFilter();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _filter.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    setState(() {
      _filter = _filter.copyWith(searchQuery: value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _updateSearch('');
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ExerciseFilterSheet(
              filter: _filter,
              onChanged: (next) {
                setState(() => _filter = next);
                setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _filter = _filter.clearFilters();
    });
  }

  void _clearAll() {
    _searchController.clear();
    setState(() {
      _filter = _filter.clearAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allExercises =
        widget.exercisesForTest ?? ExerciseCatalog.all.where((e) => e.active).toList();
    final theme = Theme.of(context);

    // True empty catalog
    if (allExercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exercise Library'),
          centerTitle: false,
        ),
        body: _EmptyState(theme: theme),
      );
    }

    final filtered = applyExerciseLibraryFilter(allExercises, _filter);
    final hasActiveFilters = _filter.hasActiveFilters;
    final hasSearch = _filter.hasSearch;
    final activeCount = _filter.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: 'Search exercises',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasSearch
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          // Quick filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('No equipment'),
                    selected: _filter.noEquipment,
                    onSelected: (v) => setState(() => _filter = _filter.copyWith(noEquipment: v)),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Standing only'),
                    selected: _filter.standingOnly,
                    onSelected: (v) => setState(() => _filter = _filter.copyWith(standingOnly: v)),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Low impact'),
                    selected: _filter.lowImpact,
                    onSelected: (v) => setState(() => _filter = _filter.copyWith(lowImpact: v)),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Quiet'),
                    selected: _filter.quiet,
                    onSelected: (v) => setState(() => _filter = _filter.copyWith(quiet: v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Filter controls + result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(hasActiveFilters ? 'Filters ($activeCount)' : 'Filters'),
                ),
                const SizedBox(width: 8),
                if (hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                if (hasActiveFilters && hasSearch)
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear all'),
                  ),
                const Spacer(),
                Text(
                  '${filtered.length} exercises',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // List / No results
          Expanded(
            child: filtered.isEmpty
                ? _NoResultsState(
                    theme: theme,
                    hasActiveFilters: hasActiveFilters,
                    hasSearch: hasSearch,
                    onClearFilters: _clearFilters,
                    onClearAll: (hasActiveFilters || hasSearch) ? _clearAll : null,
                  )
                : ListView.separated(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return ExerciseListTile(
                        exercise: exercise,
                        onTap: () => context.push(
                          AppRoutes.exerciseDetail(exercise.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises available',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The exercise catalog is currently empty. Please check back later.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({
    required this.theme,
    required this.hasActiveFilters,
    required this.hasSearch,
    required this.onClearFilters,
    this.onClearAll,
  });

  final ThemeData theme;
  final bool hasActiveFilters;
  final bool hasSearch;
  final VoidCallback onClearFilters;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your search or filters.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (hasActiveFilters)
              FilledButton(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
            if (hasSearch && !hasActiveFilters && onClearAll != null)
              FilledButton(
                onPressed: onClearAll,
                child: const Text('Clear search'),
              ),
            if (hasSearch && hasActiveFilters && onClearAll != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onClearAll,
                child: const Text('Clear all'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
