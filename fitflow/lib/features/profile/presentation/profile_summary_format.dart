import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';

/// Deterministic, order-stable summary formatting for Profile tab rows.
///
/// Ordering ALWAYS follows enum declaration order — never Set/hash order —
/// so identical selections always produce identical summary text.

/// Fitness Profile row: primary line, e.g. `General fitness • Some experience`.
String fitnessProfileSummaryPrimary(UserFitnessProfile profile,
        {AppLocalizations? l10n}) =>
    l10n == null
        ? '${profile.goal.label} • ${profile.experience.label}'
        : '${fitnessGoalLabel(l10n, profile.goal)} • ${experienceLabel(l10n, profile.experience)}';

/// Fitness Profile row: secondary line, e.g. `20 minutes • Normal home`.
String fitnessProfileSummarySecondary(UserFitnessProfile profile,
        {AppLocalizations? l10n}) =>
    l10n == null
        ? '${profile.workoutDuration.label} • ${profile.environment.label}'
        : '${workoutDurationLabel(l10n, profile.workoutDuration)} • ${environmentLabel(l10n, profile.environment)}';

/// Equipment row, e.g. `Dumbbells, exercise mat +2` or `None`.
///
/// `None` is reported as the word `None` (it is not mixed with real items);
/// real items are listed in enum declaration order, at most two labels plus
/// a `+N` overflow count. The overview opts into [showAll] to wrap every value.
String formatEquipmentSummary(Set<WorkoutEquipment> equipment,
    {AppLocalizations? l10n, bool showAll = false}) {
  final selected = [
    for (final value in WorkoutEquipment.values)
      if (value != WorkoutEquipment.none && equipment.contains(value))
        l10n == null ? value.label : equipmentLabel(l10n, value),
  ];
  if (selected.isEmpty) {
    return l10n?.equipmentNone ?? 'None';
  }
  return showAll ? selected.join(', ') : _summarizeLabels(selected);
}

/// Workout Preferences row, e.g. `No jumping, low impact +1`, or the empty
/// fallback when no preferences are selected.
String formatPreferencesSummary(Set<WorkoutPreference> preferences,
    {AppLocalizations? l10n, bool showAll = false}) {
  final selected = [
    for (final value in WorkoutPreference.values)
      if (preferences.contains(value))
        l10n == null ? value.label : preferenceLabel(l10n, value),
  ];
  if (selected.isEmpty) {
    return l10n?.utilityNoPreferences ?? 'No special workout preferences';
  }
  return showAll ? selected.join(', ') : _summarizeLabels(selected);
}

String _summarizeLabels(List<String> labels) {
  if (labels.length <= 2) {
    return labels.join(', ');
  }
  return '${labels.take(2).join(', ')} +${labels.length - 2}';
}
