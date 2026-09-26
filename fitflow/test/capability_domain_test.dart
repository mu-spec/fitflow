import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Trainable patterns', () {
    test('exactly 10 capability patterns', () {
      expect(CapabilityProfile.trainablePatterns.length, 10);
      expect(CapabilityProfile.trainablePatterns, containsAll([
        MovementPattern.push,
        MovementPattern.pull,
        MovementPattern.squat,
        MovementPattern.lunge,
        MovementPattern.hinge,
        MovementPattern.core,
        MovementPattern.glute,
        MovementPattern.cardio,
        MovementPattern.mobility,
        MovementPattern.balance,
      ]));
    });

    test('warmup excluded', () {
      expect(CapabilityProfile.trainablePatterns, isNot(contains(MovementPattern.warmup)));
    });

    test('cooldown excluded', () {
      expect(CapabilityProfile.trainablePatterns, isNot(contains(MovementPattern.cooldown)));
    });
  });

  group('Initial profile', () {
    test('contains exactly 10 entries', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      expect(profile.capabilities.length, 10);
      expect(profile.all.length, 10);
      expect(profile.isComplete, true);
      expect(profile.isValid, true);
    });

    test('every required movement exists', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      for (final pattern in CapabilityProfile.trainablePatterns) {
        expect(profile.capabilityFor(pattern), isNotNull, reason: pattern.name);
        expect(profile[pattern], isNotNull, reason: pattern.name);
      }
    });

    test('default levels are Level 1', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      for (final cap in profile.all) {
        expect(cap.level, CapabilityLevel.level1, reason: cap.movementPattern.name);
      }
    });

    test('source is initialAssessment', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      for (final cap in profile.all) {
        expect(cap.source, CapabilitySource.initialAssessment);
      }
    });

    test('timestamp is deterministic', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final profile = CapabilityProfile.initial(updatedAt: now);
      for (final cap in profile.all) {
        expect(cap.updatedAt, now);
      }
      // Different timestamp creates different profile
      final later = DateTime.utc(2026, 2, 1);
      final profile2 = CapabilityProfile.initial(updatedAt: later);
      expect(profile2.all.first.updatedAt, later);
      expect(profile, isNot(profile2));
    });

    test('defaultProfile alias works same as initial', () {
      final now = DateTime.utc(2026, 1, 1);
      final p1 = CapabilityProfile.initial(updatedAt: now);
      final p2 = CapabilityProfile.defaultProfile(updatedAt: now);
      expect(p1, p2);
    });
  });

  group('Lookup', () {
    test('Push returns Push capability', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      final push = profile.capabilityFor(MovementPattern.push);
      expect(push, isNotNull);
      expect(push!.movementPattern, MovementPattern.push);
      expect(profile[MovementPattern.push]!.movementPattern, MovementPattern.push);
    });

    test('Core returns Core capability', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      final core = profile.capabilityFor(MovementPattern.core);
      expect(core, isNotNull);
      expect(core!.movementPattern, MovementPattern.core);
    });

    test('unsupported warmup/cooldown lookup behaves safely', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      expect(profile.capabilityFor(MovementPattern.warmup), isNull);
      expect(profile.capabilityFor(MovementPattern.cooldown), isNull);
      expect(profile[MovementPattern.warmup], isNull);
      expect(profile[MovementPattern.cooldown], isNull);
      // Should not throw
      expect(() => profile.capabilityFor(MovementPattern.warmup), returnsNormally);
    });
  });

  group('Immutable update', () {
    test('updating Squat only changes Squat', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      final later = DateTime.utc(2026, 1, 2);
      final updatedSquat = MovementCapability(
        movementPattern: MovementPattern.squat,
        level: CapabilityLevel.level3,
        source: CapabilitySource.workoutFeedback,
        updatedAt: later,
        anchorExerciseId: 'squat_bodyweight',
      );

      final newProfile = profile.withCapability(updatedSquat);

      // Squat changed
      expect(newProfile.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level3);
      expect(newProfile.capabilityFor(MovementPattern.squat)!.source, CapabilitySource.workoutFeedback);
      expect(newProfile.capabilityFor(MovementPattern.squat)!.updatedAt, later);
      expect(newProfile.capabilityFor(MovementPattern.squat)!.anchorExerciseId, 'squat_bodyweight');

      // Others unchanged
      expect(newProfile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level1);
      expect(newProfile.capabilityFor(MovementPattern.core)!.level, CapabilityLevel.level1);
      expect(newProfile.capabilities.length, 10);
    });

    test('original profile remains unchanged', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      final originalSquatLevel = profile.capabilityFor(MovementPattern.squat)!.level;

      final updated = MovementCapability(
        movementPattern: MovementPattern.squat,
        level: CapabilityLevel.level5,
        source: CapabilitySource.manualAdjustment,
        updatedAt: DateTime.utc(2026, 1, 3),
      );

      final newProfile = profile.withCapability(updated);

      // Original unchanged
      expect(profile.capabilityFor(MovementPattern.squat)!.level, originalSquatLevel);
      expect(profile.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level1);
      // New changed
      expect(newProfile.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level5);
      expect(identical(profile, newProfile), false);
    });

    test('updating with warmup returns self unchanged', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      final invalid = MovementCapability(
        movementPattern: MovementPattern.warmup,
        level: CapabilityLevel.level1,
        source: CapabilitySource.initialAssessment,
        updatedAt: now,
      );
      final newProfile = profile.withCapability(invalid);
      expect(identical(newProfile, profile), true);
      expect(newProfile.isValid, true);
    });
  });

  group('Validation', () {
    test('warmup capability is invalid', () {
      final cap = MovementCapability(
        movementPattern: MovementPattern.warmup,
        level: CapabilityLevel.level1,
        source: CapabilitySource.initialAssessment,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(cap.isValid, false);
      expect(cap.validate(), isNotEmpty);
      expect(cap.validate().first, contains('warmup'));
    });

    test('cooldown capability is invalid', () {
      final cap = MovementCapability(
        movementPattern: MovementPattern.cooldown,
        level: CapabilityLevel.level2,
        source: CapabilitySource.initialAssessment,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(cap.isValid, false);
      expect(cap.validate(), isNotEmpty);
    });

    test('valid trainable capability is valid', () {
      final cap = MovementCapability(
        movementPattern: MovementPattern.push,
        level: CapabilityLevel.level3,
        source: CapabilitySource.progression,
        updatedAt: DateTime.utc(2026, 1, 1),
        anchorExerciseId: 'pushup_knee',
      );
      expect(cap.isValid, true);
      expect(cap.validate(), isEmpty);
    });

    test('empty anchorExerciseId is invalid', () {
      final cap = MovementCapability(
        movementPattern: MovementPattern.push,
        level: CapabilityLevel.level1,
        source: CapabilitySource.initialAssessment,
        updatedAt: DateTime.utc(2026, 1, 1),
        anchorExerciseId: '   ',
      );
      expect(cap.isValid, false);
    });
  });

  group('Level helpers', () {
    test('Level 5 > Level 3', () {
      expect(CapabilityLevel.level5.isHigherThan(CapabilityLevel.level3), true);
      expect(CapabilityLevel.level3.isHigherThan(CapabilityLevel.level5), false);
      expect(CapabilityLevel.level5.rank > CapabilityLevel.level3.rank, true);
    });

    test('Level 1 < Level 2', () {
      expect(CapabilityLevel.level1.isLowerThan(CapabilityLevel.level2), true);
      expect(CapabilityLevel.level2.isLowerThan(CapabilityLevel.level1), false);
    });

    test('equal levels behave correctly', () {
      expect(CapabilityLevel.level3.isHigherThan(CapabilityLevel.level3), false);
      expect(CapabilityLevel.level3.isLowerThan(CapabilityLevel.level3), false);
      expect(CapabilityLevel.level3.rank, CapabilityLevel.level3.rank);
    });

    test('rank 1-5', () {
      expect(CapabilityLevel.level1.rank, 1);
      expect(CapabilityLevel.level2.rank, 2);
      expect(CapabilityLevel.level3.rank, 3);
      expect(CapabilityLevel.level4.rank, 4);
      expect(CapabilityLevel.level5.rank, 5);
    });

    test('label is Level X', () {
      expect(CapabilityLevel.level1.label, 'Level 1');
      expect(CapabilityLevel.level5.label, 'Level 5');
    });
  });

  group('Difficulty mapping', () {
    test('Capability Level 1 maps to Exercise Difficulty Level 1', () {
      expect(CapabilityLevel.level1.toExerciseDifficulty(), ExerciseDifficulty.level1);
    });

    test('Level 5 maps to Level 5', () {
      expect(CapabilityLevel.level5.toExerciseDifficulty(), ExerciseDifficulty.level5);
    });

    test('all levels map correctly', () {
      expect(CapabilityLevel.level1.toExerciseDifficulty(), ExerciseDifficulty.level1);
      expect(CapabilityLevel.level2.toExerciseDifficulty(), ExerciseDifficulty.level2);
      expect(CapabilityLevel.level3.toExerciseDifficulty(), ExerciseDifficulty.level3);
      expect(CapabilityLevel.level4.toExerciseDifficulty(), ExerciseDifficulty.level4);
      expect(CapabilityLevel.level5.toExerciseDifficulty(), ExerciseDifficulty.level5);
    });

    test('reverse mapping works', () {
      expect(CapabilityLevel.fromExerciseDifficulty(ExerciseDifficulty.level1), CapabilityLevel.level1);
      expect(CapabilityLevel.fromExerciseDifficulty(ExerciseDifficulty.level2), CapabilityLevel.level2);
      expect(CapabilityLevel.fromExerciseDifficulty(ExerciseDifficulty.level3), CapabilityLevel.level3);
      expect(CapabilityLevel.fromExerciseDifficulty(ExerciseDifficulty.level4), CapabilityLevel.level4);
      expect(CapabilityLevel.fromExerciseDifficulty(ExerciseDifficulty.level5), CapabilityLevel.level5);
    });

    test('round-trip mapping', () {
      for (final level in CapabilityLevel.values) {
        final diff = level.toExerciseDifficulty();
        final back = CapabilityLevel.fromExerciseDifficulty(diff);
        expect(back, level);
      }
      for (final diff in ExerciseDifficulty.values) {
        final level = CapabilityLevel.fromExerciseDifficulty(diff);
        final back = level.toExerciseDifficulty();
        expect(back, diff);
      }
    });
  });

  group('Collections immutability', () {
    test('external code cannot mutate the profile capability map', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      expect(() => profile.capabilities.clear(), throwsUnsupportedError);
      expect(() => profile.capabilities[MovementPattern.push] = MovementCapability(
            movementPattern: MovementPattern.push,
            level: CapabilityLevel.level5,
            source: CapabilitySource.manualAdjustment,
            updatedAt: now,
          ), throwsUnsupportedError);
      expect(profile.capabilities.length, 10);
    });

    test('all list is unmodifiable', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      expect(() => profile.all.clear(), throwsUnsupportedError);
    });

    test('fromMap defensive copy', () {
      final now = DateTime.utc(2026, 1, 1);
      final originalMap = <MovementPattern, MovementCapability>{};
      for (final p in CapabilityProfile.trainablePatterns) {
        originalMap[p] = MovementCapability(
          movementPattern: p,
          level: CapabilityLevel.level1,
          source: CapabilitySource.initialAssessment,
          updatedAt: now,
        );
      }
      final profile = CapabilityProfile.fromMap(originalMap);
      // Mutate original map
      originalMap.clear();
      expect(profile.capabilities.length, 10);
      expect(profile.isComplete, true);
    });
  });

  group('Equality and serialization', () {
    test('equality works', () {
      final now = DateTime.utc(2026, 1, 1);
      final p1 = CapabilityProfile.initial(updatedAt: now);
      final p2 = CapabilityProfile.initial(updatedAt: now);
      expect(p1, p2);
      expect(p1.hashCode, p2.hashCode);
    });

    test('toJson/fromJson round-trip', () {
      final now = DateTime.utc(2026, 1, 1);
      final profile = CapabilityProfile.initial(updatedAt: now);
      final json = profile.toJson();
      final restored = CapabilityProfile.fromJson(json);
      expect(restored, isNotNull);
      expect(restored, profile);
    });

    test('fromJson ignores warmup/cooldown safely', () {
      final now = DateTime.utc(2026, 1, 1);
      final json = {
        'capabilities': [
          {
            'movementPattern': 'push',
            'level': 'level3',
            'source': 'initialAssessment',
            'updatedAt': now.toIso8601String(),
          },
          {
            'movementPattern': 'warmup',
            'level': 'level1',
            'source': 'initialAssessment',
            'updatedAt': now.toIso8601String(),
          },
          {
            'movementPattern': 'cooldown',
            'level': 'level1',
            'source': 'initialAssessment',
            'updatedAt': now.toIso8601String(),
          },
        ]
      };
      final profile = CapabilityProfile.fromJson(json);
      expect(profile, isNotNull);
      expect(profile!.capabilities.length, 1);
      expect(profile.capabilityFor(MovementPattern.push), isNotNull);
      expect(profile.capabilityFor(MovementPattern.warmup), isNull);
    });

    test('fromJson malformed entries do not crash', () {
      final json = {
        'capabilities': [
          {'invalid': 'data'},
          {
            'movementPattern': 'push',
            'level': 'invalidLevel',
            'source': 'initialAssessment',
            'updatedAt': 'not-a-date',
          },
          {
            'movementPattern': 'unknownPattern',
            'level': 'level1',
            'source': 'initialAssessment',
            'updatedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
          },
        ]
      };
      expect(() => CapabilityProfile.fromJson(json), returnsNormally);
      final profile = CapabilityProfile.fromJson(json);
      expect(profile, isNotNull);
      expect(profile!.capabilities.length, 0);
    });

    test('MovementCapability fromJson rejects warmup/cooldown', () {
      final now = DateTime.utc(2026, 1, 1);
      final warmupJson = {
        'movementPattern': 'warmup',
        'level': 'level1',
        'source': 'initialAssessment',
        'updatedAt': now.toIso8601String(),
      };
      expect(MovementCapability.fromJson(warmupJson), isNull);
      final cooldownJson = {
        'movementPattern': 'cooldown',
        'level': 'level1',
        'source': 'initialAssessment',
        'updatedAt': now.toIso8601String(),
      };
      expect(MovementCapability.fromJson(cooldownJson), isNull);
    });
  });
}
