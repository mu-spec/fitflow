import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/features/home/presentation/widgets/home_flow_motif.dart';
import 'package:fitflow/features/home/presentation/widgets/home_session_mode_widgets.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// V2 emphasis, with exactly the existing generated plan and Preview action.
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
    Widget count(String label, int count) => Semantics(
          label: '$label: $count',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: FitFlowSpace.sm, vertical: FitFlowSpace.xs),
            decoration: BoxDecoration(
                color: v.onHero.withValues(alpha: .07),
                borderRadius: FitFlowRadius.mediumBorder),
            child: Wrap(
                spacing: FitFlowSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('$count',
                      style: text.titleMedium?.copyWith(color: v.onHero)),
                  Text(label,
                      style: text.bodySmall?.copyWith(color: v.heroSecondary)),
                ]),
          ),
        );
    final metric =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '$minutes',
                style: text.displaySmall?.copyWith(color: v.onHero)),
            TextSpan(
                text: ' ${l.v2HomeTargetUnit}',
                style: text.labelLarge?.copyWith(color: v.heroSecondary)),
          ]),
          key: const Key('home_target'),
          semanticsLabel: l.homeDurationTarget(minutes)),
      const SizedBox(height: FitFlowSpace.sm),
      Text(l.homeExercises(plan.totalExerciseCount),
          style: text.titleSmall?.copyWith(color: v.onHero)),
      const SizedBox(height: FitFlowSpace.xxs),
      Text(planned, style: text.bodyMedium?.copyWith(color: v.heroSecondary)),
    ]);
    return FitFlowV2HeroSurface(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.homeToday,
          style: text.labelMedium?.copyWith(color: v.action, letterSpacing: 1)),
      const SizedBox(height: FitFlowSpace.xs),
      Semantics(
          header: true,
          child: Text(l.homeSession,
              style: text.headlineMedium?.copyWith(color: v.onHero))),
      const SizedBox(height: FitFlowSpace.sm),
      LayoutBuilder(builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
        // The artwork yields space to text; the user's text never shrinks.
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: metric),
          const SizedBox(width: FitFlowSpace.xs),
          SizedBox(
              width: largeText ? 56 : 104,
              height: largeText ? 76 : 112,
              child: const FittedBox(child: HomeFlowMotif())),
        ]);
      }),
      const SizedBox(height: FitFlowSpace.sm),
      Text(l.homeAdaptation,
          style: text.bodyMedium?.copyWith(color: v.heroSecondary)),
      const SizedBox(height: FitFlowSpace.lg),
      FitFlowPrimaryButton(
          label: l.viewWorkout,
          icon: Icons.arrow_forward_rounded,
          semanticHint: l.viewWorkoutHint,
          style: FilledButton.styleFrom(
              backgroundColor: v.action,
              foregroundColor: v.onAction,
              minimumSize: const Size(64, 56),
              overlayColor: v.onAction.withValues(alpha: .12)),
          onPressed: () => context.push(AppRoutes.workoutPreview),
          expand: true),
      const SizedBox(height: FitFlowSpace.xs),
      const HomeSessionModeControl(emphasized: true),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
          child: Divider(color: v.heroLine)),
      Wrap(spacing: FitFlowSpace.xs, runSpacing: FitFlowSpace.xs, children: [
        count(l.homeWarmup, plan.warmup.exerciseCount),
        count(l.homeMain, plan.main.exerciseCount),
        count(l.homeCooldown, plan.cooldown.exerciseCount),
      ]),
    ]));
  }
}
