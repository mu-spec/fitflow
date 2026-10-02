import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';

/// Deterministic, order-stable summary formatting for Profile tab rows.
///
/// Ordering ALWAYS follows enum declaration order — never Set/hash order —
/// so identical selections always produce identical summary text.

/// Fitness Profile row: primary line, e.g. `General fitness • Some experience`.
String fitnessProfileSummaryPrimary(UserFitnessProfile profile) =>
    '${profile.goal.label} • ${profile.experience.label}';

/// Fitness Profile row: secondary line, e.g. `20 minutes • Normal home`.
String fitnessProfileSummarySecondary(UserFitnessProfile profile) =>
    '${profile.workoutDuration.label} • ${profile.environment.label}';

/// Equipment row, e.g. `Dumbbells, exercise mat +2` or `None`.
///
/// `None` is reported as the word `None` (it is not mixed with real items);
/// real items are listed in enum declaration order, at most two labels plus
/// a `+N` overflow count.
String formatEquipmentSummary(Set<WorkoutEquipment> equipment) {
  final selected = [
    for (final value in WorkoutEquipment.values)
      if (value != WorkoutEquipment.none && equipment.contains(value))
        value.label,
  ];
  if (selected.isEmpty) {
    return 'None';
  }
  return _summarizeLabels(selected);
}

/// Workout Preferences row, e.g. `No jumping, low impact +1`, or the empty
/// fallback when no preferences are selected.
String formatPreferencesSummary(Set<WorkoutPreference> preferences) {
  final selected = [
    for (final value in WorkoutPreference.values)
      if (preferences.contains(value)) value.label,
  ];
  if (selected.isEmpty) {
    return 'No special workout preferences';
  }
  return _summarizeLabels(selected);
}

String _summarizeLabels(List<String> labels) {
  if (labels.length <= 2) {
    return labels.join(', ');
  }
  return '${labels.take(2).join(', ')} +${labels.length - 2}';
}
