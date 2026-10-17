import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
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
  late List<Exercise> _allExercises;
  ExerciseLibraryFilter _filter = const ExerciseLibraryFilter();

  @override
  void initState() {
    super.initState();
    _readCatalog();
    _searchController = TextEditingController(text: _filter.searchQuery);
  }

  void _readCatalog() {
    _allExercises = widget.exercisesForTest ??
        ExerciseCatalog.all.where((e) => e.active).toList(growable: false);
  }

  @override
  void didUpdateWidget(covariant ExerciseLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercisesForTest != widget.exercisesForTest) _readCatalog();
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
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.standard(context)),
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
    final allExercises = _allExercises;
    final theme = Theme.of(context);
    final v = FitFlowVisualV2.of(context);

    final libraryAppBar = AppBar(
      title: Text(context.l10n.exerciseLibraryTitle,
          style: theme.textTheme.titleLarge),
      centerTitle: false,
      toolbarHeight:
          56 + (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 3) * 48,
      backgroundColor: v.page,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    );

    // True empty catalog
    if (allExercises.isEmpty) {
      return Scaffold(
        backgroundColor: v.page,
        appBar: libraryAppBar,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(child: _EmptyState(theme: theme)),
        ),
      );
    }

    final filtered = applyExerciseLibraryFilter(allExercises, _filter);
    final hasActiveFilters = _filter.hasActiveFilters;
    final hasSearch = _filter.hasSearch;
    final activeCount = _filter.activeFilterCount;

    return Scaffold(
      backgroundColor: v.page,
      appBar: libraryAppBar,
      body: SafeArea(
        top: false,
        child: FitFlowMaxWidth(
          child: CustomScrollView(
            key: const ValueKey('exercise_library_scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      key: const ValueKey('exercise_library_search'),
                      controller: _searchController,
                      onChanged: _updateSearch,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      cursorColor: FitFlowTheme.of(context).brand,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: context.l10n.searchExercises,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: hasSearch
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                                tooltip: context.l10n.clearSearch,
                              )
                            : null,
                        filled: true,
                        fillColor: v.tint,
                        isDense: false,
                        constraints: const BoxConstraints(minHeight: 52),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: FitFlowRadius.mediumBorder,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: FitFlowRadius.mediumBorder,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: FitFlowRadius.mediumBorder,
                          borderSide: BorderSide(
                            color: FitFlowTheme.of(context).brand,
                            width: 2,
                          ),
                        ),
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
                            side: BorderSide.none,
                            backgroundColor: v.tint,
                            showCheckmark: true,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            chipAnimationStyle: ChipAnimationStyle(
                                selectAnimation: AnimationStyle(
                                    duration: SystemMotion.micro(context),
                                    reverseDuration:
                                        SystemMotion.micro(context))),
                            label: Text(context.l10n.quickNoEquipment),
                            selected: _filter.noEquipment,
                            onSelected: (v) => setState(() =>
                                _filter = _filter.copyWith(noEquipment: v)),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            side: BorderSide.none,
                            backgroundColor: v.tint,
                            showCheckmark: true,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            chipAnimationStyle: ChipAnimationStyle(
                                selectAnimation: AnimationStyle(
                                    duration: SystemMotion.micro(context),
                                    reverseDuration:
                                        SystemMotion.micro(context))),
                            label: Text(context.l10n.trainingStanding),
                            selected: _filter.standingOnly,
                            onSelected: (v) => setState(() =>
                                _filter = _filter.copyWith(standingOnly: v)),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            side: BorderSide.none,
                            backgroundColor: v.tint,
                            showCheckmark: true,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            chipAnimationStyle: ChipAnimationStyle(
                                selectAnimation: AnimationStyle(
                                    duration: SystemMotion.micro(context),
                                    reverseDuration:
                                        SystemMotion.micro(context))),
                            label: Text(context.l10n.trainingLowImpact),
                            selected: _filter.lowImpact,
                            onSelected: (v) => setState(
                                () => _filter = _filter.copyWith(lowImpact: v)),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            side: BorderSide.none,
                            backgroundColor: v.tint,
                            showCheckmark: true,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            chipAnimationStyle: ChipAnimationStyle(
                                selectAnimation: AnimationStyle(
                                    duration: SystemMotion.micro(context),
                                    reverseDuration:
                                        SystemMotion.micro(context))),
                            label: Text(context.l10n.quickQuiet),
                            selected: _filter.quiet,
                            onSelected: (v) => setState(
                                () => _filter = _filter.copyWith(quiet: v)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.xs),
                  // A single unboxed action line keeps the list hierarchy quiet.
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: FitFlowSpace.md),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: v.page,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FitFlowSpace.xs,
                          vertical: FitFlowSpace.xxs,
                        ),
                        // Wrap keeps controls reachable at compact widths and
                        // larger text without changing their actions or ordering.
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: FitFlowSpace.xs,
                          runSpacing: FitFlowSpace.xxs,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                side: BorderSide.none,
                                backgroundColor: v.tint,
                              ),
                              onPressed: _openFilterSheet,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: Text(hasActiveFilters
                                  ? context.l10n.filtersWithCount(activeCount)
                                  : context.l10n.filters),
                            ),
                            if (hasActiveFilters)
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: _clearFilters,
                                child: Text(context.l10n.trainingClearFilters),
                              ),
                            if (hasActiveFilters && hasSearch)
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: _clearAll,
                                child: Text(context.l10n.trainingClearAll),
                              ),
                            Text(
                              context.l10n
                                  .trainingExerciseCount(filtered.length),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: FitFlowTheme.of(context).textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.sm),
                  if (_filter.movementPatterns.isNotEmpty ||
                      _filter.difficulties.isNotEmpty ||
                      _filter.equipment.isNotEmpty ||
                      _filter.positions.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Text(
                            [
                              ..._filter.movementPatterns.map(
                                  (v) => movementPatternLabel(context.l10n, v)),
                              ..._filter.difficulties.map((v) =>
                                  trainingDifficultyLabel(context.l10n, v)),
                              ..._filter.equipment
                                  .map((v) => equipmentLabel(context.l10n, v)),
                              ..._filter.positions.map((v) => v.label),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall)),
                ],
              )),
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                    child: _NoResultsState(
                  theme: theme,
                  hasActiveFilters: hasActiveFilters,
                  hasSearch: hasSearch,
                  onClearFilters: _clearFilters,
                  onClearAll:
                      (hasActiveFilters || hasSearch) ? _clearAll : null,
                ))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    FitFlowSpace.md,
                    0,
                    FitFlowSpace.md,
                    0,
                  ),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: FitFlowTheme.of(context).divider,
                    ),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return ExerciseListTile(
                        key: ValueKey(exercise.id),
                        exercise: exercise,
                        onTap: () =>
                            context.push(AppRoutes.exerciseDetail(exercise.id)),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: FitFlowSpace.xl)),
            ],
          ),
        ),
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
              context.l10n.trainingCatalogEmpty,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.trainingCatalogEmptyHelp,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              context.l10n.trainingNoResults,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.trainingNoResultsHelp,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (hasActiveFilters)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onClearFilters,
                child: Text(context.l10n.trainingClearFilters),
              ),
            if (hasSearch && !hasActiveFilters && onClearAll != null)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onClearAll,
                child: Text(context.l10n.clearSearch),
              ),
            if (hasSearch && hasActiveFilters && onClearAll != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onClearAll,
                child: Text(context.l10n.trainingClearAll),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
