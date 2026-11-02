import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'exercise_body_focus.dart';
import 'exercise_detail_screen.dart';
import 'widgets/skill_paths_panel.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_filter_sheet.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:flutter/material.dart';

/// Exercise Library with instant search, filters, quick filters, live count.
/// Scoped Slate + Citrus presentation, identical tokens to the Workouts hub.
class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen(
      {super.key,
      this.exercisesForTest,
      this.initialSkills = false,
      this.initialFamilyId});

  /// Optional override for testing empty-catalog handling.
  /// When null, uses [ExerciseCatalog.all] filtered to active exercises.
  final List<Exercise>? exercisesForTest;
  final bool initialSkills;
  final String? initialFamilyId;

  @override
  Widget build(BuildContext context) => WorkoutsTheme(
      child: _ExerciseLibraryBody(
          exercisesForTest: exercisesForTest,
          initialSkills: initialSkills,
          initialFamilyId: initialFamilyId));
}

class _ExerciseLibraryBody extends StatefulWidget {
  const _ExerciseLibraryBody(
      {this.exercisesForTest,
      this.initialSkills = false,
      this.initialFamilyId});

  final List<Exercise>? exercisesForTest;
  final bool initialSkills;
  final String? initialFamilyId;

  @override
  State<_ExerciseLibraryBody> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<_ExerciseLibraryBody> {
  late final TextEditingController _searchController;
  late List<Exercise> _allExercises;
  ExerciseLibraryFilter _filter = const ExerciseLibraryFilter();
  ExerciseBodyFocus _focus = ExerciseBodyFocus.all;
  late bool _skills;
  String? _selectedFamily;

  @override
  void initState() {
    super.initState();
    _readCatalog();
    _skills = widget.initialSkills;
    _selectedFamily = widget.initialFamilyId;
    _searchController = TextEditingController(text: _filter.searchQuery);
  }

  void _readCatalog() {
    _allExercises = widget.exercisesForTest ??
        ExerciseCatalog.all.where((e) => e.active).toList(growable: false);
  }

  @override
  void didUpdateWidget(covariant _ExerciseLibraryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercisesForTest != widget.exercisesForTest) _readCatalog();
    if (oldWidget.initialSkills != widget.initialSkills ||
        oldWidget.initialFamilyId != widget.initialFamilyId) {
      _skills = widget.initialSkills;
      _selectedFamily = widget.initialFamilyId;
    }
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
      _focus = ExerciseBodyFocus.all;
    });
  }

  void _clearAll() {
    _searchController.clear();
    setState(() {
      _filter = _filter.clearAll();
      _focus = ExerciseBodyFocus.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = _allExercises;
    final theme = Theme.of(context);
    final v = FitFlowVisualV2.of(context);

    final libraryAppBar = AppBar(
      title: Text(context.l10n.exerciseLibraryTitle),
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

    final filtered = applyExerciseLibraryFilter(allExercises, _filter)
        .where(_focus.matches)
        .toList();
    final hasActiveFilters =
        _filter.hasActiveFilters || _focus != ExerciseBodyFocus.all;
    final hasSearch = _filter.hasSearch;
    return Scaffold(
      backgroundColor: v.page,
      appBar: libraryAppBar,
      body: SafeArea(
          top: false,
          child: FitFlowMaxWidth(
              child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(children: [
                  Expanded(
                      child: _tab(context.l10n.libraryExercisesTab, false)),
                  const SizedBox(width: 8),
                  Expanded(child: _tab(context.l10n.trainingSkills, true)),
                ])),
            Expanded(
                child: _skills
                    ? SkillPathsPanel(
                        key: ValueKey(_selectedFamily),
                        initialFamilyId: _selectedFamily,
                        onFamilySelected: (value) => _selectedFamily = value)
                    : CustomScrollView(
                        key: const ValueKey('exercise_library_scroll'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverToBoxAdapter(
                              child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    key: const ValueKey(
                                        'exercise_library_search'),
                                    controller: _searchController,
                                    onChanged: _updateSearch,
                                    decoration: InputDecoration(
                                      hintText: context.l10n.searchExercises,
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: hasSearch
                                          ? IconButton(
                                              onPressed: _clearSearch,
                                              tooltip: context.l10n.clearSearch,
                                              icon: const Icon(Icons.close))
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                            context.l10n.libraryFocusBody,
                                            style:
                                                theme.textTheme.titleMedium)),
                                    OutlinedButton.icon(
                                        onPressed: _openFilterSheet,
                                        icon: const Icon(Icons.tune, size: 18),
                                        label: Text(_filter.hasActiveFilters
                                            ? context.l10n.filtersWithCount(
                                                _filter.activeFilterCount)
                                            : context.l10n.filters)),
                                  ]),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(children: [
                                        for (final focus
                                            in ExerciseBodyFocus.values)
                                          Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .only(end: 8),
                                              child: ChoiceChip(
                                                key: ValueKey(
                                                    'body_focus_${focus.name}'),
                                                label: Text(focus.label),
                                                selected: _focus == focus,
                                                onSelected: (_) => setState(
                                                    () => _focus = focus),
                                              )),
                                      ])),
                                  const SizedBox(height: 8),
                                  Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                            context.l10n.trainingExerciseCount(
                                                filtered.length),
                                            style: theme.textTheme.bodySmall),
                                        if (hasActiveFilters)
                                          TextButton(
                                              onPressed: _clearFilters,
                                              child: Text(context
                                                  .l10n.trainingClearFilters)),
                                      ]),
                                ]),
                          )),
                          if (filtered.isEmpty)
                            SliverToBoxAdapter(
                                child: _NoResultsState(
                                    theme: theme,
                                    hasActiveFilters: hasActiveFilters,
                                    hasSearch: hasSearch,
                                    onClearFilters: _clearFilters,
                                    onClearAll: _clearAll))
                          else
                            SliverPadding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverList.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      ExerciseListTile(
                                    key: ValueKey(filtered[index].id),
                                    exercise: filtered[index],
                                    onTap: () => showExerciseGuide(
                                        context, filtered[index].id),
                                  ),
                                )),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      )),
          ]))),
    );
  }

  Widget _tab(String label, bool skills) => Semantics(
        selected: _skills == skills,
        child: _skills == skills
            ? FilledButton(onPressed: () {}, child: Text(label))
            : OutlinedButton(
                onPressed: () => setState(() => _skills = skills),
                child: Text(label)),
      );
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
