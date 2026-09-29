import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_adaptation_policy.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityProfile fullProfile(CapabilityLevel level, {DateTime? updatedAt}) {
  final now = updatedAt ?? DateTime.utc(2026, 1, 1);
  final map = <MovementPattern, MovementCapability>{};
  for (final p in CapabilityProfile.trainablePatterns) {
    map[p] = MovementCapability(
      movementPattern: p,
      level: level,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
      anchorExerciseId: 'anchor_${p.name}',
    );
  }
  return CapabilityProfile.fromMap(map);
}

void main() {
  group('WorkoutSessionAdaptationPolicy', () {
    test('standard effective duration equals normal', () {
      for (final dur in WorkoutDuration.values) {
        final persisted = fullProfile(CapabilityLevel.level3);
        final adaptation = WorkoutSessionAdaptationPolicy.adapt(
          normalDuration: dur,
          persistedCapability: persisted,
          mode: WorkoutSessionMode.standard,
        );
        expect(adaptation.effectiveWorkoutDuration, dur, reason: 'Standard $dur');
        expect(adaptation.effectiveCapabilityProfile, persisted);
        expect(adaptation.explanation, isNull);
      }
    });

    test('low energy duration mapping', () {
      final persisted = fullProfile(CapabilityLevel.level3);
      final mapping = {
        WorkoutDuration.fiveMinutes: WorkoutDuration.fiveMinutes,
        WorkoutDuration.tenMinutes: WorkoutDuration.fiveMinutes,
        WorkoutDuration.fifteenMinutes: WorkoutDuration.tenMinutes,
        WorkoutDuration.twentyMinutes: WorkoutDuration.fifteenMinutes,
        WorkoutDuration.thirtyMinutes: WorkoutDuration.twentyMinutes,
        WorkoutDuration.fortyFiveMinutes: WorkoutDuration.thirtyMinutes,
      };
      mapping.forEach((normal, expected) {
        final adaptation = WorkoutSessionAdaptationPolicy.adapt(
          normalDuration: normal,
          persistedCapability: persisted,
          mode: WorkoutSessionMode.lowEnergy,
        );
        expect(adaptation.effectiveWorkoutDuration, expected, reason: 'LowEnergy $normal -> $expected');
      });
    });

    test('comeback duration mapping', () {
      final persisted = fullProfile(CapabilityLevel.level3);
      final mapping = {
        WorkoutDuration.fiveMinutes: WorkoutDuration.fiveMinutes,
        WorkoutDuration.tenMinutes: WorkoutDuration.fiveMinutes,
        WorkoutDuration.fifteenMinutes: WorkoutDuration.tenMinutes,
        WorkoutDuration.twentyMinutes: WorkoutDuration.tenMinutes,
        WorkoutDuration.thirtyMinutes: WorkoutDuration.fifteenMinutes,
        WorkoutDuration.fortyFiveMinutes: WorkoutDuration.fifteenMinutes,
      };
      mapping.forEach((normal, expected) {
        final adaptation = WorkoutSessionAdaptationPolicy.adapt(
          normalDuration: normal,
          persistedCapability: persisted,
          mode: WorkoutSessionMode.comeback,
        );
        expect(adaptation.effectiveWorkoutDuration, expected, reason: 'Comeback $normal -> $expected');
      });
    });

    test('low energy capability reduce one level', () {
      final persisted = fullProfile(CapabilityLevel.level3);
      final adaptation = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.twentyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.lowEnergy,
      );
      for (final pattern in CapabilityProfile.trainablePatterns) {
        final cap = adaptation.effectiveCapabilityProfile.capabilities[pattern];
        expect(cap, isNotNull);
        expect(cap!.level, CapabilityLevel.level2, reason: 'L3 -> L2 for $pattern');
      }
    });

    test('comeback capability reduce one level', () {
      final persisted = fullProfile(CapabilityLevel.level4);
      final adaptation = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.thirtyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.comeback,
      );
      for (final pattern in CapabilityProfile.trainablePatterns) {
        final cap = adaptation.effectiveCapabilityProfile.capabilities[pattern];
        expect(cap!.level, CapabilityLevel.level3);
      }
    });

    test('floor L1 preserved', () {
      final persisted = fullProfile(CapabilityLevel.level1);
      for (final mode in [WorkoutSessionMode.lowEnergy, WorkoutSessionMode.comeback]) {
        final adaptation = WorkoutSessionAdaptationPolicy.adapt(
          normalDuration: WorkoutDuration.twentyMinutes,
          persistedCapability: persisted,
          mode: mode,
        );
        for (final pattern in CapabilityProfile.trainablePatterns) {
          final cap = adaptation.effectiveCapabilityProfile.capabilities[pattern];
          expect(cap!.level, CapabilityLevel.level1, reason: 'Floor L1 for $mode $pattern');
        }
      }
    });

    test('preserves source, updatedAt, anchor', () {
      final now = DateTime.utc(2025, 12, 25, 10, 30);
      final persisted = fullProfile(CapabilityLevel.level3, updatedAt: now);
      final adaptation = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.twentyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.lowEnergy,
      );
      for (final pattern in CapabilityProfile.trainablePatterns) {
        final orig = persisted.capabilities[pattern]!;
        final eff = adaptation.effectiveCapabilityProfile.capabilities[pattern]!;
        expect(eff.source, orig.source);
        expect(eff.updatedAt, orig.updatedAt);
        expect(eff.anchorExerciseId, orig.anchorExerciseId);
      }
    });

    test('standard does not reduce', () {
      final persisted = fullProfile(CapabilityLevel.level5);
      final adaptation = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.twentyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.standard,
      );
      for (final pattern in CapabilityProfile.trainablePatterns) {
        expect(adaptation.effectiveCapabilityProfile.capabilities[pattern]!.level, CapabilityLevel.level5);
      }
    });

    test('level5 -> level4, level4->3, level3->2, level2->1', () {
      final levels = {
        CapabilityLevel.level5: CapabilityLevel.level4,
        CapabilityLevel.level4: CapabilityLevel.level3,
        CapabilityLevel.level3: CapabilityLevel.level2,
        CapabilityLevel.level2: CapabilityLevel.level1,
        CapabilityLevel.level1: CapabilityLevel.level1,
      };
      levels.forEach((input, expected) {
        final persisted = fullProfile(input);
        final adaptation = WorkoutSessionAdaptationPolicy.adapt(
          normalDuration: WorkoutDuration.twentyMinutes,
          persistedCapability: persisted,
          mode: WorkoutSessionMode.lowEnergy,
        );
        final cap = adaptation.effectiveCapabilityProfile.capabilities[MovementPattern.push]!;
        expect(cap.level, expected, reason: '$input -> $expected');
      });
    });

    test('deterministic same inputs same output', () {
      final persisted = fullProfile(CapabilityLevel.level3);
      final a1 = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.thirtyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.lowEnergy,
      );
      final a2 = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.thirtyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.lowEnergy,
      );
      expect(a1.effectiveWorkoutDuration, a2.effectiveWorkoutDuration);
      expect(a1.effectiveCapabilityProfile, a2.effectiveCapabilityProfile);
      expect(a1.explanation, a2.explanation);
    });

    test('no mutation of persisted', () {
      final persisted = fullProfile(CapabilityLevel.level3);
      final originalLevel = persisted.capabilities[MovementPattern.push]!.level;
      WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.twentyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.lowEnergy,
      );
      expect(persisted.capabilities[MovementPattern.push]!.level, originalLevel);
    });

    test('explanation metadata present for temp modes', () {
      final persisted = fullProfile(CapabilityLevel.level3);
      final low = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.twentyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.lowEnergy,
      );
      final comeback = WorkoutSessionAdaptationPolicy.adapt(
        normalDuration: WorkoutDuration.twentyMinutes,
        persistedCapability: persisted,
        mode: WorkoutSessionMode.comeback,
      );
      expect(low.explanation, isNotNull);
      expect(comeback.explanation, isNotNull);
      expect(low.explanation, contains('Low Energy'));
      expect(comeback.explanation, contains('Comeback'));
    });

    test('all durations covered for low energy', () {
      expect(WorkoutDuration.values.length, 6);
      final persisted = fullProfile(CapabilityLevel.level3);
      for (final d in WorkoutDuration.values) {
        final a = WorkoutSessionAdaptationPolicy.adapt(
          normalDuration: d,
          persistedCapability: persisted,
          mode: WorkoutSessionMode.lowEnergy,
        );
        expect(a.effectiveWorkoutDuration, isNotNull);
      }
    });

    test('all durations covered for comeback', () {
      final persisted = fullProfile(CapabilityLevel.level3);
      for (final d in WorkoutDuration.values) {
        final a = WorkoutSessionAdaptationPolicy.adapt(
          normalDuration: d,
          persistedCapability: persisted,
          mode: WorkoutSessionMode.comeback,
        );
        expect(a.effectiveWorkoutDuration, isNotNull);
      }
    });
  });
}
