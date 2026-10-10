import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_reason.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

String workloadLabel(AppLocalizations l, WorkoutExercisePrescription p) =>
    p.repsPerSet != null
        ? l.flowWorkloadReps(p.sets, p.repsPerSet!)
        : l.flowWorkloadTime(p.sets, p.workDuration?.inSeconds ?? 0);
String equipmentSummary(AppLocalizations l, WorkoutExercisePrescription p) {
  final items =
      p.exercise.requiredEquipment.where((e) => e != WorkoutEquipment.none);
  return items.isEmpty
      ? l.flowNoEquipment
      : items.map((e) => equipmentLabel(l, e)).join(', ');
}

String sectionLabel(AppLocalizations l, WorkoutSectionType section) =>
    switch (section) {
      WorkoutSectionType.warmup => l.flowWarmup,
      WorkoutSectionType.main => l.flowMain,
      WorkoutSectionType.cooldown => l.flowCooldown,
    };
String plannedDuration(AppLocalizations l, Duration? d) => d == null
    ? l.flowUnknownDuration
    : l.flowDuration(d.inMinutes, d.inSeconds % 60);
String countdown(Duration d) {
  final seconds = d.inSeconds.clamp(0, 999999);
  return seconds >= 60
      ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
      : '$seconds';
}

String replacementReasonLabel(AppLocalizations l, WorkoutReplacementReason r) =>
    switch (r) {
      WorkoutReplacementReason.sameMovementFocus => l.flowReasonMovement,
      WorkoutReplacementReason.sameDifficulty => l.flowReasonDifficulty,
      WorkoutReplacementReason.easierVariation => l.flowReasonEasier,
      WorkoutReplacementReason.fitsSetup => l.flowReasonSetup,
      WorkoutReplacementReason.matchesPreferences => l.flowReasonPreferences,
      WorkoutReplacementReason.sameProgressionFamily => l.flowReasonFamily,
      WorkoutReplacementReason.keepsWorkload => l.flowReasonWorkload,
    };
