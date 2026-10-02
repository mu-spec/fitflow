import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/quality/exercise_catalog_quality_validator.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_engine.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Milestone 20 Final Stabilization: meaningful selectable-equipment
/// coverage (80 -> 88). Proves the new gear exercises are catalog-shaped
/// correctly, canonically eligible, generator-consumable, searchable, and
/// compatible with M9/M13/M15 without weakening any existing rule.
void main() {
  final anchorDate = DateTime.utc(2026, 10, 2);

  /// The eight stabilization additions, keyed to their required gear.
  const newEquipmentExercises = <String, WorkoutEquipment>{
    'pull_apart_resistance_band': WorkoutEquipment.resistanceBands,
    'row_resistance_band': WorkoutEquipment.resistanceBands,
    'squat_goblet_dumbbell': WorkoutEquipment.dumbbells,
    'row_bent_over_dumbbell': WorkoutEquipment.dumbbells,
    'deadlift_kettlebell': WorkoutEquipment.kettlebell,
    'squat_goblet_kettlebell': WorkoutEquipment.kettlebell,
    'dead_hang_pullup_bar': WorkoutEquipment.pullUpBar,
    'scapular_pullup': WorkoutEquipment.pullUpBar,
  };

  /// Every catalog ID that existed before the stabilization. Preserving all
  /// of them keeps custom workouts, history, skill trees, assessment,
  /// progression, and tests compatible.
  const originalIds = <String>[
    'pushup_wall', 'pushup_incline', 'pushup_knee', 'pushup_standard',
    'pushup_decline', 'squat_chair', 'squat_partial', 'squat_bodyweight',
    'squat_tempo', 'wall_sit', 'dead_bug', 'plank_knee', 'plank_forearm',
    'plank_side', 'hollow_hold', 'bridge_glute', 'bridge_single_leg',
    'march_in_place', 'high_knees', 'jumping_jacks', 'row_doorway',
    'row_towel', 'reverse_snow_angel', 'superman', 'prone_y_raise',
    'lunge_reverse', 'lunge_forward', 'squat_split_static',
    'squat_split_bulgarian', 'calf_raise', 'bird_dog', 'bicycle_crunch',
    'heel_taps', 'reverse_crunch', 'mountain_climbers', 'cat_cow',
    'childs_pose', 'hip_flexor_stretch', 'hamstring_stretch_standing',
    'thoracic_rotation', 'good_morning', 'hip_hinge',
    'hip_hinge_single_leg', 'donkey_kick', 'fire_hydrant', 'pushup_pike',
    'pushup_close_grip', 'pushup_wide', 'shoulder_tap', 'plank_up_down',
    'step_jack', 'butt_kicks', 'skater_step', 'squat_knee_drive',
    'shadow_boxing', 'single_leg_stand', 'standing_knee_raise',
    'ankle_circles', 'arm_circles', 'world_greatest_stretch',
    'pushup_diamond', 'pushup_down_dog', 'wall_shoulder_press',
    'dip_chair', 'squat_sumo', 'squat_pulse', 'lunge_curtsy',
    'lunge_lateral', 'bridge_march', 'frog_pump', 'plank_reach',
    'plank_side_knee', 'russian_twist', 'leg_raise', 'flutter_kicks',
    'burpee_low_impact', 'fast_feet', 'mountain_climber_standing',
    'cobra_stretch', 'figure_four_stretch',
  ];

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
    FitnessGoal goal = FitnessGoal.generalFitness,
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    Set<WorkoutPreference> preferences = const {},
  }) {
    return UserFitnessProfile(
      goal: goal,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: environment,
      equipment: equipment,
      preferences: preferences,
    );
  }

  WorkoutGenerationContext buildContext({
    CapabilityLevel level = CapabilityLevel.level4,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
  }) {
    return WorkoutGenerationContext(
      userProfile: userProfile(
        duration: duration,
        equipment: equipment,
      ),
      capabilityProfile: profileAtLevel(level),
    );
  }

  group('catalog stabilization shape', () {
    test('catalog grows 80 -> 88 preserving every existing ID', () {
      final allIds = ExerciseCatalog.all.map((e) => e.id).toSet();
      expect(allIds, hasLength(88));

      // All 80 original IDs remain resolvable and active.
      for (final id in originalIds) {
        final exercise = ExerciseCatalog.byId(id);
        expect(exercise, isNotNull, reason: 'original id lost: $id');
        expect(exercise!.active, isTrue, reason: id);
      }
      expect(allIds.difference(newEquipmentExercises.keys.toSet()),
          hasLength(80));

      // The 8 new IDs exist, are unique, active, and asset-truthful.
      for (final entry in newEquipmentExercises.entries) {
        final exercise = ExerciseCatalog.byId(entry.key);
        expect(exercise, isNotNull, reason: entry.key);
        expect(exercise!.active, isTrue, reason: entry.key);
        expect(exercise.assetPath, isNull, reason: entry.key);
      }
    });

    test('each new exercise requires exactly its meaningful equipment', () {
      newEquipmentExercises.forEach((id, gear) {
        final exercise = ExerciseCatalog.byId(id)!;
        expect(exercise.requiredEquipment, equals({gear}), reason: id);
        expect(
          exercise.requiredEquipment,
          isNot(contains(WorkoutEquipment.none)),
          reason: '$id must not mix none with real equipment',
        );
        expect(exercise.movementPattern, isNotNull, reason: id);
        expect(exercise.primaryMuscles, isNotEmpty, reason: id);
      });
    });

    test('quality validator stays at zero errors and zero warnings on 88',
        () {
      final report = ExerciseCatalogQualityValidator.validateCatalog();
      expect(report.errors, isEmpty, reason: report.describe());
      expect(report.warnings, isEmpty, reason: report.describe());
    });
  });

  group('canonical eligibility proof per equipment', () {
    newEquipmentExercises.forEach((id, gear) {
      test('$id is missingEquipment without $gear and eligible with it', () {
        final exercise = ExerciseCatalog.byId(id)!;

        final withoutGear = ExerciseEligibilityEngine.evaluate(
          exercise,
          ExerciseEligibilityContext.fromProfiles(
            userProfile: userProfile(equipment: const {}),
            capabilityProfile: profileAtLevel(CapabilityLevel.level5),
          ),
        );
        expect(withoutGear.eligible, isFalse, reason: id);
        expect(
          withoutGear.reasons,
          contains(ExerciseExclusionReason.missingEquipment),
          reason: id,
        );
        expect(withoutGear.missingEquipment, contains(gear), reason: id);

        final withGear = ExerciseEligibilityEngine.evaluate(
          exercise,
          ExerciseEligibilityContext.fromProfiles(
            userProfile: userProfile(equipment: {gear}),
            capabilityProfile: profileAtLevel(CapabilityLevel.level5),
          ),
        );
        expect(withGear.eligible, isTrue,
            reason: '$id reasons: ${withGear.reasons}');
        expect(withGear.missingEquipment, isEmpty, reason: id);
      });
    });
  });

  group('bodyweight remains available with gear selected', () {
    test('dumbbells-only user keeps bodyweight exercises and gains '
        'dumbbell content', () {
      final context = ExerciseEligibilityContext.fromProfiles(
        userProfile: userProfile(
          equipment: const {WorkoutEquipment.dumbbells},
        ),
        capabilityProfile: profileAtLevel(CapabilityLevel.level4),
      );

      // Equipment-free content stays eligible (none is not a hard gate).
      for (final id in const ['squat_bodyweight', 'pushup_standard',
          'plank_forearm']) {
        final result = ExerciseEligibilityEngine.evaluate(
          ExerciseCatalog.byId(id)!,
          context,
        );
        expect(result.eligible, isTrue,
            reason: '$id must survive selecting dumbbells; '
                'reasons: ${result.reasons}');
      }

      // And the gear content becomes eligible.
      final goblet = ExerciseEligibilityEngine.evaluate(
        ExerciseCatalog.byId('squat_goblet_dumbbell')!,
        context,
      );
      expect(goblet.eligible, isTrue, reason: '${goblet.reasons}');
    });

    test('kettlebell-only user keeps bodyweight exercises and gains '
        'kettlebell content', () {
      final context = ExerciseEligibilityContext.fromProfiles(
        userProfile: userProfile(
          equipment: const {WorkoutEquipment.kettlebell},
        ),
        capabilityProfile: profileAtLevel(CapabilityLevel.level4),
      );

      final bodyweight = ExerciseEligibilityEngine.evaluate(
        ExerciseCatalog.byId('bridge_glute')!,
        context,
      );
      expect(bodyweight.eligible, isTrue,
          reason: '${bodyweight.reasons}');

      final deadlift = ExerciseEligibilityEngine.evaluate(
        ExerciseCatalog.byId('deadlift_kettlebell')!,
        context,
      );
      expect(deadlift.eligible, isTrue, reason: '${deadlift.reasons}');
    });
  });

  group('generator and candidate pipeline participation', () {
    const gearScenarios = <WorkoutEquipment, List<String>>{
      WorkoutEquipment.resistanceBands: [
        'pull_apart_resistance_band',
        'row_resistance_band',
      ],
      WorkoutEquipment.dumbbells: [
        'squat_goblet_dumbbell',
        'row_bent_over_dumbbell',
      ],
      WorkoutEquipment.kettlebell: [
        'deadlift_kettlebell',
        'squat_goblet_kettlebell',
      ],
      WorkoutEquipment.pullUpBar: [
        'dead_hang_pullup_bar',
        'scapular_pullup',
      ],
    };

    gearScenarios.forEach((gear, exerciseIds) {
      test('${gear.name} exercises participate in the generation pipeline',
          () {
        // With the gear available the candidate resolver (the generator's
        // own pool seam) admits the new exercises into the main pool and
        // the pool is observably larger than without the gear.
        final withGear = WorkoutCandidateResolver.resolve(
          ExerciseCatalog.all,
          buildContext(equipment: {gear}),
        );
        final withoutGear = WorkoutCandidateResolver.resolve(
          ExerciseCatalog.all,
          buildContext(equipment: const {}),
        );

        final withGearIds =
            withGear.main.map((r) => r.exercise.id).toSet();
        final withoutGearIds =
            withoutGear.main.map((r) => r.exercise.id).toSet();
        for (final id in exerciseIds) {
          expect(withGearIds, contains(id),
              reason: '$id must be a ranked main-pool candidate when '
                  '${gear.name} is available');
          expect(withoutGearIds, isNot(contains(id)),
              reason: '$id must be missingEquipment without the gear');
        }
        expect(withGearIds.length, greaterThan(withoutGearIds.length),
            reason: 'selecting ${gear.name} must observably expand the '
                'eligible pool');

        // And normal generation with the gear produces a valid plan whose
        // every exercise is canonically eligible.
        final context = buildContext(equipment: {gear});
        final plan = WorkoutGenerator.generateCatalog(context);
        expect(plan, isNotNull,
            reason: 'generation with ${gear.name} available must remain '
                'viable at level 4 home setup');
        expect(plan!.warmup.isNotEmpty, isTrue);
        expect(plan.main.isNotEmpty, isTrue);
        expect(plan.cooldown.isNotEmpty, isTrue);
        final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: context.userProfile,
          capabilityProfile: context.effectiveCapabilityProfile,
        );
        for (final prescription in [
          ...plan.warmup.exercises,
          ...plan.main.exercises,
          ...plan.cooldown.exercises,
        ]) {
          final result = ExerciseEligibilityEngine.evaluate(
            prescription.exercise,
            eligibilityContext,
          );
          expect(result.eligible, isTrue,
              reason: '${prescription.exercise.id} in plan; '
                  'reasons: ${result.reasons}');
        }
      });
    });

    test('representative sweep selects new gear content in at least one '
        'matching context', () {
      // Equipment expands choices; it is not a mandatory-use promise. But
      // if deterministic ranking never selects any new exercise in any
      // reasonable matching context, the content would be dead weight and
      // that deserves investigation.
      final selected = <String>{};
      for (final level in const [
        CapabilityLevel.level3,
        CapabilityLevel.level4,
        CapabilityLevel.level5,
      ]) {
        for (final duration in const [
          WorkoutDuration.fifteenMinutes,
          WorkoutDuration.twentyMinutes,
          WorkoutDuration.thirtyMinutes,
        ]) {
          for (final goal in const [
            FitnessGoal.generalFitness,
            FitnessGoal.buildMuscle,
            FitnessGoal.loseWeight,
          ]) {
            final context = WorkoutGenerationContext(
              userProfile: userProfile(
                goal: goal,
                duration: duration,
                equipment: const {
                  WorkoutEquipment.resistanceBands,
                  WorkoutEquipment.dumbbells,
                  WorkoutEquipment.kettlebell,
                  WorkoutEquipment.pullUpBar,
                },
              ),
              capabilityProfile: profileAtLevel(level),
            );
            final plan = WorkoutGenerator.generateCatalog(context);
            // A truthful generation issue is acceptable for any single
            // context; the sweep only needs plans that do materialize.
            if (plan == null) continue;
            for (final prescription in [
              ...plan.warmup.exercises,
              ...plan.main.exercises,
              ...plan.cooldown.exercises,
            ]) {
              if (newEquipmentExercises
                  .containsKey(prescription.exercise.id)) {
                selected.add(prescription.exercise.id);
              }
            }
          }
        }
      }
      expect(selected, isNotEmpty,
          reason: 'no new gear exercise was ever selected by deterministic '
              'ranking across 27 reasonable matching contexts; investigate '
              'the ranking, do not weaken it');
    });
  });

  group('search finds new gear content', () {
    test('"band" finds both resistance-band exercises', () {
      final results = applyExerciseLibraryFilter(
        ExerciseCatalog.all,
        const ExerciseLibraryFilter(searchQuery: 'band'),
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(const [
        'pull_apart_resistance_band',
        'row_resistance_band',
      ]));
    });

    test('"kettlebell" finds both kettlebell exercises', () {
      final results = applyExerciseLibraryFilter(
        ExerciseCatalog.all,
        const ExerciseLibraryFilter(searchQuery: 'kettlebell'),
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(const [
        'deadlift_kettlebell',
        'squat_goblet_kettlebell',
      ]));
    });

    test('"pull-up" finds both pull-up-bar exercises', () {
      final results = applyExerciseLibraryFilter(
        ExerciseCatalog.all,
        const ExerciseLibraryFilter(searchQuery: 'pull-up'),
      );
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(const [
        'dead_hang_pullup_bar',
        'scapular_pullup',
      ]));
    });
  });

  group('M13 custom workout compatibility', () {
    final catalogById = {for (final e in ExerciseCatalog.all) e.id: e};

    CustomWorkoutTemplate buildTemplate() => CustomWorkoutTemplate(
          id: 'm20_gear_template',
          name: 'M20 gear template',
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
              exerciseId: 'row_resistance_band',
              sets: 3,
              repsPerSet: 12,
              restBetweenSets: Duration(seconds: 30),
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

    test('new gear exercise saves and resolves with the gear available',
        () {
      final resolution = CustomWorkoutPlanResolver.resolve(
        template: buildTemplate(),
        catalogById: catalogById,
        userFitnessProfile: userProfile(
          equipment: const {
            WorkoutEquipment.none,
            WorkoutEquipment.resistanceBands,
          },
        ),
        capabilityProfile: profileAtLevel(CapabilityLevel.level3),
      );
      expect(resolution.plan, isNotNull,
          reason: 'issues: ${resolution.issues}');
      final mainIds = resolution.plan!.main.exercises
          .map((p) => p.exercise.id)
          .toList();
      expect(mainIds, contains('row_resistance_band'));
    });

    test('same template is truthfully unresolved without the gear and is '
        'never rewritten', () {
      final template = buildTemplate();
      final resolution = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: userProfile(
          equipment: const {WorkoutEquipment.none},
        ),
        capabilityProfile: profileAtLevel(CapabilityLevel.level3),
      );
      expect(resolution.issues, isNotEmpty);
      expect(template.main.single.exerciseId, 'row_resistance_band',
          reason: 'stored template must never be rewritten');
    });
  });

  group('M9 smart replacement invariants with gear', () {
    test('new gear exercises only surface through existing replacement '
        'contracts', () {
      final profile = userProfile(
        equipment: const {
          WorkoutEquipment.none,
          WorkoutEquipment.resistanceBands,
        },
      );
      final capability = profileAtLevel(CapabilityLevel.level3);
      final current = WorkoutExercisePrescription.fromExerciseDefaults(
        ExerciseCatalog.byId('row_doorway')!,
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
        expect(candidate.id, isNot('row_doorway'));
        expect(candidate.movementPattern, MovementPattern.pull,
            reason: candidate.id);
        expect(candidate.exerciseType,
            ExerciseCatalog.byId('row_doorway')!.exerciseType,
            reason: candidate.id);
        expect(
          candidate.difficulty.index <= ExerciseDifficulty.level2.index,
          isTrue,
          reason: '${candidate.id} must not be harder than row_doorway',
        );
      }
      expect(
        options.map((o) => o.prescription.exercise.id).toSet(),
        hasLength(options.length),
        reason: 'replacement options must not duplicate',
      );
    });
  });

  group('M15 skill trees unaffected', () {
    test('exactly the six major families exist; standalone gear exercises '
        'stay out of trees', () {
      final catalog = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: userProfile(),
        capabilityProfile: profileAtLevel(CapabilityLevel.level3),
      );

      expect(
        catalog.trees.map((tree) => tree.familyId).toSet(),
        const {
          'pushup',
          'squat',
          'forearm_plank',
          'glute_bridge',
          'lunge',
          'hinge',
        },
      );
      expect(catalog.diagnostics, isEmpty);

      final treeExerciseIds = catalog.trees
          .expand((tree) => tree.nodes)
          .map((node) => node.exercise.id)
          .toSet();
      for (final id in newEquipmentExercises.keys) {
        expect(treeExerciseIds, isNot(contains(id)),
            reason: '$id is standalone and must not join a skill tree '
                'without a genuine progression family');
      }
    });
  });
}
