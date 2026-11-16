import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';

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
    final text = Theme.of(context)
        .textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white);
    final minutes = (effectiveDuration ?? userProfile.workoutDuration).minutes;
    final estimated = plan.estimatedDuration;
    final planned = estimated == null
        ? l.homePlannedUnknown
        : estimated.inSeconds < 60
            ? l.homePlannedShort
            : l.homePlanned((estimated.inSeconds / 60).ceil());
    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l.homeSession,
              style: text.titleLarge
                  ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        Text(planned,
            key: const Key('home_planned'),
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        Text(l.homeExercises(plan.totalExerciseCount), style: text.bodyMedium),
        const SizedBox(height: 12),
        Text('$minutes ${l.v2HomeTargetUnit}',
            key: const Key('home_target'),
            semanticsLabel: l.homeDurationTarget(minutes),
            style: text.bodyMedium),
      ],
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, constraints) {
          final content =
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(flex: 1, child: introduction),
              const SizedBox(width: 12),
              Expanded(
                  flex: 1,
                  child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Image.asset(
                          'assets/images/editorial/strength_foundations_portrait.webp',
                          key: const ValueKey('home_workout_photo'),
                          fit: BoxFit.contain,
                          excludeFromSemantics: true))),
            ]),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(
                  filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Color(0xFFCBD2DE)),
                    minimumSize: const Size(48, 48)),
              )),
              child: FitFlowPrimaryButton(
                label: l.viewWorkout,
                icon: Icons.arrow_forward_rounded,
                semanticHint: l.viewWorkoutHint,
                onPressed: () => context.push(AppRoutes.workoutPreview),
                expand: true,
              ),
            ),
          ]);
          return ColoredBox(
              color: const Color(0xFF183D73),
              child:
                  Padding(padding: const EdgeInsets.all(18), child: content));
        }),
      ),
      const SizedBox(height: FitFlowSpace.sm),
      const HomeSessionModeControl(),
    ]);
  }
}
