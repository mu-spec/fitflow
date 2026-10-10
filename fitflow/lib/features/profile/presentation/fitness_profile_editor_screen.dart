import 'package:fitflow/features/settings/presentation/widgets/utility_presentation.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/widgets/profile_editor_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Editor for goal, experience, workout time, and environment.
///
/// Changes stay in a local draft until the user explicitly taps
/// `Save changes`; nothing is persisted on selection. Equipment and
/// preferences are edited on their own screens.
class FitnessProfileEditorScreen extends ConsumerStatefulWidget {
  const FitnessProfileEditorScreen({super.key});

  static const String successMessage = 'Fitness profile updated.';

  @override
  ConsumerState<FitnessProfileEditorScreen> createState() =>
      _FitnessProfileEditorScreenState();
}

class _FitnessProfileEditorScreenState
    extends ConsumerState<FitnessProfileEditorScreen> {
  /// Persisted profile the draft was started from.
  UserFitnessProfile? _baseline;

  /// Current in-progress draft; never persisted until an explicit save.
  UserFitnessProfile? _draft;

  bool _saving = false;

  bool get _hasUnsavedChanges {
    final draft = _draft;
    final baseline = _baseline;
    return draft != null && baseline != null && draft != baseline;
  }

  void _update(UserFitnessProfile Function(UserFitnessProfile) change) {
    setState(() {
      _draft = change(_draft!);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final draft = _draft;
    if (draft == null || !_hasUnsavedChanges) return;

    setState(() => _saving = true);
    final saved =
        await ref.read(userFitnessProfileProvider.notifier).saveProfile(draft);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? FitnessProfileEditorScreen.successMessage
                : profileEditorSaveFailedMessage,
          ),
        ),
      );

    if (saved) {
      // The provider now reflects the persisted profile; align the editor so
      // the route is clean to pop without another discard prompt.
      setState(() {
        _baseline = draft;
        _draft = draft;
        _saving = false;
      });
      if (mounted) {
        context.pop();
      }
    } else {
      // Stay on screen; the old persisted profile remains authoritative.
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userFitnessProfileProvider);

    return PopScope(
      canPop: !_hasUnsavedChanges && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _saving) return;
        // No dialog when nothing changed: canPop is true in that case, so the
        // route already popped on its own.
        confirmDiscardEditorChanges(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Fitness profile')),
        body: SafeArea(
          child: profileAsync.when(
            loading: () =>
                FitFlowLoading(label: context.l10n.assessmentLoading),
            error: (error, stackTrace) => SingleChildScrollView(
                child: FitFlowErrorState(
                    title: context.l10n.utilityProfileError,
                    message: context.l10n.utilityRetryBody,
                    action: TextButton(
                        onPressed: () =>
                            ref.invalidate(userFitnessProfileProvider),
                        child: Text(context.l10n.retry)))),
            data: (profile) {
              if (profile == null) {
                return const ProfileEditorMissingState();
              }
              _baseline ??= profile;
              _draft ??= profile;
              final draft = _draft!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: FitFlowLayout.maxReadableWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'These settings shape future adaptive workouts.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(context.l10n.utilityEditorDraft,
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 20),
                        UtilityDisclosure(
                            title: context.l10n.utilityGoal,
                            summary: context.l10n.utilitySelectedValue(
                                fitnessGoalLabel(context.l10n, draft.goal)),
                            children: [
                              for (final goal in FitnessGoal.values)
                                ProfileOptionTile(
                                  enabled: !_saving,
                                  label: fitnessGoalLabel(context.l10n, goal),
                                  selected: draft.goal == goal,
                                  onSelected: () =>
                                      _update((p) => p.copyWith(goal: goal)),
                                ),
                            ]),
                        const SizedBox(height: 12),
                        UtilityDisclosure(
                            title: context.l10n.utilityExperience,
                            summary: context.l10n.utilitySelectedValue(
                                experienceLabel(
                                    context.l10n, draft.experience)),
                            children: [
                              for (final level in ExperienceLevel.values)
                                ProfileOptionTile(
                                  enabled: !_saving,
                                  label: experienceLabel(context.l10n, level),
                                  helperText:
                                      experienceHelp(context.l10n, level),
                                  selected: draft.experience == level,
                                  onSelected: () => _update(
                                      (p) => p.copyWith(experience: level)),
                                ),
                            ]),
                        const SizedBox(height: 12),
                        UtilityDisclosure(
                            title: context.l10n.utilityDuration,
                            summary: context.l10n.utilitySelectedValue(
                                workoutDurationLabel(
                                    context.l10n, draft.workoutDuration)),
                            children: [
                              for (final duration in WorkoutDuration.values)
                                ProfileOptionTile(
                                  enabled: !_saving,
                                  label: workoutDurationLabel(
                                      context.l10n, duration),
                                  selected: draft.workoutDuration == duration,
                                  onSelected: () => _update(
                                    (p) =>
                                        p.copyWith(workoutDuration: duration),
                                  ),
                                ),
                            ]),
                        const SizedBox(height: 12),
                        UtilityDisclosure(
                            title: context.l10n.utilityEnvironment,
                            summary: context.l10n.utilitySelectedValue(
                                environmentLabel(
                                    context.l10n, draft.environment)),
                            children: [
                              for (final env in TrainingEnvironment.values)
                                ProfileOptionTile(
                                  enabled: !_saving,
                                  label: environmentLabel(context.l10n, env),
                                  selected: draft.environment == env,
                                  onSelected: () => _update(
                                      (p) => p.copyWith(environment: env)),
                                ),
                            ]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _draft == null
            ? null
            : ProfileEditorSaveBar(
                enabled: _hasUnsavedChanges,
                saving: _saving,
                onSave: _save,
              ),
      ),
    );
  }
}
