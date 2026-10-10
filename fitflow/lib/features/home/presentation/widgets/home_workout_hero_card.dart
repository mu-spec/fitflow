import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/core/design/widgets/fitflow_surfaces.dart';
import 'package:fitflow/features/home/presentation/widgets/home_session_mode_widgets.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A single action-led anchor. All numbers come from the current generated plan.
class HomeWorkoutHeroCard extends StatelessWidget {
  const HomeWorkoutHeroCard(
      {super.key,
      required this.plan,
      required this.userProfile,
      this.effectiveDuration,
      this.sessionMode = WorkoutSessionMode.standard});
  final WorkoutPlan plan;
  final UserFitnessProfile userProfile;
  final WorkoutDuration? effectiveDuration;
  final WorkoutSessionMode sessionMode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    final minutes = (effectiveDuration ?? userProfile.workoutDuration).minutes;
    final estimated = plan.estimatedDuration;
    final planned = estimated == null
        ? l10n.homePlannedUnknown
        : estimated.inSeconds < 60
            ? l10n.homePlannedShort
            : l10n.homePlanned((estimated.inSeconds / 60).ceil());
    Widget count(String label, int count) => Semantics(
          label: '$label: $count',
          excludeSemantics: true,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$count', style: text.titleSmall),
            const SizedBox(width: FitFlowSpace.xxs),
            Text(label, style: text.bodySmall),
          ]),
        );
    return FitFlowSurface(
      padding: const EdgeInsets.all(FitFlowSpace.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.homeToday,
            style: text.labelSmall?.copyWith(color: colors.brand)),
        const SizedBox(height: FitFlowSpace.xs),
        Text(l10n.homeSession, style: text.titleLarge),
        const SizedBox(height: FitFlowSpace.md),
        Text(l10n.homeDurationTarget(minutes),
            key: const Key('home_target'),
            style: text.headlineMedium?.copyWith(color: colors.brand)),
        const SizedBox(height: FitFlowSpace.xxs),
        Wrap(spacing: FitFlowSpace.sm, runSpacing: FitFlowSpace.xxs, children: [
          Text(l10n.homeExercises(plan.totalExerciseCount),
              style: text.bodyMedium),
          Text(planned,
              style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
        ]),
        const SizedBox(height: FitFlowSpace.sm),
        Text(l10n.homeAdaptation,
            style: text.bodySmall?.copyWith(color: colors.textSecondary)),
        const SizedBox(height: FitFlowSpace.lg),
        Semantics(
            hint: l10n.viewWorkoutHint,
            child: FitFlowPrimaryButton(
                label: l10n.viewWorkout,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push(AppRoutes.workoutPreview),
                expand: true)),
        const SizedBox(height: FitFlowSpace.sm),
        const HomeSessionModeControl(),
        const SizedBox(height: FitFlowSpace.sm),
        const Divider(),
        const SizedBox(height: FitFlowSpace.sm),
        Wrap(spacing: FitFlowSpace.md, runSpacing: FitFlowSpace.xs, children: [
          count(l10n.homeWarmup, plan.warmup.exerciseCount),
          count(l10n.homeMain, plan.main.exerciseCount),
          count(l10n.homeCooldown, plan.cooldown.exerciseCount),
        ]),
      ]),
    );
  }
}
