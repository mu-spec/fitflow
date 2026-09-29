import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomWorkoutTemplate _makeTemplate({
  String? id,
  String name = 'Test Workout',
  WorkoutDuration duration = WorkoutDuration.fifteenMinutes,
  DateTime? createdAt,
  DateTime? updatedAt,
  List<CustomWorkoutExerciseEntry>? warmup,
  List<CustomWorkoutExerciseEntry>? main,
  List<CustomWorkoutExerciseEntry>? cooldown,
}) {
  final now = DateTime.now().toUtc();
  return CustomWorkoutTemplate(
    id: id ?? 'custom_${now.millisecondsSinceEpoch}_0',
    name: name,
    targetDuration: duration,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    warmup: warmup ??
        [
          CustomWorkoutExerciseEntry(
            exerciseId: 'march_in_place',
            sets: 1,
            workDuration: const Duration(seconds: 30),
            restBetweenSets: const Duration(seconds: 15),
          )
        ],
    main: main ??
        [
          CustomWorkoutExerciseEntry(
            exerciseId: 'squat_bodyweight',
            sets: 2,
            repsPerSet: 10,
            restBetweenSets: const Duration(seconds: 30),
          )
        ],
    cooldown: cooldown ??
        [
          CustomWorkoutExerciseEntry(
            exerciseId: 'cobra_stretch',
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: const Duration(seconds: 0),
          )
        ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomWorkoutStorage', () {
    late CustomWorkoutStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = const CustomWorkoutStorage();
    });

    test('empty storage returns empty list', () async {
      final all = await storage.loadAll();
      expect(all, isEmpty);
    });

    test('round-trip single template', () async {
      final template = _makeTemplate(id: 'custom_1_0');
      final result = await storage.create(template);
      expect(result, isNotNull);
      final all = await storage.loadAll();
      expect(all.length, 1);
      expect(all.first.id, 'custom_1_0');
      expect(all.first.name, 'Test Workout');
    });

    test('order newest updated first', () async {
      final t1 = _makeTemplate(
          id: 'custom_1_0',
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 1));
      final t2 = _makeTemplate(
          id: 'custom_2_0',
          createdAt: DateTime.utc(2024, 1, 2),
          updatedAt: DateTime.utc(2024, 1, 2));
      final saved = await storage.saveAll([t1, t2]);
      expect(saved, isNotNull);
      final all = await storage.loadAll();
      expect(all.first.id, 'custom_2_0');
      expect(all.last.id, 'custom_1_0');
    });

    test('prescription preserved round-trip', () async {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 3,
        repsPerSet: 12,
        restBetweenSets: const Duration(seconds: 45),
      );
      final template = _makeTemplate(id: 'custom_1_0', main: [entry]);
      await storage.create(template);
      final all = await storage.loadAll();
      expect(all.first.main.first.sets, 3);
      expect(all.first.main.first.repsPerSet, 12);
      expect(all.first.main.first.restBetweenSets.inSeconds, 45);
    });

    test('ID preserved across save/load', () async {
      final template = _makeTemplate(id: 'custom_123_0');
      await storage.create(template);
      final all = await storage.loadAll();
      expect(all.first.id, 'custom_123_0');
    });

    test('createdAt preserved', () async {
      final created = DateTime.utc(2023, 5, 5, 10);
      final template = _makeTemplate(id: 'custom_1_0', createdAt: created, updatedAt: created);
      await storage.create(template);
      final all = await storage.loadAll();
      expect(all.first.createdAt, created);
    });

    test('updatedAt changes on update', () async {
      final created = DateTime.utc(2023, 5, 5, 10);
      final template = _makeTemplate(id: 'custom_1_0', createdAt: created, updatedAt: created);
      await storage.create(template);
      await Future.delayed(const Duration(milliseconds: 10));
      final updated = template.copyWith(name: 'Updated', updatedAt: DateTime.now().toUtc());
      final result = await storage.update(updated);
      expect(result, isNotNull);
      final all = await storage.loadAll();
      expect(all.first.name, 'Updated');
      expect(all.first.updatedAt.isAfter(created), true);
      expect(all.first.createdAt, created);
    });

    test('duplicate ID deduplicated', () async {
      final t1 = _makeTemplate(id: 'dup', name: 'First', updatedAt: DateTime.utc(2024, 1, 1));
      final t2 = _makeTemplate(id: 'dup', name: 'Second', updatedAt: DateTime.utc(2024, 1, 2));
      final saved = await storage.saveAll([t1, t2]);
      expect(saved, isNotNull);
      final all = await storage.loadAll();
      expect(all.length, 1);
      expect(all.first.name, 'Second');
    });

    test('malformed root safe returns empty', () async {
      SharedPreferences.setMockInitialValues({CustomWorkoutStorage.key: 'not a json array'});
      final all = await storage.loadAll();
      expect(all, isEmpty);
    });

    test('malformed entry safe skips', () async {
      SharedPreferences.setMockInitialValues({
        CustomWorkoutStorage.key: '[{"id":"good","name":"Good","targetDuration":"fifteenMinutes","createdAt":"2024-01-01T00:00:00.000Z","updatedAt":"2024-01-01T00:00:00.000Z","warmup":[],"main":[],"cooldown":[]}, {"bad": true}]'
      });
      final all = await storage.loadAll();
      expect(all.length, 1);
      expect(all.first.id, 'good');
    });

    test('missing ID field entry skipped but persist others', () async {
      SharedPreferences.setMockInitialValues({
        CustomWorkoutStorage.key:
            '[{"name":"NoId","targetDuration":"fifteenMinutes","createdAt":"2024-01-01T00:00:00.000Z","updatedAt":"2024-01-01T00:00:00.000Z","warmup":[],"main":[],"cooldown":[]}, {"id":"good","name":"Good","targetDuration":"fifteenMinutes","createdAt":"2024-01-01T00:00:00.000Z","updatedAt":"2024-01-01T00:00:00.000Z","warmup":[],"main":[],"cooldown":[]}]'
      });
      final all = await storage.loadAll();
      expect(all.length, 1);
      expect(all.first.id, 'good');
    });

    test('max 50 retains most recent 50', () async {
      final templates = List.generate(60, (i) {
        return _makeTemplate(
          id: 'custom_${i}_0',
          createdAt: DateTime.utc(2024, 1, 1).add(Duration(days: i)),
          updatedAt: DateTime.utc(2024, 1, 1).add(Duration(days: i)),
        );
      });
      final saved = await storage.saveAll(templates);
      expect(saved, isNotNull);
      expect(saved!.length, 50);
      final all = await storage.loadAll();
      expect(all.length, 50);
      expect(all.first.id, 'custom_59_0');
      expect(all.last.id, 'custom_10_0');
    });

    test('51st retains most recent 50', () async {
      final templates = List.generate(50, (i) {
        return _makeTemplate(
          id: 'custom_${i}_0',
          createdAt: DateTime.utc(2024, 1, 1).add(Duration(days: i)),
          updatedAt: DateTime.utc(2024, 1, 1).add(Duration(days: i)),
        );
      });
      await storage.saveAll(templates);
      final extra = _makeTemplate(
        id: 'custom_50_0',
        createdAt: DateTime.utc(2024, 2, 20),
        updatedAt: DateTime.utc(2024, 2, 20),
      );
      final result = await storage.create(extra);
      expect(result, isNotNull);
      final all = await storage.loadAll();
      expect(all.length, 50);
      expect(all.first.id, 'custom_50_0');
    });

    test('delete removes template', () async {
      final t1 = _makeTemplate(id: 'custom_1_0');
      final t2 = _makeTemplate(id: 'custom_2_0');
      await storage.saveAll([t1, t2]);
      final delResult = await storage.delete('custom_1_0');
      expect(delResult, isNotNull);
      final all = await storage.loadAll();
      expect(all.length, 1);
      expect(all.first.id, 'custom_2_0');
    });

    test('failed save does not corrupt (malformed JSON write skipped)', () async {
      final template = _makeTemplate(id: 'custom_1_0');
      await storage.create(template);
      final before = await storage.loadAll();
      SharedPreferences.setMockInitialValues({CustomWorkoutStorage.key: 'invalid json'});
      final after = await storage.loadAll();
      expect(after, isEmpty);
      await storage.saveAll(before);
      final restored = await storage.loadAll();
      expect(restored.length, 1);
    });

    // New failure contract tests
    test('setString == false -> save returns failure null', () async {
      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      SharedPreferences.setMockInitialValues({});
      final template = _makeTemplate(id: 'custom_1_0');
      final result = await failingStorage.saveAll([template]);
      expect(result, isNull);
    });

    test('create returns null on write failure', () async {
      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      SharedPreferences.setMockInitialValues({});
      final template = _makeTemplate(id: 'custom_1_0');
      final result = await failingStorage.create(template);
      expect(result, isNull);
    });

    test('update returns null on write failure', () async {
      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      SharedPreferences.setMockInitialValues({});
      final template = _makeTemplate(id: 'custom_1_0');
      final result = await failingStorage.update(template);
      expect(result, isNull);
    });

    test('delete returns null on write failure', () async {
      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      SharedPreferences.setMockInitialValues({});
      final result = await failingStorage.delete('custom_1_0');
      expect(result, isNull);
    });

    test('successful writes still update state normally', () async {
      final template = _makeTemplate(id: 'custom_1_0');
      final result = await storage.create(template);
      expect(result, isNotNull);
      expect(result!.length, 1);
    });
  });
}
