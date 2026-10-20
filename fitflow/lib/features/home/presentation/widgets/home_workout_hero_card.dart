import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/features/home/presentation/widgets/home_session_mode_widgets.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A photo-led introduction to the actual generated workout, not a program.
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
    final l = context.l10n;
    final v = FitFlowVisualV2.of(context);
    final text = Theme.of(context).textTheme;
    final minutes = (effectiveDuration ?? userProfile.workoutDuration).minutes;
    final estimated = plan.estimatedDuration;
    final planned = estimated == null
        ? l.homePlannedUnknown
        : estimated.inSeconds < 60
            ? l.homePlannedShort
            : l.homePlanned((estimated.inSeconds / 60).ceil());
    // The photo follows the current plan, including temporary mode changes.
    final featured =
        plan.main.exercises.isEmpty ? null : plan.main.exercises.first.exercise;

    final introduction = Padding(
      padding: const EdgeInsets.all(FitFlowSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
            header: true,
            child: Text(l.homeSession,
                style: text.titleLarge
                    ?.copyWith(color: v.onHero, fontWeight: FontWeight.w500))),
        const SizedBox(height: FitFlowSpace.xs),
        Wrap(
            spacing: FitFlowSpace.md,
            runSpacing: FitFlowSpace.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('$minutes ${l.v2HomeTargetUnit}',
                  key: const Key('home_target'),
                  semanticsLabel: l.homeDurationTarget(minutes),
                  style: text.bodyMedium?.copyWith(color: v.heroSecondary)),
              Text(l.homeExercises(plan.totalExerciseCount),
                  style: text.bodyMedium?.copyWith(color: v.heroSecondary)),
            ]),
        if (estimated != Duration(minutes: minutes)) ...[
          const SizedBox(height: FitFlowSpace.xxs),
          Text(planned,
              style: text.bodySmall?.copyWith(color: v.heroSecondary)),
        ],
        const SizedBox(height: FitFlowSpace.sm),
        FitFlowPrimaryButton(
            label: l.viewWorkout,
            icon: Icons.arrow_forward_rounded,
            semanticHint: l.viewWorkoutHint,
            style: FilledButton.styleFrom(
                backgroundColor: v.action,
                foregroundColor: v.onAction,
                textStyle:
                    text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
                minimumSize: const Size(64, 52),
                padding: const EdgeInsets.symmetric(
                    horizontal: FitFlowSpace.md, vertical: FitFlowSpace.sm),
                overlayColor: v.onAction.withValues(alpha: .12)),
            onPressed: () => context.push(AppRoutes.workoutPreview),
            expand: true),
      ]),
    );
    Widget photo(double width) => FitFlowExerciseImage.hero(
        key: const ValueKey('home_workout_photo'),
        exerciseId: featured!.id,
        width: width,
        height: width * 3 / 4,
        decorative: false,
        semanticLabel: featured.name);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DecoratedBox(
          decoration: BoxDecoration(
              color: v.heroStart, borderRadius: FitFlowRadius.cardBorder),
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560 &&
                MediaQuery.textScalerOf(context).scale(16) <= 22;
            if (wide && featured != null) {
              return Row(children: [
                photo(constraints.maxWidth * .46),
                Expanded(child: introduction)
              ]);
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (featured != null) photo(constraints.maxWidth),
                  introduction
                ]);
          })),
      const SizedBox(height: FitFlowSpace.sm),
      const HomeSessionModeControl(),
    ]);
  }
}
