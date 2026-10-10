import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_option.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_reason.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Presentation only. Eligibility, ordering and replacement remain controller-owned.
class WorkoutReplacementPicker extends StatelessWidget {
  const WorkoutReplacementPicker(
      {super.key,
      required this.currentPrescription,
      required this.options,
      required this.scrollController,
      required this.onSelect,
      this.originalExerciseName});
  final WorkoutExercisePrescription currentPrescription;
  final List<WorkoutReplacementOption> options;
  final ScrollController scrollController;
  final ValueChanged<WorkoutReplacementOption> onSelect;
  final String? originalExerciseName;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return SafeArea(
        top: false,
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
              FitFlowSpace.xl, 0, FitFlowSpace.xl, FitFlowSpace.xl),
          itemCount: options.isEmpty ? 2 : options.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Semantics(
                              header: true,
                              child:
                                  Text(l.flowReplace, style: text.titleLarge))),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l.cancel))
                    ]),
                    const SizedBox(height: FitFlowSpace.xs),
                    Text(l.flowCurrent(currentPrescription.exercise.name),
                        style: text.titleMedium),
                    if (originalExerciseName != null)
                      Text(l.flowOriginal(originalExerciseName!),
                          style: text.bodySmall),
                    const SizedBox(height: FitFlowSpace.xs),
                    Text(workloadLabel(l, currentPrescription),
                        style: text.bodyMedium),
                    const SizedBox(height: FitFlowSpace.md),
                    const Divider(),
                  ]);
            }
            if (options.isEmpty) {
              return FitFlowEmptyState(
                  title: l.flowNoAlternatives,
                  message: l.flowNoAlternativesBody,
                  icon: Icons.swap_horiz_rounded);
            }
            final option = options[index - 1];
            // Reorder only the explanation, never the engine's candidate ordering.
            const priority = [
              WorkoutReplacementReason.keepsWorkload,
              WorkoutReplacementReason.fitsSetup,
              WorkoutReplacementReason.sameDifficulty,
              WorkoutReplacementReason.easierVariation,
              WorkoutReplacementReason.sameMovementFocus,
              WorkoutReplacementReason.matchesPreferences,
              WorkoutReplacementReason.sameProgressionFamily
            ];
            final reasons = priority
                .where(option.reasons.contains)
                .map((r) => replacementReasonLabel(l, r))
                .toList();
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(option.exercise.name, style: text.titleLarge),
                      const SizedBox(height: FitFlowSpace.xs),
                      Text(workloadLabel(l, option.prescription),
                          style: text.titleMedium),
                      const SizedBox(height: FitFlowSpace.xxs),
                      Text(equipmentSummary(l, option.prescription),
                          style: text.bodySmall),
                      const SizedBox(height: FitFlowSpace.sm),
                      for (final reason in reasons.take(2))
                        Padding(
                            padding:
                                const EdgeInsets.only(bottom: FitFlowSpace.xxs),
                            child: Text(reason, style: text.bodyMedium)),
                      if (reasons.length > 2)
                        ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title:
                                Text(l.flowMoreReasons, style: text.labelLarge),
                            children: [
                              for (final reason in reasons.skip(2))
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: FitFlowSpace.xs),
                                        child: Text(reason,
                                            style: text.bodySmall))),
                            ]),
                      const SizedBox(height: FitFlowSpace.xs),
                      Semantics(
                          label: l.flowReplaceWith(option.exercise.name),
                          child: FilledButton.tonal(
                              key: ValueKey(
                                  'replace_option_${option.exercise.id}'),
                              onPressed: () => onSelect(option),
                              child: Text(l.flowUse))),
                      const SizedBox(height: FitFlowSpace.md),
                      const Divider(height: 1),
                    ]));
          },
        ));
  }
}
