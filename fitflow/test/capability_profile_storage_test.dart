import 'dart:convert';

import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  CapabilityProfile createMixedProfile(DateTime updatedAt) {
    // Mixed complete profile as spec: Push2, Pull1, Squat4, Lunge3, Hinge3, Core1, Glute4, Cardio2, Mobility3, Balance2
    final map = <MovementPattern, MovementCapability>{
      MovementPattern.push: MovementCapability(
        movementPattern: MovementPattern.push,
        level: CapabilityLevel.level2,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
        anchorExerciseId: 'pushup_knee',
      ),
      MovementPattern.pull: MovementCapability(
        movementPattern: MovementPattern.pull,
        level: CapabilityLevel.level1,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
      MovementPattern.squat: MovementCapability(
        movementPattern: MovementPattern.squat,
        level: CapabilityLevel.level4,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
        anchorExerciseId: 'squat_bodyweight',
      ),
      MovementPattern.lunge: MovementCapability(
        movementPattern: MovementPattern.lunge,
        level: CapabilityLevel.level3,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
      MovementPattern.hinge: MovementCapability(
        movementPattern: MovementPattern.hinge,
        level: CapabilityLevel.level3,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
      MovementPattern.core: MovementCapability(
        movementPattern: MovementPattern.core,
        level: CapabilityLevel.level1,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
      MovementPattern.glute: MovementCapability(
        movementPattern: MovementPattern.glute,
        level: CapabilityLevel.level4,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
        anchorExerciseId: 'bridge_glute',
      ),
      MovementPattern.cardio: MovementCapability(
        movementPattern: MovementPattern.cardio,
        level: CapabilityLevel.level2,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
      MovementPattern.mobility: MovementCapability(
        movementPattern: MovementPattern.mobility,
        level: CapabilityLevel.level3,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
      MovementPattern.balance: MovementCapability(
        movementPattern: MovementPattern.balance,
        level: CapabilityLevel.level2,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
    };
    return CapabilityProfile.fromMap(map);
  }

  group('CapabilityProfileStorage Save / Load', () {
    test('save and load mixed complete profile preserves equality', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final updatedAt = DateTime.utc(2026, 9, 26, 10, 0, 0);
      final profile = createMixedProfile(updatedAt);
      expect(profile.isComplete, true);
      expect(profile.isValid, true);

      final saved = await storage.save(profile);
      expect(saved, true);

      final loaded = storage.load();
      expect(loaded, isNotNull);
      expect(loaded, profile);
      expect(loaded!.capabilities.length, 10);
    });

    test('levels preserved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final updatedAt = DateTime.utc(2026, 9, 26);
      final profile = createMixedProfile(updatedAt);
      await storage.save(profile);
      final loaded = storage.load()!;

      expect(loaded.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level2);
      expect(loaded.capabilityFor(MovementPattern.pull)!.level, CapabilityLevel.level1);
      expect(loaded.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level4);
      expect(loaded.capabilityFor(MovementPattern.lunge)!.level, CapabilityLevel.level3);
      expect(loaded.capabilityFor(MovementPattern.hinge)!.level, CapabilityLevel.level3);
      expect(loaded.capabilityFor(MovementPattern.core)!.level, CapabilityLevel.level1);
      expect(loaded.capabilityFor(MovementPattern.glute)!.level, CapabilityLevel.level4);
      expect(loaded.capabilityFor(MovementPattern.cardio)!.level, CapabilityLevel.level2);
      expect(loaded.capabilityFor(MovementPattern.mobility)!.level, CapabilityLevel.level3);
      expect(loaded.capabilityFor(MovementPattern.balance)!.level, CapabilityLevel.level2);
    });

    test('source preserved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final profile = createMixedProfile(DateTime.utc(2026, 1, 1));
      await storage.save(profile);
      final loaded = storage.load()!;
      for (final cap in loaded.all) {
        expect(cap.source, CapabilitySource.initialAssessment);
      }
    });

    test('timestamps preserved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final updatedAt = DateTime.utc(2026, 5, 15, 14, 30, 45);
      final profile = createMixedProfile(updatedAt);
      await storage.save(profile);
      final loaded = storage.load()!;
      for (final cap in loaded.all) {
        expect(cap.updatedAt, updatedAt);
      }
    });

    test('anchors preserved where present', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final profile = createMixedProfile(DateTime.utc(2026, 1, 1));
      await storage.save(profile);
      final loaded = storage.load()!;

      expect(loaded.capabilityFor(MovementPattern.push)!.anchorExerciseId, 'pushup_knee');
      expect(loaded.capabilityFor(MovementPattern.squat)!.anchorExerciseId, 'squat_bodyweight');
      expect(loaded.capabilityFor(MovementPattern.glute)!.anchorExerciseId, 'bridge_glute');
      expect(loaded.capabilityFor(MovementPattern.pull)!.anchorExerciseId, isNull);
      expect(loaded.capabilityFor(MovementPattern.core)!.anchorExerciseId, isNull);
    });
  });

  group('Missing Data', () {
    test('no SharedPreferences key returns null', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      expect(storage.load(), isNull);
    });
  });

  group('Malformed JSON', () {
    test('invalid JSON string returns null without throwing', () async {
      SharedPreferences.setMockInitialValues({
        CapabilityProfileStorage.profileKey: 'not valid json {{{',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      expect(() => storage.load(), returnsNormally);
      expect(storage.load(), isNull);
    });

    test('JSON not object returns null', () async {
      SharedPreferences.setMockInitialValues({
        CapabilityProfileStorage.profileKey: jsonEncode(['array', 'not', 'object']),
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      expect(storage.load(), isNull);
    });

    test('JSON with wrong structure returns null', () async {
      SharedPreferences.setMockInitialValues({
        CapabilityProfileStorage.profileKey: jsonEncode({'capabilities': 'not a list'}),
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      expect(storage.load(), isNull);
    });
  });

  group('Incomplete Profile', () {
    test('persist JSON with only 9 valid capabilities returns null', () async {
      final now = DateTime.utc(2026, 1, 1);
      // Create profile with 9 entries
      final map = <MovementPattern, MovementCapability>{};
      final patterns = CapabilityProfile.trainablePatterns.take(9);
      for (final p in patterns) {
        map[p] = MovementCapability(
          movementPattern: p,
          level: CapabilityLevel.level2,
          source: CapabilitySource.initialAssessment,
          updatedAt: now,
        );
      }
      final incompleteProfile = CapabilityProfile.fromMap(map);
      expect(incompleteProfile.isComplete, false);

      // Directly store its JSON (bypassing save validation which would throw)
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      // Manually encode incomplete profile via toJson
      final jsonString = jsonEncode(incompleteProfile.toJson());
      await freshPrefs.setString(CapabilityProfileStorage.profileKey, jsonString);

      final storage = CapabilityProfileStorage(freshPrefs);
      final loaded = storage.load();
      expect(loaded, isNull, reason: 'incomplete persisted data should not be valid');
    });

    test('save() rejects incomplete profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final now = DateTime.utc(2026, 1, 1);
      final map = <MovementPattern, MovementCapability>{
        MovementPattern.push: MovementCapability(
          movementPattern: MovementPattern.push,
          level: CapabilityLevel.level1,
          source: CapabilitySource.initialAssessment,
          updatedAt: now,
        ),
      };
      final incomplete = CapabilityProfile.fromMap(map);
      expect(incomplete.isComplete, false);

      expect(() => storage.save(incomplete), throwsArgumentError);
      expect(storage.load(), isNull);
    });
  });

  group('Invalid Entries', () {
    test('warmup/cooldown capability data does not produce valid profile', () async {
      final now = DateTime.utc(2026, 1, 1);
      final json = {
        'capabilities': [
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
      SharedPreferences.setMockInitialValues({
        CapabilityProfileStorage.profileKey: jsonEncode(json),
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      expect(storage.load(), isNull);
    });

    test('unknown enum names handled safely', () async {
      final now = DateTime.utc(2026, 1, 1);
      final json = {
        'capabilities': [
          {
            'movementPattern': 'push',
            'level': 'unknownLevel',
            'source': 'initialAssessment',
            'updatedAt': now.toIso8601String(),
          },
          {
            'movementPattern': 'unknownPattern',
            'level': 'level1',
            'source': 'initialAssessment',
            'updatedAt': now.toIso8601String(),
          },
        ]
      };
      SharedPreferences.setMockInitialValues({
        CapabilityProfileStorage.profileKey: jsonEncode(json),
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      expect(() => storage.load(), returnsNormally);
      expect(storage.load(), isNull);
    });

    test('save() rejects invalid profile containing warmup', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final now = DateTime.utc(2026, 1, 1);
      // Create a map that includes warmup (invalid)
      final map = <MovementPattern, MovementCapability>{};
      for (final p in CapabilityProfile.trainablePatterns) {
        map[p] = MovementCapability(
          movementPattern: p,
          level: CapabilityLevel.level1,
          source: CapabilitySource.initialAssessment,
          updatedAt: now,
        );
      }
      // Add warmup via fromMap that includes warmup? fromMap will include it but validate fails
      // We need to test that a profile that is invalid due to warmup is rejected
      // Since CapabilityProfile.fromMap with warmup will have 11 entries and isComplete false? Actually trainablePatterns is 10, so adding warmup makes length 11, isComplete false because it checks length ==10 and contains exactly trainable
      // So save should throw for incomplete/invalid
      final invalidMap = Map<MovementPattern, MovementCapability>.from(map);
      invalidMap[MovementPattern.warmup] = MovementCapability(
        movementPattern: MovementPattern.warmup,
        level: CapabilityLevel.level1,
        source: CapabilitySource.initialAssessment,
        updatedAt: now,
      );
      final invalidProfile = CapabilityProfile.fromMap(invalidMap);
      expect(invalidProfile.isValid, false);
      expect(() => storage.save(invalidProfile), throwsArgumentError);
    });
  });

  group('Clear', () {
    test('save valid profile, clear, load returns null', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);

      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      await storage.save(profile);
      expect(storage.load(), isNotNull);

      await storage.clear();
      expect(storage.load(), isNull);
    });
  });
}
