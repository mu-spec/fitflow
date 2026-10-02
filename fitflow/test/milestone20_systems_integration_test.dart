import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_engine.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_engine.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:flutter_test/flutter_test.dart';

/// Milestone 20 Part 2: subsystem integration regression over the corrected
/// catalog — M15, M13, capability anchors, M9, M10, M16, and player
/// prescription viability. No architecture rewrites.
void main() {
  final anchorDate = DateTime.utc(2026, 10, 1);

  CapabilityProfile profileAtLevel(CapabilityLevel level) {
    return CapabilityProfile.fromMap({
      for (final pattern in CapabilityProfile.trainablePatterns)
        pattern: MovementCapability(
          movementPattern: pattern,
          level: level,
          source: CapabilitySource.initialAssessment,
          updatedAt: anchorDate,
        ),
    });
  }

  UserFitnessProfile userProfile({
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    Set<WorkoutPreference> preferences = const {},
    WorkoutDuration duration = WorkoutDuration.fifteenMinutes,
  }) {
    return UserFitnessProfile(
      goal: FitnessGoal.generalFitness,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: environment,
      equipment: equipment,
      preferences: preferences,
    );
  }

  group('M15 skill tree regression', () {
    test('major families resolve structurally valid and deterministic', () {
      final profile = userProfile();
      final capability = profileAtLevel(CapabilityLevel.level3);

      final first = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: profile,
        capabilityProfile: capability,
      );
      final second = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: profile,
        capabilityProfile: capability,
      );

      final expectedFamilies = const [
        'pushup',
        'squat',
        'forearm_plank',
        'glute_bridge',
        'lunge',
        'hinge',
      ];
      for (final familyId in expectedFamilies) {
        final tree = first.treeForFamilyId(familyId);
        expect(tree, isNotNull, reason: familyId);
        expect(tree!.nodes, isNotEmpty, reason: familyId);
        expect(tree.diagnostics, isEmpty, reason: familyId);
      }

      // Deterministic ordering.
      for (final familyId in expectedFamilies) {
        expect(
          second
              .treeForFamilyId(familyId)!
              .nodes
              .map((n) => n.exercise.id)
              .toList(),
          first
              .treeForFamilyId(familyId)!
              .nodes
              .map((n) => n.exercise.id)
              .toList(),
          reason: familyId,
        );
      }

      // Capability status derives from ExerciseDifficulty: nodes at or below
      // the movement level fit; higher ones do not.
      final pushTree = first.treeForFamilyId('pushup')!;
      for (final node in pushTree.nodes) {
        final fits = CapabilityLevel.fromExerciseDifficulty(
                  node.exercise.difficulty,
                ).rank <=
                CapabilityLevel.level3.rank;
        expect(node.fitsCurrentLevel, fits, reason: node.exercise.id);
      }

      // No fake locks/mastery: resolver reports no catalog diagnostics.
      expect(first.diagnostics, isEmpty);
    });

    test('setup fit still reflects profile equipment changes', () {
      final capability = profileAtLevel(CapabilityLevel.level3);

      final withBench = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: userProfile(
          equipment: const {WorkoutEquipment.none, WorkoutEquipment.bench},
        ),
        capabilityProfile: capability,
      );
      final withoutBench = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: userProfile(),
        capabilityProfile: capability,
      );

      final benchNodeWith = withBench
          .treeForFamilyId('pushup')!
          .nodes
          .firstWhere((n) => n.exercise.id == 'pushup_incline');
      final benchNodeWithout = withoutBench
          .treeForFamilyId('pushup')!
          .nodes
          .firstWhere((n) => n.exercise.id == 'pushup_incline');

      expect(benchNodeWith.fitsSetup, isTrue);
      expect(benchNodeWithout.fitsSetup, isFalse);
      expect(
        benchNodeWithout.setupStatus,
        ExerciseSkillTreeSetupStatus.needsSetupChange,
      );
    });
  });

  group('exercise ID compatibility', () {
    test('regression list of referenced IDs all resolve to active exercises',
        () {
      const referencedIds = [
        // Major progression families.
        'pushup_wall', 'pushup_incline', 'pushup_knee', 'pushup_standard',
        'pushup_decline', 'pushup_diamond',
        'squat_chair', 'squat_partial', 'squat_bodyweight', 'squat_tempo',
        'plank_knee', 'plank_forearm',
        'bridge_glute', 'bridge_march', 'bridge_single_leg',
        'squat_split_static', 'lunge_reverse', 'lunge_forward',
        'squat_split_bulgarian',
        'hip_hinge', 'good_morning', 'hip_hinge_single_leg',
        // Warmup/cooldown anchors used by resolvers.
        'march_in_place', 'figure_four_stretch',
        // Capability assessment example anchors.
        'wall_sit', 'dead_bug', 'cat_cow', 'high_knees', 'step_jack',
      ];
      for (final id in referencedIds) {
        final exercise = ExerciseCatalog.byId(id);
        expect(exercise, isNotNull, reason: id);
        expect(exercise!.active, isTrue, reason: id);
      }
    });

    test('assessment anchor names resolve to active exercises with valid '
        'difficulty', () {
      final byName = {
        for (final e in ExerciseCatalog.all) e.name.toLowerCase(): e,
      };
      for (final item in CapabilityAssessmentCatalog.all) {
        for (final example in item.examples) {
          final exercise = byName[example.toLowerCase()];
          expect(exercise, isNotNull, reason: example);
          expect(exercise!.active, isTrue, reason: example);
          expect(exercise.difficulty, isA<ExerciseDifficulty>(),
              reason: example);
          expect(exercise.movementPattern, isNotNull, reason: example);
        }
      }
    });
  });

  group('M13 custom workout compatibility', () {
    final catalogById = {for (final e in ExerciseCatalog.all) e.id: e};

    CustomWorkoutTemplate buildTemplate() => CustomWorkoutTemplate(
          id: 'm20_template',
          name: 'M20 compatibility template',
          targetDuration: WorkoutDuration.fifteenMinutes,
          createdAt: anchorDate,
          updatedAt: anchorDate,
          warmup: const [
            CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place',
              sets: 1,
              workDuration: Duration(seconds: 30),
              restBetweenSets: Duration(seconds: 15),
            ),
          ],
          main: const [
            CustomWorkoutExerciseEntry(
              exerciseId: 'pushup_incline',
              sets: 3,
              repsPerSet: 8,
              restBetweenSets: Duration(seconds: 45),
            ),
          ],
          cooldown: const [
            CustomWorkoutExerciseEntry(
              exerciseId: 'figure_four_stretch',
              sets: 1,
              workDuration: Duration(seconds: 20),
              restBetweenSets: Duration(seconds: 15),
            ),
          ],
        );

    test('template referencing existing IDs resolves without migration', () {
      final template = buildTemplate();
      final resolution = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: userProfile(
          equipment: const {WorkoutEquipment.none, WorkoutEquipment.bench},
        ),
        capabilityProfile: profileAtLevel(CapabilityLevel.level3),
      );
      expect(resolution.plan, isNotNull,
          reason: 'issues: ${resolution.issues}');
      // Template untouched.
      expect(template.main.single.exerciseId, 'pushup_incline');
      expect(template.updatedAt, anchorDate);
    });

    test('eligibility changes truthfully when setup changes', () {
      final template = buildTemplate();
      final resolution = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: userProfile(), // no bench
        capabilityProfile: profileAtLevel(CapabilityLevel.level3),
      );
      // Truthful: either issues are reported or no plan is produced —
      // the resolver must not silently fabricate a substitute.
      expect(resolution.issues, isNotEmpty);
      expect(template.main.single.exerciseId, 'pushup_incline',
          reason: 'stored template must never be rewritten');
    });
  });

  group('M9 smart replacement regression', () {
    test('replacement candidates keep movement/type/eligibility/difficulty '
        'contracts', () {
      final profile = userProfile();
      final capability = profileAtLevel(CapabilityLevel.level3);
      final current = WorkoutExercisePrescription.fromExerciseDefaults(
        ExerciseCatalog.byId('pushup_standard')!,
        sets: 3,
      )!;

      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: current,
        eligibilityContext: ExerciseEligibilityContext.fromProfiles(
          userProfile: profile,
          capabilityProfile: capability,
        ),
        userProfile: profile,
        capabilityProfile: capability,
        effectiveExerciseIdsElsewhere: const {},
      );

      expect(options, isNotEmpty);
      for (final option in options) {
        final candidate = option.prescription.exercise;
        expect(candidate.id, isNot('pushup_standard'));
        expect(candidate.movementPattern, MovementPattern.push,
            reason: candidate.id);
        expect(candidate.exerciseType,
            ExerciseCatalog.byId('pushup_standard')!.exerciseType,
            reason: candidate.id);
        expect(
          candidate.difficulty.index <=
              ExerciseDifficulty.level3.index,
          isTrue,
          reason: '${candidate.id} must not be harder than current',
        );
      }

      // Deterministic.
      final again = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: current,
        eligibilityContext: ExerciseEligibilityContext.fromProfiles(
          userProfile: profile,
          capabilityProfile: capability,
        ),
        userProfile: profile,
        capabilityProfile: capability,
        effectiveExerciseIdsElsewhere: const {},
      );
      expect(
        again.map((o) => o.prescription.exercise.id).toList(),
        options.map((o) => o.prescription.exercise.id).toList(),
      );

      // Duplicate protection.
      final withDuplicate = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: current,
        eligibilityContext: ExerciseEligibilityContext.fromProfiles(
          userProfile: profile,
          capabilityProfile: capability,
        ),
        userProfile: profile,
        capabilityProfile: capability,
        effectiveExerciseIdsElsewhere: {
          for (final option in options) option.prescription.exercise.id,
        },
      );
      for (final option in withDuplicate) {
        expect(
          options.map((o) => o.prescription.exercise.id),
          isNot(contains(option.prescription.exercise.id)),
        );
      }
    });
  });

  group('M10 adaptive progression regression', () {
    test('fromExerciseDifficulty mapping stays identity for all levels', () {
      for (final difficulty in ExerciseDifficulty.values) {
        expect(
          CapabilityLevel.fromExerciseDifficulty(difficulty).rank,
          difficulty.index + 1,
        );
        expect(
          CapabilityLevel.fromExerciseDifficulty(difficulty)
              .toExerciseDifficulty(),
          difficulty,
        );
      }
    });

    test('representative main-set progression still computes decisions', () {
      final capability = profileAtLevel(CapabilityLevel.level2);
      final prescription = WorkoutExercisePrescription.fromExerciseDefaults(
        ExerciseCatalog.byId('pushup_knee')!,
        sets: 2,
      )!;

      final result = AdaptiveProgressionEngine.calculate(
        AdaptiveProgressionInput(
          currentProfile: capability,
          effectiveMainPrescriptions: [prescription],
          feedbackByMovement: const {
            MovementPattern.push: MovementWorkoutFeedback.easy,
          },
          currentEvidence: AdaptiveProgressionEvidence.zero(),
          now: anchorDate,
        ),
      );

      expect(result.updatedProfile.isValid, isTrue);
      expect(result.updatedProfile.capabilityFor(MovementPattern.push),
          isNotNull);
      // Other patterns remain untouched by a push-only session.
      for (final pattern in CapabilityProfile.trainablePatterns) {
        if (pattern == MovementPattern.push) continue;
        expect(result.updatedProfile.capabilityFor(pattern)!.level,
            CapabilityLevel.level2,
            reason: pattern.name);
      }
    });
  });

  group('M16 program generation regression', () {
    test('Balanced Foundations and Strength Foundations sessions resolve', () {
      final capability = profileAtLevel(CapabilityLevel.level2);
      for (final programId in [
        AdaptiveProgramCatalog.balancedFoundationsId,
        AdaptiveProgramCatalog.strengthFoundationsId,
      ]) {
        final definition = AdaptiveProgramCatalog.byId(programId);
        expect(definition, isNotNull, reason: programId);
        final session = definition!.sessions.first;
        final resolution = AdaptiveProgramWorkoutResolver.resolve(
          definition: definition,
          session: session,
          userProfile: userProfile(),
          capabilityProfile: capability,
        );
        expect(resolution.isSuccess, isTrue, reason: programId);
        expect(resolution.plan!.warmup.isNotEmpty, isTrue);
        expect(resolution.plan!.main.isNotEmpty, isTrue);
        expect(resolution.plan!.cooldown.isNotEmpty, isTrue);
      }
    });

    test('setup-restrictive profile yields success or truthful issue', () {
      final definition = AdaptiveProgramCatalog.byId(
        AdaptiveProgramCatalog.balancedFoundationsId,
      )!;
      final session = definition.sessions.first;
      final resolution = AdaptiveProgramWorkoutResolver.resolve(
        definition: definition,
        session: session,
        userProfile: userProfile(
          environment: TrainingEnvironment.apartment,
          preferences: const {
            WorkoutPreference.noJumping,
            WorkoutPreference.lowImpact,
            WorkoutPreference.standingOnly,
          },
        ),
        capabilityProfile: profileAtLevel(CapabilityLevel.level1),
      );
      // Either outcome is acceptable; a fabricated plan is not.
      if (resolution.isSuccess) {
        expect(resolution.plan!.main.isNotEmpty, isTrue);
      } else {
        expect(resolution.issue, isNotNull);
      }
    });
  });

  group('player prescription viability', () {
    test('generated plan prescriptions all remain valid for the Player', () {
      final context = WorkoutGenerationContext(
        userProfile: userProfile(),
        capabilityProfile: profileAtLevel(CapabilityLevel.level3),
      );
      final plan = WorkoutGenerator.generateCatalog(context);
      expect(plan, isNotNull);
      final prescriptions = [
        ...plan!.warmup.exercises,
        ...plan.main.exercises,
        ...plan.cooldown.exercises,
      ];
      expect(prescriptions, isNotEmpty);
      for (final prescription in prescriptions) {
        expect(prescription.isValid, isTrue,
            reason: prescription.exercise.id);
      }
    });
  });
}
