import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
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
      this.maxPhotoHeight = 330,
      this.sessionMode = WorkoutSessionMode.standard});
  final double maxPhotoHeight;
  final WorkoutPlan plan;
  final UserFitnessProfile userProfile;
  final WorkoutDuration? effectiveDuration;
  final WorkoutSessionMode sessionMode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = FitFlowTheme.of(context);
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
      padding: const EdgeInsets.only(top: FitFlowSpace.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
            header: true,
            child: Text(l.homeSession,
                style: text.titleLarge?.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w500))),
        const SizedBox(height: FitFlowSpace.xs),
        Wrap(
            spacing: FitFlowSpace.md,
            runSpacing: FitFlowSpace.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(planned,
                  key: const Key('home_planned'), style: text.bodyMedium),
              Text(l.homeExercises(plan.totalExerciseCount),
                  style:
                      text.bodyMedium?.copyWith(color: colors.textSecondary)),
            ]),
        const SizedBox(height: FitFlowSpace.xxs),
        Text('$minutes ${l.v2HomeTargetUnit}',
            key: const Key('home_target'),
            semanticsLabel: l.homeDurationTarget(minutes),
            style: text.bodySmall?.copyWith(color: colors.textSecondary)),
        const SizedBox(height: FitFlowSpace.sm),
        FitFlowPrimaryButton(
            label: l.viewWorkout,
            icon: Icons.arrow_forward_rounded,
            semanticHint: l.viewWorkoutHint,
            onPressed: () => context.push(AppRoutes.workoutPreview),
            expand: true),
      ]),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (featured != null)
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, maxPhotoHeight * 4 / 3);
          return Center(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FitFlowExerciseImage.hero(
              key: const ValueKey('home_workout_photo'),
              exerciseId: featured.id,
              width: width,
              height: width * 3 / 4,
              decorative: false,
              semanticLabel: featured.name,
            ),
          ));
        }),
      introduction,
      const SizedBox(height: FitFlowSpace.sm),
      const HomeSessionModeControl(),
    ]);
  }
}
