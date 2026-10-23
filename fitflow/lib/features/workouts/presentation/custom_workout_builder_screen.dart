import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_limits.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_section_classifier.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_validator.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Scoped Slate + Citrus wrapper: placing the body below the theme means the
/// state's discard dialog, add-exercise sheet and prescription editor inherit
/// the same tokens (they are presented from the state's own context).
class CustomWorkoutBuilderScreen extends StatelessWidget {
  const CustomWorkoutBuilderScreen({super.key, this.workoutId});

  final String? workoutId;

  @override
  Widget build(BuildContext context) =>
      WorkoutsTheme(child: _CustomWorkoutBuilderBody(workoutId: workoutId));
}

class _CustomWorkoutBuilderBody extends ConsumerStatefulWidget {
  const _CustomWorkoutBuilderBody({this.workoutId});

  final String? workoutId;

  @override
  ConsumerState<_CustomWorkoutBuilderBody> createState() =>
      _CustomWorkoutBuilderScreenState();
}

class _CustomWorkoutBuilderScreenState
    extends ConsumerState<_CustomWorkoutBuilderBody> {
  final _nameController = TextEditingController();
  WorkoutDuration? _selectedDuration;
  List<CustomWorkoutExerciseEntry> _warmup = [];
  List<CustomWorkoutExerciseEntry> _main = [];
  List<CustomWorkoutExerciseEntry> _cooldown = [];

  String? _editingId;
  DateTime? _originalCreatedAt;
  CustomWorkoutTemplate? _originalTemplate;
  bool _isSaving = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfEditing());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadIfEditing() async {
    if (widget.workoutId == null) {
      setState(() {
        _selectedDuration = WorkoutDuration.fifteenMinutes;
      });
      return;
    }

    final controller = ref.read(customWorkoutControllerProvider.notifier);
    final template = await controller.findById(widget.workoutId!);
    if (template == null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Workout not found.')));
      if (context.mounted) context.go(AppRoutes.workouts);
      return;
    }
    if (template != null && mounted) {
      setState(() {
        _editingId = template.id;
        _originalCreatedAt = template.createdAt;
        _originalTemplate = template;
        _nameController.text = template.name;
        _selectedDuration = template.targetDuration;
        _warmup = List.from(template.warmup);
        _main = List.from(template.main);
        _cooldown = List.from(template.cooldown);
      });
    }
  }

  bool get _isDirty {
    if (_hasSaved) return false;
    if (_originalTemplate == null) {
      return _nameController.text.trim().isNotEmpty ||
          _warmup.isNotEmpty ||
          _main.isNotEmpty ||
          _cooldown.isNotEmpty ||
          _selectedDuration != WorkoutDuration.fifteenMinutes;
    }
    final current = _buildTemplateForComparison();
    return current != _originalTemplate;
  }

  CustomWorkoutTemplate _buildTemplateForComparison() {
    final now = DateTime.now();
    return CustomWorkoutTemplate(
      id: _editingId ?? 'temp',
      name: _nameController.text.trim(),
      targetDuration: _selectedDuration ?? WorkoutDuration.fifteenMinutes,
      createdAt: _originalCreatedAt ?? now,
      updatedAt: now,
      warmup: _warmup,
      main: _main,
      cooldown: _cooldown,
    );
  }

  bool get _isValidForSave {
    final nameError = CustomWorkoutValidator.validateName(_nameController.text);
    final durError = CustomWorkoutValidator.validateDuration(_selectedDuration);
    if (nameError != null || durError != null) return false;
    if (_warmup.isEmpty || _main.isEmpty || _cooldown.isEmpty) return false;
    for (final e in [..._warmup, ..._main, ..._cooldown]) {
      if (e.sets < CustomWorkoutLimits.setsMin ||
          e.sets > CustomWorkoutLimits.setsMax) {
        return false;
      }
      if (e.restBetweenSets.inSeconds < CustomWorkoutLimits.restMinSec ||
          e.restBetweenSets.inSeconds > CustomWorkoutLimits.restMaxSec) {
        return false;
      }
      if (e.isTimed) {
        final d = e.workDuration!.inSeconds;
        if (d < CustomWorkoutLimits.timedWorkMinSec ||
            d > CustomWorkoutLimits.timedWorkMaxSec) {
          return false;
        }
      } else {
        final r = e.repsPerSet;
        if (r == null ||
            r < CustomWorkoutLimits.repsMin ||
            r > CustomWorkoutLimits.repsMax) {
          return false;
        }
      }
    }
    final allIds =
        [..._warmup, ..._main, ..._cooldown].map((e) => e.exerciseId).toList();
    if (allIds.toSet().length != allIds.length) return false;
    return true;
  }

  Future<bool> _handlePop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      animationStyle: SystemMotion.overlay(context),
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep editing')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final trimmedName = _nameController.text.trim();
    final duration = _selectedDuration;

    if (trimmedName.isEmpty || duration == null) {
      setState(() => _isSaving = false);
      return;
    }

    final now = DateTime.now();
    final id = _editingId ?? CustomWorkoutIdGenerator.generate();
    final createdAt = _originalCreatedAt ?? now;

    final template = CustomWorkoutTemplate(
      id: id,
      name: trimmedName,
      targetDuration: duration,
      createdAt: createdAt,
      updatedAt: now,
      warmup: _warmup,
      main: _main,
      cooldown: _cooldown,
    );

    final catalogById = ExerciseCatalog.byIdMap;
    final validation = CustomWorkoutValidator.validateTemplate(
        template: template, catalogById: catalogById);
    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validation.issues.first)),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final controller = ref.read(customWorkoutControllerProvider.notifier);
    bool success;
    if (_editingId == null) {
      success = await controller.create(template);
    } else {
      success = await controller.update(template);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save this workout. Try again.")),
      );
      return;
    }

    _hasSaved = true;
    if (_editingId == null) {
      context.go(AppRoutes.customWorkoutDetail(id));
    } else {
      context.go(AppRoutes.customWorkoutDetail(id));
    }
  }

  void _addExercise(WorkoutSectionType sectionType) async {
    final userProfile = ref.read(userFitnessProfileProvider).value;
    final capabilityProfile = ref.read(capabilityProfileProvider).value;
    if (userProfile == null || capabilityProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not available.')));
      return;
    }

    final existingIds =
        {..._warmup, ..._main, ..._cooldown}.map((e) => e.exerciseId).toSet();

    final result = await showModalBottomSheet<CustomWorkoutExerciseEntry>(
      context: context,
      sheetAnimationStyle: SystemMotion.overlay(context),
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _AddExerciseSheet(
          sectionType: sectionType,
          existingIds: existingIds,
          userProfile: userProfile,
          capabilityProfile: capabilityProfile,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        switch (sectionType) {
          case WorkoutSectionType.warmup:
            _warmup = List.from(_warmup)..add(result);
            break;
          case WorkoutSectionType.main:
            _main = List.from(_main)..add(result);
            break;
          case WorkoutSectionType.cooldown:
            _cooldown = List.from(_cooldown)..add(result);
            break;
        }
      });
    }
  }

  void _editPrescription(
      CustomWorkoutExerciseEntry entry, WorkoutSectionType sectionType) async {
    final catalogById = ExerciseCatalog.byIdMap;
    final exercise = catalogById[entry.exerciseId];
    if (exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise not found in catalog.')));
      return;
    }

    final updated = await showDialog<CustomWorkoutExerciseEntry>(
      context: context,
      animationStyle: SystemMotion.overlay(context),
      builder: (ctx) =>
          _PrescriptionEditorDialog(entry: entry, exercise: exercise),
    );

    if (updated != null && mounted) {
      setState(() {
        List<CustomWorkoutExerciseEntry> targetList;
        switch (sectionType) {
          case WorkoutSectionType.warmup:
            targetList = _warmup;
            break;
          case WorkoutSectionType.main:
            targetList = _main;
            break;
          case WorkoutSectionType.cooldown:
            targetList = _cooldown;
            break;
        }
        final idx = targetList
            .indexWhere((e) => e.exerciseId == entry.exerciseId && e == entry);
        final effectiveIdx = idx != -1
            ? idx
            : targetList.indexWhere((e) => e.exerciseId == entry.exerciseId);
        if (effectiveIdx != -1) {
          final newList = List<CustomWorkoutExerciseEntry>.from(targetList);
          newList[effectiveIdx] = updated;
          switch (sectionType) {
            case WorkoutSectionType.warmup:
              _warmup = newList;
              break;
            case WorkoutSectionType.main:
              _main = newList;
              break;
            case WorkoutSectionType.cooldown:
              _cooldown = newList;
              break;
          }
        }
      });
    }
  }

  void _removeExercise(
      CustomWorkoutExerciseEntry entry, WorkoutSectionType sectionType) {
    setState(() {
      switch (sectionType) {
        case WorkoutSectionType.warmup:
          _warmup = _warmup.where((e) => e != entry).toList();
          break;
        case WorkoutSectionType.main:
          _main = _main.where((e) => e != entry).toList();
          break;
        case WorkoutSectionType.cooldown:
          _cooldown = _cooldown.where((e) => e != entry).toList();
          break;
      }
    });
  }

  void _moveUp(int index, WorkoutSectionType type) {
    if (index <= 0) return;
    setState(() {
      List<CustomWorkoutExerciseEntry> list;
      switch (type) {
        case WorkoutSectionType.warmup:
          list = _warmup;
          break;
        case WorkoutSectionType.main:
          list = _main;
          break;
        case WorkoutSectionType.cooldown:
          list = _cooldown;
          break;
      }
      final newList = List<CustomWorkoutExerciseEntry>.from(list);
      final item = newList.removeAt(index);
      newList.insert(index - 1, item);
      switch (type) {
        case WorkoutSectionType.warmup:
          _warmup = newList;
          break;
        case WorkoutSectionType.main:
          _main = newList;
          break;
        case WorkoutSectionType.cooldown:
          _cooldown = newList;
          break;
      }
    });
  }

  void _moveDown(int index, WorkoutSectionType type) {
    setState(() {
      List<CustomWorkoutExerciseEntry> list;
      switch (type) {
        case WorkoutSectionType.warmup:
          list = _warmup;
          break;
        case WorkoutSectionType.main:
          list = _main;
          break;
        case WorkoutSectionType.cooldown:
          list = _cooldown;
          break;
      }
      if (index >= list.length - 1) return;
      final newList = List<CustomWorkoutExerciseEntry>.from(list);
      final item = newList.removeAt(index);
      newList.insert(index + 1, item);
      switch (type) {
        case WorkoutSectionType.warmup:
          _warmup = newList;
          break;
        case WorkoutSectionType.main:
          _main = newList;
          break;
        case WorkoutSectionType.cooldown:
          _cooldown = newList;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.workoutId != null;
    final visual = FitFlowVisualV2.of(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final titleScale = MediaQuery.textScalerOf(context).scale(16);
    final largeText = titleScale > 20;
    final showToolbarSave = viewportWidth >= 420 && !largeText;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: visual.page,
        appBar: AppBar(
          backgroundColor: visual.page,
          scrolledUnderElevation: 0,
          toolbarHeight: largeText ? (titleScale > 28 ? 104 : 80) : null,
          title: Semantics(
            header: true,
            child: Text(isEditing ? 'Edit workout' : context.l10n.trainingCreate),
          ),
          actions: [
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.all(FitFlowSpace.md),
                child: Tooltip(
                  message: context.l10n.utilitySaving,
                  excludeFromSemantics: true,
                  child: Semantics(
                    label: context.l10n.utilitySaving,
                    liveRegion: true,
                    child: const ExcludeSemantics(
                        child: Icon(Icons.hourglass_top)),
                  ),
                ),
              )
            else if (showToolbarSave)
              TextButton(
                onPressed: _isValidForSave ? _save : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, SystemMotion.minTouchTarget),
                ),
                child: const Text('Save'),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: viewportWidth < 360
                  ? FitFlowSpace.md
                  : FitFlowSpace.screenHorizontal,
              vertical: FitFlowSpace.md,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Workout name',
                            hintText: 'e.g., Morning Strength',
                            errorText: CustomWorkoutValidator.validateName(
                                            _nameController.text) !=
                                        null &&
                                    _nameController.text.isNotEmpty
                                ? CustomWorkoutValidator.validateName(
                                    _nameController.text)
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: FitFlowRadius.mediumBorder,
                            ),
                          ),
                          maxLength: CustomWorkoutLimits.nameMaxLength,
                        ),
                        const SizedBox(height: FitFlowSpace.sm),
                        Semantics(
                          header: true,
                          child: Text(
                            context.l10n.flowTargetLabel,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: FitFlowSpace.xs),
                        Wrap(
                          spacing: FitFlowSpace.xs,
                          runSpacing: FitFlowSpace.xs,
                          children: [
                            for (final dur in WorkoutDuration.values)
                              ChoiceChip(
                                label: Text(dur.label),
                                selected: _selectedDuration == dur,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedDuration = dur);
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: FitFlowSpace.md),
                    _SectionEditor(
                      title: 'Warm-up',
                      type: WorkoutSectionType.warmup,
                      entries: _warmup,
                      onAdd: () => _addExercise(WorkoutSectionType.warmup),
                      onEdit: (e) =>
                          _editPrescription(e, WorkoutSectionType.warmup),
                      onRemove: (e) =>
                          _removeExercise(e, WorkoutSectionType.warmup),
                      onMoveUp: (i) => _moveUp(i, WorkoutSectionType.warmup),
                      onMoveDown: (i) =>
                          _moveDown(i, WorkoutSectionType.warmup),
                    ),
                    const SizedBox(height: FitFlowSpace.sm),
                    _SectionEditor(
                      title: 'Main',
                      type: WorkoutSectionType.main,
                      entries: _main,
                      onAdd: () => _addExercise(WorkoutSectionType.main),
                      onEdit: (e) =>
                          _editPrescription(e, WorkoutSectionType.main),
                      onRemove: (e) =>
                          _removeExercise(e, WorkoutSectionType.main),
                      onMoveUp: (i) => _moveUp(i, WorkoutSectionType.main),
                      onMoveDown: (i) => _moveDown(i, WorkoutSectionType.main),
                    ),
                    const SizedBox(height: FitFlowSpace.sm),
                    _SectionEditor(
                      title: 'Cool-down',
                      type: WorkoutSectionType.cooldown,
                      entries: _cooldown,
                      onAdd: () => _addExercise(WorkoutSectionType.cooldown),
                      onEdit: (e) =>
                          _editPrescription(e, WorkoutSectionType.cooldown),
                      onRemove: (e) =>
                          _removeExercise(e, WorkoutSectionType.cooldown),
                      onMoveUp: (i) => _moveUp(i, WorkoutSectionType.cooldown),
                      onMoveDown: (i) =>
                          _moveDown(i, WorkoutSectionType.cooldown),
                    ),
                    const SizedBox(height: FitFlowSpace.lg),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          SystemMotion.minTouchTarget,
                        ),
                      ),
                      onPressed: _isValidForSave && !_isSaving ? _save : null,
                      child:
                          Text(isEditing ? 'Save changes' : 'Create workout'),
                    ),
                    const SizedBox(height: FitFlowSpace.xs),
                    if (!_isValidForSave)
                      Text(
                        'Add a name, target duration, and at least one exercise per section.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionEditor extends StatelessWidget {
  const _SectionEditor({
    required this.title,
    required this.type,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final String title;
  final WorkoutSectionType type;
  final List<CustomWorkoutExerciseEntry> entries;
  final VoidCallback onAdd;
  final void Function(CustomWorkoutExerciseEntry) onEdit;
  final void Function(CustomWorkoutExerciseEntry) onRemove;
  final void Function(int) onMoveUp;
  final void Function(int) onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogById = ExerciseCatalog.byIdMap;

    return Padding(
      key: Key('custom-workout-section-${type.name}'),
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380 ||
                  MediaQuery.textScalerOf(context).scale(16) > 20;
              final heading = Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              );
              final addButton = TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, SystemMotion.minTouchTarget),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add exercise'),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    const SizedBox(height: FitFlowSpace.xxs),
                    addButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: FitFlowSpace.sm),
          if (entries.isEmpty)
            Text(
              'No exercises yet. Tap Add exercise.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final Exercise? exercise = catalogById[entry.exerciseId];
                final isMissing = exercise == null;
                final workloadText = entry.isTimed
                    ? '${entry.sets} × ${entry.workDuration!.inSeconds}s'
                    : '${entry.sets} × ${entry.repsPerSet} reps';
                final restText = '${entry.restBetweenSets.inSeconds}s rest';

                return Padding(
                  key: ValueKey(
                    'custom-workout-entry-${type.name}-$index-${entry.exerciseId}',
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMissing) ...[
                            FitFlowExerciseImage.thumbnail(
                              exerciseId: exercise.id,
                              width: 64,
                              height: 64,
                            ),
                            const SizedBox(width: FitFlowSpace.sm),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isMissing)
                                  Text(
                                    'Missing: ${entry.exerciseId}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.error,
                                    ),
                                  )
                                else
                                  Text(
                                    exercise.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (!isMissing) ...[
                                  const SizedBox(height: FitFlowSpace.xxs),
                                  Text(
                                    _customExerciseMetadata(context, exercise),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: FitFlowSpace.xxs),
                                  Text(
                                    '$workloadText • $restText',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: FitFlowSpace.xxs),
                      Wrap(
                        spacing: FitFlowSpace.xs,
                        runSpacing: FitFlowSpace.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Move up',
                            onPressed: index > 0 ? () => onMoveUp(index) : null,
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: 'Move down',
                            onPressed: index < entries.length - 1
                                ? () => onMoveDown(index)
                                : null,
                            icon: const Icon(Icons.arrow_downward),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(
                                64,
                                SystemMotion.minTouchTarget,
                              ),
                            ),
                            onPressed: isMissing ? null : () => onEdit(entry),
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(
                                64,
                                SystemMotion.minTouchTarget,
                              ),
                            ),
                            onPressed: () => onRemove(entry),
                            child: const Text('Remove'),
                          ),
                          if (isMissing)
                            Text(
                              'Exercise no longer available',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.error),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet({
    required this.sectionType,
    required this.existingIds,
    required this.userProfile,
    required this.capabilityProfile,
  });

  final WorkoutSectionType sectionType;
  final Set<String> existingIds;
  final UserFitnessProfile userProfile;
  final CapabilityProfile capabilityProfile;

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> _filteredExercises() {
    final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
      userProfile: widget.userProfile,
      capabilityProfile: widget.capabilityProfile,
    );

    final all = ExerciseCatalog.all.where((ex) {
      if (!ex.active) return false;
      if (!ex.isValid) return false;
      final section = CustomWorkoutSectionClassifier.classify(ex);
      if (section != widget.sectionType) return false;
      if (widget.existingIds.contains(ex.id)) return false;
      final pres = WorkoutExercisePrescription.fromExerciseDefaults(ex);
      if (pres == null) return false;
      // Canonical eligibility for ALL sections (engine already handles capability only for trainable patterns)
      final result = ExerciseEligibilityEngine.evaluate(ex, eligibilityContext);
      if (!result.eligible) return false;
      if (_searchQuery.isNotEmpty) {
        if (!ex.name.toLowerCase().contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredExercises();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => CustomScrollView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(FitFlowSpace.md),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                        header: true,
                        child: Text(
                          context.l10n.part6AddExercise(
                            sectionLabel(context.l10n, widget.sectionType),
                          ),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        )),
                    const SizedBox(height: FitFlowSpace.sm),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: context.l10n.searchExercises,
                        hintText: 'Search by name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: FitFlowRadius.mediumBorder,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                FitFlowSpace.md,
                0,
                FitFlowSpace.md,
                FitFlowSpace.md,
              ),
              sliver: filtered.isEmpty
                  ? SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Text(
                            _searchQuery.isEmpty
                                ? context.l10n.part6NoSectionExercises
                                : context.l10n.trainingNoResults,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: _searchController.clear,
                              child: Text(context.l10n.clearSearch),
                            ),
                        ],
                      ),
                    )
                  : SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ex = filtered[index];
                        final pres =
                            WorkoutExercisePrescription.fromExerciseDefaults(
                          ex,
                        )!;
                        final workload = ex.exerciseType.name == 'reps'
                            ? '${pres.sets} × ${pres.repsPerSet} reps'
                            : '${pres.sets} × ${pres.workDuration!.inSeconds}s';
                        final equipment = ex.requiredEquipment.isEmpty
                            ? context.l10n.flowNoEquipment
                            : ex.requiredEquipment
                                .map((e) => equipmentLabel(context.l10n, e))
                                .join(', ');

                        return ListTile(
                          isThreeLine: true,
                          minLeadingWidth: 64,
                          horizontalTitleGap: FitFlowSpace.sm,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: FitFlowSpace.sm,
                          ),
                          leading: FitFlowExerciseImage.thumbnail(
                            exerciseId: ex.id,
                            width: 64,
                            height: 64,
                          ),
                          title: Text(
                            ex.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: FitFlowSpace.xxs),
                              Text(
                                '${_customExerciseMetadata(context, ex)} · $equipment',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: FitFlowSpace.xxs),
                              Text(
                                workload,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: const ExcludeSemantics(
                            child: Icon(Icons.add_circle_outline),
                          ),
                          onTap: () {
                            final entry = CustomWorkoutExerciseEntry(
                              exerciseId: ex.id,
                              sets: pres.sets,
                              repsPerSet: pres.repsPerSet,
                              workDuration: pres.workDuration,
                              restBetweenSets: pres.restBetweenSets,
                            );
                            Navigator.of(context).pop(entry);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionEditorDialog extends StatefulWidget {
  const _PrescriptionEditorDialog(
      {required this.entry, required this.exercise});

  final CustomWorkoutExerciseEntry entry;
  final Exercise exercise;

  @override
  State<_PrescriptionEditorDialog> createState() =>
      _PrescriptionEditorDialogState();
}

class _PrescriptionEditorDialogState extends State<_PrescriptionEditorDialog> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _workController;
  late final TextEditingController _restController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(text: widget.entry.sets.toString());
    _repsController =
        TextEditingController(text: widget.entry.repsPerSet?.toString() ?? '');
    _workController = TextEditingController(
        text: widget.entry.workDuration?.inSeconds.toString() ?? '');
    _restController = TextEditingController(
        text: widget.entry.restBetweenSets.inSeconds.toString());
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _workController.dispose();
    _restController.dispose();
    super.dispose();
  }

  bool get _isTimed => widget.entry.isTimed;

  String? _validate() {
    final sets = int.tryParse(_setsController.text.trim());
    if (sets == null ||
        sets < CustomWorkoutLimits.setsMin ||
        sets > CustomWorkoutLimits.setsMax) {
      return 'Sets must be ${CustomWorkoutLimits.setsMin}..${CustomWorkoutLimits.setsMax}';
    }
    final rest = int.tryParse(_restController.text.trim());
    if (rest == null ||
        rest < CustomWorkoutLimits.restMinSec ||
        rest > CustomWorkoutLimits.restMaxSec) {
      return 'Rest must be ${CustomWorkoutLimits.restMinSec}..${CustomWorkoutLimits.restMaxSec} sec';
    }
    if (_isTimed) {
      final work = int.tryParse(_workController.text.trim());
      if (work == null ||
          work < CustomWorkoutLimits.timedWorkMinSec ||
          work > CustomWorkoutLimits.timedWorkMaxSec) {
        return 'Work must be ${CustomWorkoutLimits.timedWorkMinSec}..${CustomWorkoutLimits.timedWorkMaxSec} sec';
      }
    } else {
      final reps = int.tryParse(_repsController.text.trim());
      if (reps == null ||
          reps < CustomWorkoutLimits.repsMin ||
          reps > CustomWorkoutLimits.repsMax) {
        return 'Reps must be ${CustomWorkoutLimits.repsMin}..${CustomWorkoutLimits.repsMax}';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _validate();

    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: FitFlowRadius.cardBorder),
      title: Semantics(
        header: true,
        child: Text('Edit ${widget.exercise.name}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _setsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sets',
              border: OutlineInputBorder(
                borderRadius: FitFlowRadius.mediumBorder,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (_isTimed)
            TextField(
              controller: _workController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Work seconds',
                border: OutlineInputBorder(
                  borderRadius: FitFlowRadius.mediumBorder,
                ),
              ),
              onChanged: (_) => setState(() {}),
            )
          else
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                border: OutlineInputBorder(
                  borderRadius: FitFlowRadius.mediumBorder,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _restController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Rest seconds',
              border: OutlineInputBorder(
                borderRadius: FitFlowRadius.mediumBorder,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final sets = int.tryParse(_setsController.text.trim()) ??
                  widget.entry.sets;
              final rest = int.tryParse(_restController.text.trim()) ??
                  widget.entry.restBetweenSets.inSeconds;
              String preview;
              if (_isTimed) {
                final work = int.tryParse(_workController.text.trim()) ??
                    widget.entry.workDuration?.inSeconds ??
                    0;
                preview = 'Preview: $sets × $work' 's, $rest' 's rest';
              } else {
                final reps = int.tryParse(_repsController.text.trim()) ??
                    widget.entry.repsPerSet ??
                    0;
                preview = 'Preview: $sets × $reps reps, $rest' 's rest';
              }
              return Text(preview, style: theme.textTheme.bodySmall);
            },
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: error == null
              ? () {
                  final sets = int.parse(_setsController.text.trim());
                  final rest = int.parse(_restController.text.trim());
                  CustomWorkoutExerciseEntry updated;
                  if (_isTimed) {
                    final work = int.parse(_workController.text.trim());
                    updated = CustomWorkoutExerciseEntry(
                      exerciseId: widget.entry.exerciseId,
                      sets: sets,
                      workDuration: Duration(seconds: work),
                      restBetweenSets: Duration(seconds: rest),
                    );
                  } else {
                    final reps = int.parse(_repsController.text.trim());
                    updated = CustomWorkoutExerciseEntry(
                      exerciseId: widget.entry.exerciseId,
                      sets: sets,
                      repsPerSet: reps,
                      restBetweenSets: Duration(seconds: rest),
                    );
                  }
                  Navigator.of(context).pop(updated);
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Presentation-only labels; persisted enum values and eligibility are unchanged.
String _customExerciseMetadata(BuildContext context, Exercise exercise) {
  final l = context.l10n;
  final pattern = exercise.movementPattern;
  return [
    if (pattern != null) movementPatternLabel(l, pattern),
    trainingDifficultyLabel(l, exercise.difficulty),
    exercise.exerciseType == ExerciseType.timed
        ? l.flowTimedWork
        : l.part6RepetitionWork,
  ].join(' · ');
}
