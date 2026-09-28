import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

/// Clean execution representation derived from existing WorkoutPlan.
/// Preserves Warm-up → Main → Cooldown order and exact prescription order.
/// Understands each individual set.
class WorkoutPlayerExecution {
  WorkoutPlayerExecution(this.plan)
      : sections = [plan.warmup, plan.main, plan.cooldown],
        totalSets = _computeTotalSets(plan),
        _sectionTypes = const [
          WorkoutSectionType.warmup,
          WorkoutSectionType.main,
          WorkoutSectionType.cooldown,
        ];

  final WorkoutPlan plan;
  final List<WorkoutSection> sections;
  final List<WorkoutSectionType> _sectionTypes;
  final int totalSets;

  static int _computeTotalSets(WorkoutPlan plan) {
    int sum = 0;
    for (final s in [plan.warmup, plan.main, plan.cooldown]) {
      for (final p in s.exercises) {
        sum += p.sets;
      }
    }
    return sum;
  }

  int get sectionCount => sections.length;

  WorkoutSection sectionAt(int sectionIndex) => sections[sectionIndex];

  WorkoutSectionType sectionTypeAt(int sectionIndex) => _sectionTypes[sectionIndex];

  int exerciseCountInSection(int sectionIndex) => sections[sectionIndex].exerciseCount;

  WorkoutExercisePrescription prescriptionAt(int sectionIndex, int exerciseIndex) {
    return sections[sectionIndex].exercises[exerciseIndex];
  }

  /// Returns ordered list of all prescriptions flattened but preserving section boundaries.
  List<WorkoutExercisePrescription> get allPrescriptionsInOrder => plan.allPrescriptions;

  /// Helper to check if exercise is last in its section.
  bool isLastExerciseInSection(int sectionIndex, int exerciseIndex) {
    return exerciseIndex >= exerciseCountInSection(sectionIndex) - 1;
  }

  /// Helper to check if section is last (cooldown).
  bool isLastSection(int sectionIndex) => sectionIndex >= sectionCount - 1;
}
