import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live, in-memory projection of catalog metadata and the persisted/current
/// movement and setup profiles. It intentionally does not watch temporary
/// workout-session modes and creates no skill-tree persistence.
final exerciseSkillTreeCatalogProvider = Provider<ExerciseSkillTreeCatalog>(
  (ref) {
    final userProfile = ref.watch(userFitnessProfileProvider).value;
    final capabilityProfile = ref.watch(capabilityProfileProvider).value;
    return ExerciseSkillTreeResolver.resolve(
      exercises: ExerciseCatalog.all,
      userProfile: userProfile,
      capabilityProfile: capabilityProfile,
    );
  },
);
