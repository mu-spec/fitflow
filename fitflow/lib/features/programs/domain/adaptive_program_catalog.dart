import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';

/// Built-in adaptive program catalog — M16 Part 1.
///
/// Exactly five programs. Definitions live here, outside widgets, and are
/// immutable. No exercise IDs are stored; every workout is generated later
/// from the user's current profile and capability.
class AdaptiveProgramCatalog {
  AdaptiveProgramCatalog._();

  static const String balancedFoundationsId = 'balanced_foundations';
  static const String strengthFoundationsId = 'strength_foundations';
  static const String enduranceBuilderId = 'endurance_builder';
  static const String mobilityMovementId = 'mobility_movement';
  static const String stayActiveStarterId = 'stay_active_starter';

  static final AdaptiveProgramDefinition balancedFoundations =
      AdaptiveProgramDefinition.build(
    id: balancedFoundationsId,
    name: 'Balanced Foundations',
    description:
        'A four-week mix of general fitness, strength and endurance sessions. '
        'Each workout is generated from your current movement levels and setup.',
    focus: 'Balanced full-body training',
    weekCount: 4,
    weeklyTemplate: const [
      AdaptiveProgramSessionTemplate(
        focus: 'Full-body basics',
        generationGoal: FitnessGoal.generalFitness,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Strength',
        generationGoal: FitnessGoal.buildStrength,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Endurance',
        generationGoal: FitnessGoal.improveEndurance,
      ),
    ],
    recommendedFor: const {FitnessGoal.generalFitness},
  );

  static final AdaptiveProgramDefinition strengthFoundations =
      AdaptiveProgramDefinition.build(
    id: strengthFoundationsId,
    name: 'Strength Foundations',
    description:
        'Six weeks of strength and muscle-building sessions. Exercises are '
        'chosen from your current movement levels, equipment and environment.',
    focus: 'Strength and muscle',
    weekCount: 6,
    weeklyTemplate: const [
      AdaptiveProgramSessionTemplate(
        focus: 'Strength',
        generationGoal: FitnessGoal.buildStrength,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Muscle building',
        generationGoal: FitnessGoal.buildMuscle,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Strength',
        generationGoal: FitnessGoal.buildStrength,
      ),
    ],
    recommendedFor: const {FitnessGoal.buildStrength, FitnessGoal.buildMuscle},
  );

  static final AdaptiveProgramDefinition enduranceBuilder =
      AdaptiveProgramDefinition.build(
    id: enduranceBuilderId,
    name: 'Endurance Builder',
    description:
        'Four weeks with four sessions per week focused on endurance and '
        'staying active. Workouts adapt to your current movement levels and setup.',
    focus: 'Endurance and activity',
    weekCount: 4,
    weeklyTemplate: const [
      AdaptiveProgramSessionTemplate(
        focus: 'Endurance',
        generationGoal: FitnessGoal.improveEndurance,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Full-body basics',
        generationGoal: FitnessGoal.generalFitness,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Endurance',
        generationGoal: FitnessGoal.improveEndurance,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Stay active',
        generationGoal: FitnessGoal.stayActive,
      ),
    ],
    recommendedFor: const {
      FitnessGoal.improveEndurance,
      FitnessGoal.loseWeight,
    },
  );

  static final AdaptiveProgramDefinition mobilityMovement =
      AdaptiveProgramDefinition.build(
    id: mobilityMovementId,
    name: 'Mobility & Movement',
    description:
        'Four weeks that alternate mobility sessions with general fitness '
        'sessions, generated from your current movement levels and setup.',
    focus: 'Mobility and movement quality',
    weekCount: 4,
    weeklyTemplate: const [
      AdaptiveProgramSessionTemplate(
        focus: 'Mobility',
        generationGoal: FitnessGoal.improveMobility,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Full-body basics',
        generationGoal: FitnessGoal.generalFitness,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Mobility',
        generationGoal: FitnessGoal.improveMobility,
      ),
    ],
    recommendedFor: const {FitnessGoal.improveMobility},
  );

  static final AdaptiveProgramDefinition stayActiveStarter =
      AdaptiveProgramDefinition.build(
    id: stayActiveStarterId,
    name: 'Stay Active Starter',
    description:
        'A gentle four-week routine of stay-active and general fitness '
        'sessions built around your current movement levels and setup.',
    focus: 'Consistent, gentle activity',
    weekCount: 4,
    weeklyTemplate: const [
      AdaptiveProgramSessionTemplate(
        focus: 'Stay active',
        generationGoal: FitnessGoal.stayActive,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Full-body basics',
        generationGoal: FitnessGoal.generalFitness,
      ),
      AdaptiveProgramSessionTemplate(
        focus: 'Stay active',
        generationGoal: FitnessGoal.stayActive,
      ),
    ],
    recommendedFor: const {FitnessGoal.stayActive},
  );

  /// All five programs in deterministic display order (unmodifiable).
  static final List<AdaptiveProgramDefinition> all =
      List<AdaptiveProgramDefinition>.unmodifiable([
    balancedFoundations,
    strengthFoundations,
    enduranceBuilder,
    mobilityMovement,
    stayActiveStarter,
  ]);

  /// All ordered program IDs (unmodifiable).
  static final List<String> allIds =
      List<String>.unmodifiable(all.map((p) => p.id));

  /// Looks up a program by ID; null when unknown.
  static AdaptiveProgramDefinition? byId(String? programId) {
    if (programId == null) return null;
    for (final p in all) {
      if (p.id == programId) return p;
    }
    return null;
  }

  static bool contains(String? programId) => byId(programId) != null;

  /// Finds a session across all programs; null when unknown.
  static AdaptiveProgramSession? sessionById(String sessionId) {
    for (final p in all) {
      final s = p.sessionById(sessionId);
      if (s != null) return s;
    }
    return null;
  }

  /// Catalog-level validation problems (empty when valid).
  static List<String> validate() {
    final problems = <String>[];
    final programIds = <String>{};
    final sessionIds = <String>{};
    for (final p in all) {
      if (!programIds.add(p.id)) {
        problems.add('duplicate program id ${p.id}');
      }
      problems.addAll(p.validate().map((e) => '${p.id}: $e'));
      for (final s in p.sessions) {
        if (!sessionIds.add(s.id)) {
          problems.add('duplicate session id ${s.id} across catalog');
        }
      }
      if (p.recommendedFor.isEmpty) {
        problems.add('${p.id}: recommendedFor is empty');
      }
    }
    return problems;
  }

  static bool get isValid => validate().isEmpty;
}
