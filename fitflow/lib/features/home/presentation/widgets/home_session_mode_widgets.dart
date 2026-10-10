import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/widgets/fitflow_selection.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeSessionModeControl extends ConsumerWidget {
  const HomeSessionModeControl({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(workoutSessionModeProvider);
    final colors = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Row(children: [
      ExcludeSemantics(
          child: Icon(Icons.tune_outlined, color: colors.brand, size: 20)),
      const SizedBox(width: FitFlowSpace.xs),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.homeMode,
            style: text.bodySmall?.copyWith(color: colors.textSecondary)),
        Semantics(
            liveRegion: true,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(mode),
              tween: Tween(begin: 0, end: 1),
              duration: SystemMotion.micro(context),
              curve: FitFlowMotion.standardCurve,
              builder: (_, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Text(sessionModeLabel(context.l10n, mode),
                  style: text.titleSmall),
            )),
        if (mode != WorkoutSessionMode.standard)
          Text(context.l10n.homeTemporary,
              style: text.bodySmall?.copyWith(color: colors.textSecondary)),
      ])),
      TextButton(
          onPressed: () => FitFlowSheet.show<void>(context,
              child: const ChooseWorkoutModeSheet()),
          child: Text(context.l10n.homeAdjust)),
    ]);
  }
}

class ChooseWorkoutModeSheet extends ConsumerWidget {
  const ChooseWorkoutModeSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(workoutSessionModeProvider);
    final l10n = context.l10n;
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
              header: true,
              child: Text(l10n.homeChooseMode,
                  style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: FitFlowSpace.sm),
          Text(l10n.modeDoesNotChangeLevels,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FitFlowSpace.md),
          for (final mode in WorkoutSessionMode.values) ...[
            Semantics(
                inMutuallyExclusiveGroup: true,
                child: FitFlowSelectableTile(
                  label: sessionModeLabel(l10n, mode),
                  subtitle: switch (mode) {
                    WorkoutSessionMode.standard => l10n.modeStandardDescription,
                    WorkoutSessionMode.lowEnergy =>
                      l10n.modeLowEnergyDescription,
                    WorkoutSessionMode.comeback => l10n.modeComebackDescription,
                  },
                  selected: current == mode,
                  onTap: () {
                    ref
                        .read(workoutSessionModeProvider.notifier)
                        .selectMode(mode);
                    Navigator.of(context).pop();
                  },
                )),
            const SizedBox(height: FitFlowSpace.xs),
          ],
        ]);
  }
}

class ComebackSuggestionCard extends ConsumerWidget {
  const ComebackSuggestionCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.homeComebackSuggestion,
              style: Theme.of(context).textTheme.bodyMedium),
          FitFlowTertiaryButton(
              label: context.l10n.homeUseComeback,
              onPressed: () => ref
                  .read(workoutSessionModeProvider.notifier)
                  .selectMode(WorkoutSessionMode.comeback)),
        ],
      );
}
