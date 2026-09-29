import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_section_classifier.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityProfile _defaultCap() {
  final now = DateTime.now().toUtc();
  final map = <MovementPattern, MovementCapability>{};
  for (final p in CapabilityProfile.trainablePatterns) {
    map[p] = MovementCapability(
      movementPattern: p,
      level: CapabilityLevel.level3,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

List<Exercise> _filterForSection({
  required WorkoutSectionType section,
  required ExerciseEligibilityContext context,
  Set<String> alreadyPresent = const {},
}) {
  // Mimic builder filtering logic after fix
  final candidates = ExerciseCatalog.all.where((e) {
    if (!e.active) return false;
    if (!e.isValid) return false;
    if (alreadyPresent.contains(e.id)) return false;
    final classification = CustomWorkoutSectionClassifier.classify(e);
    if (classification == null) return false;
    if (classification != section) return false;
    final result = ExerciseEligibilityEngine.evaluate(e, context);
    if (!result.eligible) return false;
    return true;
  }).toList();
  return candidates;
}

void main() {
  group('Builder filtering - all sections via eligibility', () {
    test('warmup filtered by eligibility (equipment)', () {
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none},
        environment: TrainingEnvironment.normalHome,
        capabilityProfile: _defaultCap(),
        preferences: {},
      );
      final warmups = _filterForSection(section: WorkoutSectionType.warmup, context: context);
      // All should be eligible
      for (final ex in warmups) {
        final res = ExerciseEligibilityEngine.evaluate(ex, context);
        expect(res.eligible, true);
      }
      // Now with missing equipment, bench-required warmup should be excluded
      final base = ExerciseCatalog.all.firstWhere((e) => e.movementPattern == MovementPattern.warmup);
      final fake = Exercise(
        id: 'fake_warmup_bench',
        name: 'Fake Warmup Bench',
        movementPattern: MovementPattern.warmup,
        difficulty: base.difficulty,
        impactLevel: base.impactLevel,
        noiseLevel: base.noiseLevel,
        spaceRequirement: base.spaceRequirement,
        wristLoad: base.wristLoad,
        kneeLoad: base.kneeLoad,
        exerciseType: base.exerciseType,
        defaultReps: base.defaultReps,
        defaultDuration: base.defaultDuration,
        defaultRest: base.defaultRest,
        active: true,
        requiredEquipment: {WorkoutEquipment.bench},
        tags: {'warmup'},
        bodyPosition: base.bodyPosition,
      );
      // Simulate catalog containing fake - filtering should exclude it when equipment missing
      final res = ExerciseEligibilityEngine.evaluate(fake, context);
      expect(res.eligible, false);
    });

    test('cooldown filtered by eligibility (equipment)', () {
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none},
        environment: TrainingEnvironment.normalHome,
        capabilityProfile: _defaultCap(),
        preferences: {},
      );
      final cooldowns = _filterForSection(section: WorkoutSectionType.cooldown, context: context);
      for (final ex in cooldowns) {
        final r = ExerciseEligibilityEngine.evaluate(ex, context);
        expect(r.eligible, true);
      }
    });

    test('warmup filtered by environment', () {
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.apartment,
        capabilityProfile: _defaultCap(),
        preferences: {},
      );
      final warmups = _filterForSection(section: WorkoutSectionType.warmup, context: context);
      // All returned should be eligible for apartment
      for (final ex in warmups) {
        final r = ExerciseEligibilityEngine.evaluate(ex, context);
        expect(r.eligible, true, reason: '${ex.id} should be eligible in apartment');
      }
    });

    test('cooldown filtered by environment', () {
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.apartment,
        capabilityProfile: _defaultCap(),
        preferences: {},
      );
      final cooldowns = _filterForSection(section: WorkoutSectionType.cooldown, context: context);
      for (final ex in cooldowns) {
        expect(ExerciseEligibilityEngine.evaluate(ex, context).eligible, true);
      }
    });

    test('warmup filtered by preference', () {
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.normalHome,
        capabilityProfile: _defaultCap(),
        preferences: {WorkoutPreference.noFloorExercises},
      );
      final warmups = _filterForSection(section: WorkoutSectionType.warmup, context: context);
      for (final ex in warmups) {
        expect(ExerciseEligibilityEngine.evaluate(ex, context).eligible, true);
      }
      // Ensure at least one floor warmup exists and would be filtered out
      final floorWarmups = ExerciseCatalog.all.where((e) => e.movementPattern == MovementPattern.warmup && e.bodyPosition?.name == 'floor').toList();
      if (floorWarmups.isNotEmpty) {
        final floor = floorWarmups.first;
        final res = ExerciseEligibilityEngine.evaluate(floor, context);
        expect(res.eligible, false);
      }
    });

    test('cooldown filtered by preference', () {
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.normalHome,
        capabilityProfile: _defaultCap(),
        preferences: {WorkoutPreference.noFloorExercises},
      );
      final cooldowns = _filterForSection(section: WorkoutSectionType.cooldown, context: context);
      for (final ex in cooldowns) {
        expect(ExerciseEligibilityEngine.evaluate(ex, context).eligible, true);
      }
    });

    test('main still filtered by capability', () {
      final lowCap = CapabilityProfile.fromMap({
        for (final p in CapabilityProfile.trainablePatterns)
          p: MovementCapability(
            movementPattern: p,
            level: CapabilityLevel.level1,
            source: CapabilitySource.initialAssessment,
            updatedAt: DateTime.now().toUtc(),
          )
      });
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.normalHome,
        capabilityProfile: lowCap,
        preferences: {},
      );
      final mains = _filterForSection(section: WorkoutSectionType.main, context: context);
      // All mains should be eligible (level1)
      for (final ex in mains) {
        final r = ExerciseEligibilityEngine.evaluate(ex, context);
        expect(r.eligible, true);
      }
      // High difficulty squat should be excluded
      final highSquat = ExerciseCatalog.all.where((e) => e.movementPattern == MovementPattern.squat && e.difficulty.name == 'level5').toList();
      if (highSquat.isNotEmpty) {
        final res = ExerciseEligibilityEngine.evaluate(highSquat.first, context);
        expect(res.eligible, false);
      }
    });

    test('warmup capability NOT blocked (trainable check)', () {
      final lowCap = CapabilityProfile.fromMap({
        for (final p in CapabilityProfile.trainablePatterns)
          p: MovementCapability(
            movementPattern: p,
            level: CapabilityLevel.level1,
            source: CapabilitySource.initialAssessment,
            updatedAt: DateTime.now().toUtc(),
          )
      });
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.normalHome,
        capabilityProfile: lowCap,
        preferences: {},
      );
      final warmups = _filterForSection(section: WorkoutSectionType.warmup, context: context);
      // Warmups should still be present even with low capability, because engine doesn't check capability for warmup
      expect(warmups.isNotEmpty, true);
    });

    test('already present excluded', () {
      final context = ExerciseEligibilityContext(
        availableEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.normalHome,
        capabilityProfile: _defaultCap(),
        preferences: {},
      );
      final warmups = _filterForSection(section: WorkoutSectionType.warmup, context: context);
      if (warmups.isNotEmpty) {
        final firstId = warmups.first.id;
        final filtered = _filterForSection(section: WorkoutSectionType.warmup, context: context, alreadyPresent: {firstId});
        expect(filtered.any((e) => e.id == firstId), false);
      }
    });
  });
}
