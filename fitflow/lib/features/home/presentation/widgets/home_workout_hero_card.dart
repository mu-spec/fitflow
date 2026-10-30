import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
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

    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l.homeSession,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        Text(planned, key: const Key('home_planned'), style: text.bodyMedium),
        Text(l.homeExercises(plan.totalExerciseCount),
            style: text.bodySmall?.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 4),
        Text('$minutes ${l.v2HomeTargetUnit}',
            key: const Key('home_target'),
            semanticsLabel: l.homeDurationTarget(minutes),
            style: text.bodySmall?.copyWith(color: colors.textSecondary)),
      ],
    );
    Widget photo(double width) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FitFlowMediaImage(
            key: const ValueKey('home_workout_photo'),
            asset: ExerciseMediaRegistry.lookup(featured!.id)?.hero,
            width: width,
            height: width * 3 / 4,
            decorative: false,
            semanticLabel: featured.name,
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            LayoutBuilder(builder: (context, constraints) {
              if (featured == null) return introduction;
              if (MediaQuery.textScalerOf(context).scale(16) > 24 ||
                  constraints.maxWidth < 270) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    photo(128),
                    const SizedBox(height: 12),
                    introduction
                  ],
                );
              }
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    photo(112),
                    const SizedBox(width: 12),
                    Expanded(child: introduction),
                  ]);
            }),
            const SizedBox(height: 12),
            FitFlowPrimaryButton(
              label: l.viewWorkout,
              icon: Icons.arrow_forward_rounded,
              semanticHint: l.viewWorkoutHint,
              onPressed: () => context.push(AppRoutes.workoutPreview),
              expand: true,
            ),
          ]),
        ),
      ),
      const SizedBox(height: FitFlowSpace.sm),
      const HomeSessionModeControl(),
    ]);
  }
}
