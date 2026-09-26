import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  CapabilityProfile createMixedProfile(DateTime updatedAt) {
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

  group('CapabilityProfile Provider - Initial load', () {
    test('no persisted profile → AsyncData(null)', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Need to ensure SharedPreferences instance is empty
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final profile = await container.read(capabilityProfileProvider.future);
      expect(profile, isNull);

      final asyncValue = container.read(capabilityProfileProvider);
      expect(asyncValue, isA<AsyncData<CapabilityProfile?>>());
      expect(asyncValue.value, isNull);
    });

    test('valid persisted profile → AsyncData(profile)', () async {
      final updatedAt = DateTime.utc(2026, 9, 26);
      final expectedProfile = createMixedProfile(updatedAt);

      // Pre-populate SharedPreferences with valid profile JSON via storage
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      await storage.save(expectedProfile);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final loaded = await container.read(capabilityProfileProvider.future);
      expect(loaded, isNotNull);
      expect(loaded, expectedProfile);
      expect(loaded!.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level2);
    });
  });

  group('CapabilityProfile Provider - Save', () {
    test('saving valid profile updates SharedPreferences and provider state',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Initially null
      var loaded = await container.read(capabilityProfileProvider.future);
      expect(loaded, isNull);

      final updatedAt = DateTime.utc(2026, 9, 26);
      final profile = createMixedProfile(updatedAt);

      final controller = container.read(capabilityProfileProvider.notifier);
      final saved = await controller.saveProfile(profile);
      expect(saved, true);

      // Provider state should be saved profile
      final state = container.read(capabilityProfileProvider);
      expect(state.value, profile);

      // SharedPreferences should contain it
      final storage = CapabilityProfileStorage(prefs);
      final fromStorage = storage.load();
      expect(fromStorage, profile);
    });
  });

  group('CapabilityProfile Provider - Clear', () {
    test('storage removed and provider state becomes null', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final storage = CapabilityProfileStorage(prefs);
      await storage.save(profile);
      expect(storage.load(), isNotNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Load initial
      var loaded = await container.read(capabilityProfileProvider.future);
      expect(loaded, isNotNull);

      final controller = container.read(capabilityProfileProvider.notifier);
      await controller.clearProfile();

      // Storage should be cleared
      expect(storage.load(), isNull);

      // Provider state should be null
      final state = container.read(capabilityProfileProvider);
      expect(state.value, isNull);
    });
  });

  group('CapabilityProfile Provider - Invalid profile', () {
    test('invalid/incomplete profile is not persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final controller = container.read(capabilityProfileProvider.notifier);

      // Create incomplete profile (only 1 entry)
      final incomplete = CapabilityProfile.fromMap({
        MovementPattern.push: MovementCapability(
          movementPattern: MovementPattern.push,
          level: CapabilityLevel.level1,
          source: CapabilitySource.initialAssessment,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      });
      expect(incomplete.isComplete, false);

      final saved = await controller.saveProfile(incomplete);
      expect(saved, false);

      // Need to await future to ensure initial load completed
      await container.read(capabilityProfileProvider.future);
      final afterState = container.read(capabilityProfileProvider);
      expect(afterState.value, isNull);

      // Storage should still be empty
      final storage = CapabilityProfileStorage(prefs);
      expect(storage.load(), isNull);
    });
  });
}
